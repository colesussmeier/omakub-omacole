#!/bin/bash

# Check upstream omakub for changes since the fork date
UPSTREAM_URL="https://github.com/basecamp/omakub.git"
FORK_DATE="2026-03-26"
REVIEWED_FILE="$OMAKUB_PATH/.upstream-reviewed"

# Attempt to cherry-pick a commit, then offer to run affected installers
do_cherry_pick() {
  local HASH="$1"
  local DESC="$2"

  if git cherry-pick "$HASH" --no-commit 2>/dev/null; then
    echo "✓ Changes from $HASH staged (not yet committed)"
    if gum confirm "Commit these changes?"; then
      git commit -m "upstream: $DESC"
      echo "✓ Committed"
    fi

    # Detect changed files and offer to run affected installers/configs
    CHANGED_FILES=$(git diff-tree --no-commit-id --name-only -r "$HASH" 2>/dev/null)
    offer_reapply "$CHANGED_FILES"
  else
    echo "✗ Conflict applying $HASH"
    echo "Conflicted files:"
    git diff --name-only --diff-filter=U
    echo ""
    if gum confirm "Abort this cherry-pick?"; then
      git cherry-pick --abort 2>/dev/null
      git checkout -- . 2>/dev/null
      echo "Cherry-pick aborted."
    else
      echo "Resolve conflicts manually, then 'git add' and 'git commit'."
      BREAK_LOOP=1
    fi
  fi
}

