# Snap Packaging for Git Cola

![Icon of Git Cola](gui/icon.png "Icon of Git Cola")

**This is the snap for Git Cola**, *"The highly caffeinated Git GUI"*. It works on Ubuntu, Fedora, Debian, and other major Linux distributions.

[![Build Status Badge of the `git-cola-brlin` Snap](https://build.snapcraft.io/badge/Lin-Buo-Ren/git-cola-snap.svg "Build Status of the `git-cola-brlin` snap")](https://build.snapcraft.io/user/Lin-Buo-Ren/git-cola-brlin)

![Screenshot of the Snapped Application](screenshots/view-main-amending.png "Screenshot of the Snapped Application")

Published for <img src="http://anything.codes/slack-emoji-for-techies/emoji/tux.png" align="top" width="24" /> with 💝 by Snapcrafters

## Installation

```
# Install Snap
sudo snap install --channel=beta git-cola-brlin

# Connect the Snap to Optional Interfaces
## removable-media: For opening Git repositories under `/media/*` and `/run/media/*`
sudo snap connect git-cola-brlin:removable-media

## ssh-keys: For remote operation via SSH protocol
sudo snap connect git-cola-brlin:ssh-keys

## gpg-keys: For signing commits and tags
sudo snap connect git-cola-brlin:gpg-keys

```

([Don't have snapd installed?](https://snapcraft.io/docs/core/install))

## What is Working

- Launch
- I18N
- Launch help webpages
- Initialize new repository
- Clone existing repository
- Modify Git config
- Modify Git remotes
- File system change monitoring
- Launch host editor for editing files
- Stage changes
- Commit changes
- Remote fetch
- Remote push
- Create branch
- Rebase
- DAG view
- Stash
- File browser
- Visualize via gitk

## What is NOT Working...yet

- Git Large File Storage(missing part)
- Git Annex(missing part)
- External diff viewer(missing part)

## What is NOT Tested...yet

- send2trash
- grep
- Anything not listed here

## Support

- [Issue Tracker](https://github.com/Lin-Buo-Ren/git-cola-snap/issues)