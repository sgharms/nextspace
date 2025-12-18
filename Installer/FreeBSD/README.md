# FreeBSD Developer Preview 1

## Goals

1. Don't blow up before I see anything
2. Manage my windows
3. Let me have a `Terminal.app` that had nice key bindings
4. Let me write a GNUStep app using `ProjectCenter.app` and `Gorm.app`
5. Look NeXT-y
6. Let me get fonts big enough to read without my glasses
7. Get something working so that other BSD pros can help get around thorny
   issues

## Sadly Broken / Insufficiently Tested

1. Drag n' Drop
2. Sound controls
3. Display aware resizing and cleverness based on hot plug/unplug of
   peripherals
4. ~~Uninstaller script (Do you know how hard it was to get this working ;))~~ -- _Everything's in `/usr/local/NextSpace`
5. ~~Power-inefficient: Starting this up cranks my fan. Might be this machine or 14.3 FreeBSD. Needs investigation~~ -- see `c6a4247`

## Low-Priority Goals

1. Drive insertion detection working
2. Peripheral configuration
3. Display manager login w-t-f ever, no. Use `startx`. You're on FreeBSD

## Test Platform

Jail and Host: `14.3-RELEASE FreeBSD 14.3-RELEASE releng/14.3-n271432-8c9ce319fef7 GENERIC amd64`

## Introduction

I have wanted NeXT look and feel and GNUstep toolchain integration for about a
year now. I also wanted it on a BSD -- like NeXT machines were.

After chasing permutations of Window Maker, I found Sergeii's [NEXTSPACE].
But, it only runs on Linux. Sergeii, to his credit, also said that there were
certain considerations of supporting to FreeBSD that made it impossible for to
him support.

Having walked a mile in those shoes, you weren't kidding, brother. For the last
several months I have been leveling-up in a variety of skills to be able to
port the core functionality across as listed in the Goals section.

## Maturity

***This is a developer release.*** If you're trying this, please back up your
data. I can't guarantee I haven't created catastrophic failure modes.

That above said, the installation is not one-click at this point. But running
10 shell scripts shouldn't be considered "hard."

If something goes wrong, I can try to help out, but I can't commit to any sort
of support service level agreement.

I hope this Just Works for you :).

## Firm Footing

In the event that something goes wrong, you will probably need to be familiar
with some of these skills. I wound up having to learn to use most of them
afresh, but found myself aided by Claude Code and ChatGPT.

* Shell scripting
* [GNU `make`][GNUmake]
* Objective-C Programming
* C Programming
* cmake

I'll also recommend that you use certain bits of FreeBSD magic in this
installation approach. Having the FreeBSD handbook, uh, handy is a good idea.
Of particular note, my build approach involves using FreeBSD jails to make sure
this experimental code doesn't pour seagull poop all over your main system.

## AI

I'll also readily acknowledge that I used Claude 4.5 (Sonnet) and ChatGPT 5.0
to tackle this problem. I'm not an AI purist: I recognize that it can set us
back, but I also recognize that it's allowing me to tackle big projects (e.g.
this) that have a complex stack and whose documentation is low empathy for
casual contribution.

Is AI a bubble? Probably. Is it a tool that in the right hands may help extend
the zone of proximal development _or_ allow one to contribute a one-off fix? In
my case here, yes. There's really no nuanced conversation on this anymore, but
this project is a data point. Yes, it has allowed me to reach farther; on the
other hand, I hope I've never let a diff hunk be committed where I didn't learn
what was missing and document it either by virtue of the diff or in the commit.

## Installation

One can install the system (provided one has a jail) in a safe manner in about
5 minutes depending on machine speed. I'm on a fairly old 4 core Lenovo T14
that I bought from a reseller in Chelsea.