# Look at which files a commit touched and offer to re-run installers or
# re-deploy configs so the changes actually take effect on the system
offer_reapply() {
  local CHANGED_FILES="$1"
  local ACTIONS=()

  while IFS= read -r file; do
    case "$file" in
      install/terminal/app-*.sh)
        ACTIONS+=("Run installer: $file")
        ;;
      install/desktop/app-*.sh)
        ACTIONS+=("Run installer: $file")
        ;;
      install/desktop/optional/app-*.sh)
        ACTIONS+=("Run installer: $file")
        ;;
      install/terminal/optional/app-*.sh)
        ACTIONS+=("Run installer: $file")
        ;;
      install/desktop/set-*.sh)
        ACTIONS+=("Run settings: $file")
        ;;
      configs/alacritty*.toml | configs/alacritty/*.toml)
        ACTIONS+=("Re-deploy alacritty config")
        ;;
      configs/neovim/*)
        ACTIONS+=("Re-deploy neovim config")
        ;;
      themes/*)
        ACTIONS+=("Re-apply current theme")
        ;;
      defaults/bash/*)
        ACTIONS+=("Re-deploy shell config")
        ;;
    esac
  done <<< "$CHANGED_FILES"

  # Deduplicate
  if [ ${#ACTIONS[@]} -gt 0 ]; then
    UNIQUE_ACTIONS=($(printf '%s\n' "${ACTIONS[@]}" | sort -u))

    echo ""
    echo "This commit changed files that need re-deployment to take effect:"
    printf '  • %s\n' "${UNIQUE_ACTIONS[@]}"
    echo ""

    for action in "${UNIQUE_ACTIONS[@]}"; do
      if gum confirm "$action?"; then
        case "$action" in
          "Run installer: "* | "Run settings: "*)
            SCRIPT="${action#Run installer: }"
            SCRIPT="${SCRIPT#Run settings: }"
            echo "Running $SCRIPT..."
            source "$OMAKUB_PATH/$SCRIPT"
            echo "✓ Done"
            ;;
          "Re-deploy alacritty config")
            cp "$OMAKUB_PATH/configs/alacritty.toml" ~/.config/alacritty/alacritty.toml
            for f in "$OMAKUB_PATH"/configs/alacritty/*.toml; do
              cp "$f" ~/.config/alacritty/
            done
            echo "✓ Alacritty config updated"
            ;;
          "Re-deploy neovim config")
            for f in "$OMAKUB_PATH"/configs/neovim/*; do
              cp "$f" ~/.config/nvim/plugin/after/
            done
            echo "✓ Neovim config updated"
            ;;
          "Re-apply current theme")
            source "$OMAKUB_PATH/bin/omakub-sub/theme.sh"
            ;;
          "Re-deploy shell config")
            cp "$OMAKUB_PATH/defaults/bash/rc" ~/.bashrc_omakub 2>/dev/null
            echo "✓ Shell config updated (restart your shell to apply)"
            ;;
        esac
      fi
    done
  fi
}

cd $OMAKUB_PATH

# Ensure upstream remote exists
if ! git remote get-url upstream &>/dev/null; then
  echo "Adding upstream remote..."
  git remote add upstream "$UPSTREAM_URL"
fi

# Ensure reviewed file exists
touch "$REVIEWED_FILE"

echo "Fetching upstream changes..."
git fetch upstream --quiet

# Get upstream commits since fork date
COMMITS=$(git log upstream/stable --since="$FORK_DATE" --oneline --no-merges 2>/dev/null)

if [ -z "$COMMITS" ]; then
  COMMITS=$(git log upstream/master --since="$FORK_DATE" --oneline --no-merges 2>/dev/null)
  UPSTREAM_BRANCH="upstream/master"
else
  UPSTREAM_BRANCH="upstream/stable"
fi

if [ -z "$COMMITS" ]; then
  echo "No new upstream changes since $FORK_DATE."
  cd - >/dev/null
  sleep 2
  clear
  source $OMAKUB_PATH/bin/omakub
  return 2>/dev/null || exit 0
fi

# Filter out already-reviewed commits
NEW_COMMITS=""
while IFS= read -r line; do
  HASH=$(echo "$line" | awk '{print $1}')
  if ! grep -q "^$HASH$" "$REVIEWED_FILE" 2>/dev/null; then
    NEW_COMMITS+="$line"$'\n'
  fi
done <<< "$COMMITS"

# Remove trailing newline
NEW_COMMITS=$(echo "$NEW_COMMITS" | sed '/^$/d')

if [ -z "$NEW_COMMITS" ]; then
  TOTAL_REVIEWED=$(wc -l < "$REVIEWED_FILE")
  echo "No new upstream commits to review ($TOTAL_REVIEWED already reviewed)."
  echo ""
  if gum confirm "Show all upstream commits (including reviewed)?"; then
    NEW_COMMITS="$COMMITS"
  else
    cd - >/dev/null
    sleep 2
    clear
    source $OMAKUB_PATH/bin/omakub
    return 2>/dev/null || exit 0
  fi
fi

echo ""
echo "Upstream changes to review:"
echo "─────────────────────────────────────────"
echo "$NEW_COMMITS"
echo "─────────────────────────────────────────"
echo ""

# Let user pick commits to review
COMMIT_LINES=()
while IFS= read -r line; do
  COMMIT_LINES+=("$line")
done <<< "$NEW_COMMITS"

SELECTED=$(printf '%s\n' "${COMMIT_LINES[@]}" | gum choose --no-limit --height 20 --header "Select commits to review (space to select, enter to confirm)")

if [ -z "$SELECTED" ]; then
  echo "No commits selected."
  cd - >/dev/null
  sleep 2
  clear
  source $OMAKUB_PATH/bin/omakub
  return 2>/dev/null || exit 0
fi

# Review each selected commit
BREAK_LOOP=0
while IFS= read -r line; do
  [ "$BREAK_LOOP" -eq 1 ] && break

  HASH=$(echo "$line" | awk '{print $1}')
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Commit: $line"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Show files changed
  echo "Files changed:"
  git diff-tree --no-commit-id --name-status -r "$HASH" 2>/dev/null
  echo ""

  # Show the full diff
  git show "$HASH" --stat --format="" 2>/dev/null
  echo ""

  ACTION=$(gum choose "Cherry-pick this commit" "View full diff" "Skip" --header "What would you like to do?")

  case "$ACTION" in
    "View full diff")
      git show "$HASH" --format="" 2>/dev/null | head -200
      echo ""
      ACTION2=$(gum choose "Cherry-pick this commit" "Skip" --header "Cherry-pick this commit?")
      if [ "$ACTION2" = "Cherry-pick this commit" ]; then
        do_cherry_pick "$HASH" "$line"
      fi
      ;;
    "Cherry-pick this commit")
      do_cherry_pick "$HASH" "$line"
      ;;
    "Skip")
      echo "Skipped."
      ;;
  esac

  # Mark as reviewed regardless of action taken
  if ! grep -q "^$HASH$" "$REVIEWED_FILE" 2>/dev/null; then
    echo "$HASH" >> "$REVIEWED_FILE"
  fi

done <<< "$SELECTED"

cd - >/dev/null
echo ""
echo "Done reviewing upstream changes. Be sure to commit to origin master if you want to keep a record of these changes on Github."
sleep 2

clear
source $OMAKUB_PATH/bin/omakub
