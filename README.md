# realNTFS

A native macOS application to mount NTFS drives as Read/Write with excellent performance using `ntfs-3g`. 

> [!WARNING]
> This app is for advanced users, it requires disabling SIP and reducing kernel security to allow unsigned kexts. Not for the average user but much nicer to use than any other free app out there for people who have the expertise to set it up.

## Performance
ntfs-3g (the actual thing behind this wrapper) has INCREDIBLE performance for a userspace FUSE. Here are some comparisons with different filesystems and tools. All tests are transferring 27.04GB of assorted video files to an external 7200rpm NAS hard drive in an enclosure with USB 2.0 (my cheap dock doesn't support 3.0).

### APFS (native filesystem)
- Time taken: 2 minutes and 30 seconds
- Speed: ~180 MB/s

### NTFS (realNTFS)
- Time taken: 8 minutes and 13 seconds
- Speed: 55 MB/s

### NTFS (Mounty using native macOS driver)
**Test FAILED**: Transfer stalled to 0 B/s after 1.1GB transferred and did not recover after 15 minutes, the 1.1GB that was transferred was corrupted and unplayable.
- Time taken: 19 minutes and 19 seconds
- Speed: 0.95 MB/s

### exFAT (native macOS driver)
**TEST NOT COMPLETED**: I let the transfer run for 15 minutes and gave up because I am not waiting almost 4 hours, the estimated time taken was at the end of the 15 minutes
- ESTIMATED Time taken: 3 hours and 45 minutes
- Speed: ~2.0 MB/s (but likely would've slowed down further if I let it run longer, exFAT is terrible for large transfers and hard drives due to fragmentation)

## Prerequisites

- SIP **OFF**
- Kernel Security **Reduced** with both checkboxes for kernel extensions and stuff checked
- macOS 11-26 (only tested on 26, please open github issue if it doesn't work on an older version)

I will laugh at you and close your issue as invalid if you do not have ALL of these.

You need to have `ntfs-3g` and `macfuse` installed.

```bash
brew tap gromgit/homebrew-fuse
brew install ntfs-3g-mac
brew install --cask macfuse
```

Once again I will laugh at you and close your issue as invalid if you do not have these installed unless your issue is about being unable to install either dependencies.

## Building the App

To build the application, run the provided build script:

```bash
./build_app.sh
```

This will create `realNTFS.app` in the current directory. You can drag this to your Applications folder. Alternatively a precompiled Apple Silicon version of the app is available in GitHub releases. I do not have an Intel Mac, do not ask me to compile for Intel or I will permanently ban you from opening issues. 

Once again, this is **not for average users**, if you don't even know how to build this app yourself or what Git is, you should not be using this.

## Usage

1. Open `realNTFS.app`.
2. The app will list all detected NTFS drives.
3. Click "Mount R/W" next to the drive you want to mount.
4. You will be prompted for your system password (required for `sudo` operations).
5. The drive will be unmounted and remounted with write permissions at `/Volumes/<DriveName>`.

## Helper Agent installation
The helper agent allows you to automatically remount drives as rw on login/when connected. To install it, open settings and click the install helper agent button. It will ask you for your admin password once and you'll never have to enter it again for remounting.

## Troubleshooting

- Check the logs
- Make sure you read the file literally called README.md (this one)
- Export logs and open a GitHub issue (anyone opening a GitHub issue is required to be an admin user on their machine, know how to use the terminal and not be a dumbass, otherwise I will close your issue). I am not obligated to solve your issue.

## Why are you so rude?
Because I KNOW there's gonna be annoying average users spamming GitHub issues and I am not going to deal with it, this is a project I made for myself and I am only publishing it to help experienced users who want something that actually works for free.