> **TL;DR**: Look in `Installer/FreeBSD` and run the shell scripts in order.
> Several of them have manual configuration steps at the end. Do those when
> prompted.
> 
> At the end, run `/usr/local/NextSpace/Apps/Workspace.app/Workspace`. It
> should work. If things break look at the executing terminal or double-check
> `~/Library/Preferences/.NextSpace/WMState.plist`

You can do this in a jail (recommended) or on your main system (#yolo).

## Step 1: Build a Test Jail

We'll be using a _thick jail_. I recommend you read through the creation and
installation of a _thick jail_ before proceeding. We follow a very vanilla
path. I call my container `/usr/local/jails/containers/nextspace-dr1`:

<preview>
<summary><code>/etc/jail.conf</code> declaration for <code>nextspace-debug</code> jail
<pre>
nextspace-debug { 
  # STARTUP/LOGGING
  exec.start = "/bin/sh /etc/rc"; 
  exec.stop = "/bin/sh /etc/rc.shutdown"; 
  exec.consolelog = "/var/log/jail_console_nextspace-debug.log"; 

  # PERMISSIONS
  allow.raw_sockets; 
  exec.clean; 
  mount.devfs; 
  allow.sysvipc = 1;
  devfs_ruleset = 20;
  mount.fstab = "/etc/fstab.jail";

  # HOSTNAME/PATH
  host.hostname = "nextspace-debug"; 
  path = "/usr/local/jails/containers/nextspace-debug/"; 

  # NETWORK
  ip4 = inherit;
}
</pre>

This follows the ZFS directory creation plan listed in the handbook:

<pre>
# zfs create -o mountpoint=/usr/local/jails zroot/jails
# zfs create zroot/jails/media
# zfs create zroot/jails/templates
# zfs create zroot/jails/containers
</pre>

Notable configuration lines are:

* `allow.sysvipc = 1;` : We need this later for interprocess communication as part of NEXTSPACE
* `devfs_ruleset = 20;`: We need this later for device management as part of NEXTSPACE
* `mount.fstab = "/etc/fstab.jail";`: We need this to help `pkg(8)` and `ports(7)` work nice
* `host.hostname = "nextspace-debug";`: Helps to know what machine you're on

Here's `/etc/fstab.jail`:

<code>
/etc/resolv.conf /usr/local/jails/containers/nextspace-debug/etc/resolv.conf nullfs ro 0 0 
/dev /usr/local/jails/containers/nextspace-debug/dev devfs ro 0 0
/home/myuser/git_checkouts/nextspace/ /usr/local/jails/containers/nextspace-debug/src nullfs rw 0 0 
</code>

Notably this puts my homedir's checkout of the NEXTSPACE as a mount to _the
jail's_ `/src` mount point. This makes it easy to copy things and to make sure
that changes to the NEXTSPACE code survive rollbacks.

Get your jail working and create a "prime" snapshot.

</preview>

## Step 2: Developer Ergonomics

We're going to be hopping in and out of the jail. This is still a pretty
unstable application, so you're going to need to snapshot the jail, hop into
the jail, change directory, etc. Make it ergonomic *now*.

`alias je='doas jexec nextspace-dr1 sh -l'`

Or: "Quickly get in the jail as root with a login shell."

Once inside the jail, we're going to be spending some time in the installer
directory in `.../nextspace/Installer/FreeBSD/` and
`.../nextspace/Applications`.

Make it easy to get there, so edit the `.shrc` inside of `root`'s login shell.

Add to `/usr/local/jails/containers/nextspace-dr1/root/.shrc`:

<code>
alias jj='cd /src/Installer/FreeBSD/'
alias jk='cd /src/Applications/Workspace/'
</code>

## Step 3: Verify `root` Behavior

Make sure host OS `je` launches you into the jail (as `root`). Make sure `jj`
and `jk` work.

For this guide, I'm going to be working and running NEXTSPACE as `root`.

## Step 5: Set Up X Shared State

Add the following to your host `.shrc`

alias xtunnel='doas mount_nullfs /tmp/.X11-unix/ /usr/local/jails/containers/nextspace-dr1/tmp/.X11-unix'

By doing this, your jail can share X connections back to the host OS. You have
to run it manually after reboots / power outages / etc.

Invoke `xtunnel`. Allow the jail to tunnel back to the host with `xhost`. I use
`xhost +` when I get frustrated. Theoretically, `xhost +nextspace-dr1` should
work.

## Step 6: Install Any Final Tools

Add tools you need in order to be productive: install `tmux` or `vim`. Copy
over your `.tmux.conf` and/or your `.vimrc`. Once your jail is ready to go
snapshot it.

Here's my base:

# pkg prime-list

diff-so-fancy
gdb
git
gmake
pkg
tig
tmux
tree
vim
xeyes

## Step 7: Make `xeyes` at `DISPLAY:0` and `:1`

```console
$ je
root@nextspace-dr1:/ # echo $DISPLAY
:0
$ xeyes
```

Do you see `xeyes` watching you? If so, great! You're on your way.

Now, on the host OS log in through another virtual console. Launch `X :1`.

With your shared `/tmp/.X11-unix` in place, you should be able to redirect
output to this server with `export DISPLAY=:1`. Now try `xeyes` again. Change
to the virtual terminal for this bare X session and you'll see the eyes.
Awesome. You have a working X (`:0`) and a test X (`:1`). Neat.

## Step 8: The "Prime" Snapshot on the Host

`# zfs snapshot zroot/jails/containers/nextspace-dr1@begin-NS-installation`

From here on out, I used zfs snapshots to experiment, roll-forward, roll-back,
etc. As Sierra games and FROM Software have taught me, save your work at
checkpoints so that you don't fall back to 0.

```shell
$ zfs list -t snapshot |grep dr1
zroot/jails/containers/nextspace-dr1@base                                                     404K      -  2.76G  -
zroot/jails/containers/nextspace-dr1@after-1                                                 1.85M      -  4.09G  -
zroot/jails/containers/nextspace-dr1@after-2                                                 1.64M      -  4.10G  -
zroot/jails/containers/nextspace-dr1@after-3a                                                1.44M      -  5.35G  -
zroot/jails/containers/nextspace-dr1@after-3b                                                1.43M      -  5.36G  -
zroot/jails/containers/nextspace-dr1@after-4                                                 5.19M      -  5.42G  -
zroot/jails/containers/nextspace-dr1@after-5                                                 3.98M      -  5.47G  -
zroot/jails/containers/nextspace-dr1@after-7                                                  476K      -  5.53G  -
zroot/jails/containers/nextspace-dr1@after-8                                                  588K      -  5.54G  -
zroot/jails/containers/nextspace-dr1@after-9                                                  540K      -  5.70G  -
```

## Install

OK eager beavers, some of you said "What's up with this jail noise? I'm going
to install this developer release cobbled together by a rando on the internet
on my system with no precautions." Nice to see you here.

For those working in a jail (please, please) and for those installing this on
your main system, do what the TL;DR said. Go into `Installer/FreeBSD` and run
the scripts in order.  You might want to use `sh -xe` or `sh -e` or just `sh`
to run the scripts or potentially catch output with `tee(1)`.

At the end, run `/usr/local/NextSpace/Apps/Workspace.app/Workspace`. It
should work. If things break look at the executing terminal or double-check
`~/Library/Preferences/.NextSpace/WMState.plist`

_Inconsistently_ my first run would crash. Re-running seemed to fix things.

## Configuration

### Terminal.app

1. If `Terminal AlternateAsMeta YES` and `Terminal PreserveReadlineWordMovement YES`, you will get your alt+f/b to work as GNU readline (word-forward/backward)
`

## Issues

Bound to be tons. You can report them, or, even better, patch them. We can use
my fork to track BSD work until I can align with Sergeii on if/whether to fold
back to NEXTSPACE.

## Author of FreeBSD "Port"

Steven G. Harms (sgharms@stevengharms.com)

## Recognition/Thanks

Sergeii did all the heavy lifting on this thing. I never want to compete with
his project being the canonical home. I hope we can work to unify the
installers and codebases in future.

Thanks to David Chisnall who wrote the Objective-C runtime we use and who
offered some help during my darkest moments here. Ditto Jens Finkhaeuser and
"Window Maker Live."

The FreeBSD ports maintainers for GNUStep deps / FreeBSD patches. Without you,
I could not have done this. My C simply wasn't up to the task and your patches
made the difference. And thanks to FreeBSD for being awesome and having the
`ports(7)` infrastructure. Thanks to Joe Maloney for maintaining the packages I
raided.

Thanks to the folks on my [Issue 506] asking for FreeBSD support. This is a
(late-) nights and weekends and lunch break project for me. As all OSS
contributors know, this work is 0-sum: to give here other loved ones and
hobbies gathered dust. Some strangers offering encouragement helps.

## Miscellaneous Notes

## Script: `3_build_core.sh`

OK here's one that's ripe for bugs. Here we're installing into directories that
make sense on Linux but might not be right for FreeBSD. It'd be easy to miss
one (or three). I'm going to annotate what I've noticed about these files, per
FreeBSD. Also, I'll document my understanding of C build and install pipelines
so that someone more familiar can correct me.

* Primary data source: `CORE_SOURCES=${PROJECT_DIR}/Core/os_files`
* A file used in the logic of `NSSavePanel` to define what's hidden: `$CP_CMD
  ${CORE_SOURCES}/dot_hidden /.hidden` * Important repository of configuration
  data `$DEST_DIR/Library/Preferences`
* Add netspace shared library search path by adding `nextspace.conf` to
  `/usr/local/libdata/ldconfig/`: `$CP_CMD -v
  ${CORE_SOURCES}/etc/ld.so.conf.d/nextspace.conf /usr/local/libdata/ldconfig/` *
Append Xresources data to `$DEST_DIR/etc/X11/xinit/.Xresources` based on
  `/usr/local/etc/X11/xinit/xinitrc` which expects a `.Xresources` local to it
  for sourcing as a system-wide capability * Configure `polkit` (a dependency):
  `$CP_CMD ${CORE_SOURCES}/etc/polkit-1/rules.d/*.rules
  $DEST_DIR/etc/polkit-1/rules.d/`
* Apply `devd` (FreeBSD-specific): `$CP_CMD ${CORE_SOURCES}/etc/devd/*.conf $DEST_DIR/etc/devd/`
* FreeBSD doesn't really know about `profile.d`. But there's a lot of good
  configuration in this file. So I create a directory to put it in. Arguably it
  might be better in the `$NEXTSPACE_HOME`, but...I log a message about it
  instead. Also since we create a `skel` directory nearby, I think it makes sense
  * ***On top of that!*** This path is expected by `/usr/local/NextSpace/bin/gnustep-services` which is used to automate gnustep back-end daemons on launch
* Create and populate `/usr/local/etc/skel`, use with  `pw.useradd -k $DEST_DIR/etc/skel`
* Add startup files for root that we already did in the skeleton for regular
  users. Most of these are for applications, but a few really relevant ones are
  listed below:
  * GTK3 and PulseAudio: `$CP_CMD ${CORE_SOURCES}/etc/skel/.config /root`
    * Probably don't need PulseAudio since `sound(4)`
	* Probably same for GTK
  * $CP_CMD ${CORE_SOURCES}/etc/skel/Library /root
  * Some config bugs find home in contention between ~/Library/Preferences and the contents of the subdir `.NextSpace`. It's worth keeping **both** these directories in mind
* Aforementioned `/usr/local/NextSpace/bin/gnustep-services` script comes
  with: `$CP_CMD ${CORE_SOURCES}/usr/NextSpace/bin/* $NEXTSPACE_HOME/bin/`
* Copy cursors and Plymouth

Clearly build-core has a lot of opportunities to put something in the wrong
spot as we try to put the file system layout into FreeBSD idiom. If you can
`find(1)` what you needed in a reasonable, but wrong, directory it probably
went wrong in this step. Please patch :).

Suffice it to say, you ***really want to have a snapshot on either side of
this.***

## Script: `3_build_tools-make.sh`

Finally, we're into GNUstep deps. Most of this is pretty straight-forward: we
leverage the power of `ports(7)` to get gnustep-make in place. The real magic
is the tiny little `fsl` file . This defines our installation directories and
expectations about what goes where.

I've created a custom: `Core/nextspace-freebsd.fsl`. Big takeaways (see
comments inside for more):

1. We set the prefix to `/usr/local` per FreeBSD standard
2. We **do not** prefix to `/usr/local/GNUstep/...` or
   `/usr/local/NextSpace/...` because this infrastructure is kinda a hybrid of
   both.
3. Makefiles (important for building other stuff) are
   `/usr/local/Developer/Makefiles`
4. NextSpace, or _System_ apps go in `/usr/local/NextSpace`, makes sense
5. Developer apps go in `/usr/local/Developer` (Gorm.app, ProjectCenter.app)
6. Local apps go in `/usr/local/Applications`

I think this setup keeps the system versus userland distinction of FreeBSD
together but also dishonors GNUstep conventions in the way that NextSpace
intends.

Many of the porting bugs I've fought have originated in something important
being in the wrong place from _either_ GNUstep's _or_ NextSpace's point of
view. ***Really*** you should have a snapshot before and after this step.

Additionally, we're going to drop a custom `pkg-plist` in. Since we're
leveraging ports(7), we need to make sure that final packaging steps (the
post-install target of the `ports(7)` `Makefile`  and the `pkg-plist` contents
file are appropriate to get this installed).

If all goes well:

```
# ls -1 /usr/local/Developer/Makefiles/ |wc -l
      67
```

and `/usr/local/Library/Preferences/GlobalDefaults.plist` exists.

## Script: `4_build_libwraster.sh`

OK an easy one. This uses `port(7)` to install the [w]indow maker [raster]
library.

## Script: `5_build_libs-base.sh`

Biggest warning here, this install is big due to transitive dependencies. Try
to do this one only on fast connections.

Corollary: Because of the _freaking gigantic_ dependency install surface area
there is so, so much that could go wrong here. The package and its deps are
just begging to go out of support / have a vulnerability. I really am concerned
about this guy.

root@nextspace-dr1:/src/Packaging/Sources # find /usr/local -name libgnustep\*
/usr/local/Library/Libraries/libgnustep-base.so.1.31.1
/usr/local/Library/Libraries/libgnustep-base.so.1.31
/usr/local/Library/Libraries/libgnustep-base.so
root@nextspace-dr1:/src/Packaging/Sources # 

Also: start `gdomap` (as root) and make edit via `sysrc`.

## Script: `6_build_libs-gui.sh`

root@nextspace-dr1:/src/Packaging/Sources # find /usr -name libgnustep-gui\*
/usr/local/Library/Libraries/libgnustep-gui.so.0.32.0
/usr/local/Library/Libraries/libgnustep-gui.so
/usr/local/Library/Libraries/libgnustep-gui.so.0

## `7_build_libs-back.sh`

This installs the ART rendering back-end. The fonts provided by this may be too
tiny. Sergii' implementation was using ART, so I've retained that here. I may
need to change to Cairo so that we get more fonts / bigger fonts.

## `8_build_Frameworks.sh`

A lot of the logic for NEXTSPACE is retained within these files. Breakage
around sound support is in here as well (that's also where it could be fixed
;)).

## `9_build_Applications.sh`

Here's a nice makefile to instal the applications. Yay!

## FAQ: Troubleshooting

### Alt-Tab Window Switching Not Working

**Problem**: Pressing Alt+Tab doesn't show the application switcher panel.

**Root Causes**:
1. Wrong key binding names in WM.plist configuration
2. Using unsupported modifier names like "Mod1" instead of "Alt"

**Solution**:

Edit `~/Library/Preferences/.NextSpace/WM.plist` and verify these settings:

```xml
<key>GroupNextKey</key>
<string>Alt+Tab</string>
<key>GroupPrevKey</key>
<string>Alt+Shift+Tab</string>
```

**Common Mistakes**:
- Using `FocusNextKey` instead of `GroupNextKey` (cycles windows within app, not between apps)
- Using "Mod1" instead of "Alt" (Mod1/Mod2/etc are not recognized by the keyboard parser)

**Key Binding Reference**:
- `GroupNextKey`/`GroupPrevKey` - Switch between applications (Alt-Tab behavior)
- `FocusNextKey`/`FocusPrevKey` - Switch between windows of same application
- Supported modifier names: Alt, Control, Shift, Super, Command, Hyper
- Unsupported: Mod1, Mod2, Mod3, Mod4, Mod5 (use semantic names instead)

After editing, restart Workspace for changes to take effect.

### Caps Lock as Control Not Working

**Problem**: Want Caps Lock to function as Control key (common ergonomic preference).

**Root Cause**: Incorrect XKB option in NXGlobalDomain configuration. The default `"caps:ctrl_modifier"` makes Caps Lock act as both Caps Lock and Control, not just Control.

**Solution**:

Edit `~/Library/Preferences/.NextSpace/NXGlobalDomain` and change the keyboard option:

**Change from**:
```
KeyboardOptions = (
    "kpdl:dot",
    "numpad:mac",
    "caps:ctrl_modifier",     // Wrong - acts as both Caps and Ctrl
    "grp:win_space_toggle"
);
```

**Change to**:
```
KeyboardOptions = (
    "kpdl:dot",
    "numpad:mac",
    "ctrl:nocaps",            // Correct - Caps Lock acts as Control only
    "grp:win_space_toggle"
);
```

**Alternative XKB Options**:
- `"ctrl:nocaps"` - Caps Lock as Control (recommended)
- `"ctrl:swapcaps"` - Swap Caps Lock and Control positions
- `"caps:escape"` - Caps Lock as ESC (popular with Vim users)
- `"caps:none"` - Disable Caps Lock completely

**Testing**:
After restarting Workspace, test with readline shortcuts (Control+P for previous line, Control+N for next line, etc.). Note that in GNUstep/NextSpace, copy/paste uses Command (Alt), not Control.

After editing, restart Workspace for changes to take effect.

### Faster Builds: Skipping GORM and ProjectCenter

**Problem**: Building all applications with `9_build_Applications.sh` is slow, especially when you only need to rebuild Workspace.

**Solution**:

Use the `SKIP_GORM_PC` environment variable to skip building GORM and ProjectCenter:

```sh
# If using doas (FreeBSD standard)
doas env SKIP_GORM_PC=1 ./9_build_Applications.sh

# If using sudo (Linux)
sudo SKIP_GORM_PC=1 ./9_build_Applications.sh

# Or export it first
export SKIP_GORM_PC=1
doas -E ./9_build_Applications.sh
```

This significantly reduces build time by only building Workspace and the essential system applications, skipping the developer tools (GORM and ProjectCenter).

**When to use this**:
- During iterative development/debugging of Workspace
- When you don't need the IDE tools
- When doing quick rebuilds after code changes

**Note**: You'll still get a fully functional NextSpace desktop environment; you just won't have the visual interface builder (GORM) or IDE (ProjectCenter).

[GNUmake]: https://www.gnu.org/software/make/manual/make.html
[FBSDHBJail]: https://docs.freebsd.org/en/books/handbook/jails/
[NEXTSPACE]: https://github.com/trunkmaster/nextspace/
[Issue 506]: https://github.com/trunkmaster/nextspace/issues/506
