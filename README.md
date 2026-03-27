# Omacole (Cole's Opinionated Version of DHH's Opinionated Ubuntu Setup)

I'm a big fan of DHH and Ubuntu. I pretty much always run Ubuntu on my servers so it makes sense to develop in the same environment, plus I'm tired of dealing with Microslop breaking everything. Any year now it'll be the year of the Linux desktop...

## Changes from the base version of Omakub
- Switch from Zellij to Tmux: This is the biggest change. I know Tmux and it's not broken so I'm not fixing it
- "Bloat": Sorry DHH I'm not using Basecamp or HEY but I respect your ambition
- Corporate spyware: Whatsapp is a no-go
- Switch from Windsurf/Cursor to Claude Code: The Cursor team was dishonest about their use of a Chinese model in Composer. Not disclosing this and claiming the work for your own is the same thing as lying as far as I'm concerned-- I don't care what the license was. Windsurf is owned by OpenAI and don't even get me started on Snakeoil Salesman Scam Altman the Shlop Shiller
- Switch from 1password to KeyPassXC: IYKYK
- No Doom Emacs: Neovim is scary enough
- Misc: Remove Brave, Dropbox, Minecraft :( (this is for work), rubymine, Zed
- Additions: Add uv and bun. I was devastated when OpenAI bought Astral (the company behind uv). A wise man (stranger on Twitter) once said this is like seeing your favorite restaurant get bought by a shitty hotel chain. If they mess with uv or make that closed source too I'm gonna snap

Much of the above are optional installs, I just want a minimal setup so I made these tweaks. If you actually care about agency you should be in an environment where you have full control, and ideally one that "just works". Omakub is a great place to start, even if you have different opinions about the setup. 

## Install

Install with: wget -qO- https://raw.githubusercontent.com/colesussmeier/omakub-omacole/master/boot.sh | bash

## Update 

Since this is a fork of Omakub, I can't just pull the changes from the upstream project. Instead, I added an option in the update menu called "Upstream" that lists new commits to upstream and allows me to review them one by one. I can either choose to cherry pick them and then push them to my master branch, or ignore them. A file keeps track of my decisions so I only have to review commits once. 


The rest of this readme is from the Omakub source code, this repo is just a fork of the main project with the changes listed above.


# Omakub

Turn a fresh Ubuntu installation into a fully-configured, beautiful, and modern web development system by running a single command. That's the one-line pitch for Omakub. No need to write bespoke configs for every essential tool just to get started or to be up on all the latest command-line tools. Omakub is an opinionated take on what Linux can be at its best.

Watch the introduction video and read more at [omakub.org](https://omakub.org).

## Contributing to the documentation

Please help us improve Omakub's documentation on the [basecamp/omakub-site repository](https://github.com/basecamp/omakub-site).

## License

Omakub is released under the [MIT License](https://opensource.org/licenses/MIT).

## Extras

While omakub is purposed to be an opinionated take, the open source community offers alternative customization, add-ons, extras, that you can use to adjust, replace or enrich your experience.

[⇒ Browse the omakub extensions.](EXTENSIONS.md)
