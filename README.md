# Voicemod on Linux

A helper tool for running Voicemod on Linux systems(tested on Ubuntu, Fedora(distrobox), Arch(distrobox))
that uses a custom version of [wine](https://github.com/Hamilt79/wine-voicemod) to get around the 
incompatibility issues. 

## Install

### Video Install Demo
> AUDIO WARNING: A somewhat loud sound effect is played at the end

https://github.com/user-attachments/assets/edfe3502-bea7-45b9-b037-a1f099b1e9f5

### Text Install Directions
Download the Voicemod installer EXE from voicemod.net.
> It should look something like "VoicemodInstaller_1.6.22-lyz4mh.exe" \
> The exact version/ending characters shouldn't matter

Then run:

```sh
git clone https://github.com/Hamilt79/linux-voicemod
cd linux-voicemod
./setup --prebuilt /path/to/VoicemodInstaller.exe
```
> Remove --prebuilt to build Wine yourself; it takes 10 to 30 minutes but is more reliable across different systems.

After that, you should be able to choose Voicemod from your choice of 
application menus, or run:

```sh
./voicemod
```

Sign in as usual. Voicemod should open a sign-in page in your browser.
> During the installation process, if Voicemod asks you to install their drive, decline. \
> If you just see a white rectangle window for several minutes during the installation,
> close it from the toolbar and try to reopen Voicemod from the application menu. 

Select **Voicemod Microphone** as the input device in *other* software,
and your real mic as the input device in Voicemod. 
> If you find no audio coming through, go to the Voicemod settings and reselect your correct microphone. 

## Commands

| Command | Effect |
| --- | --- |
| `./voicemod` | Start Voicemod and create its audio devices |
| `./voicemod --stop` | Close Voicemod and remove its audio devices |
| `./voicemod --status` | Show whether Voicemod and its devices are up |
| `./setup` | Refresh the setup, for example after updating this repository |
| `./setup --prebuilt` | Download Wine instead of building it |
| `./setup --rebuild-wine` | Rebuild Wine from scratch |

The **Voicemod** output device and the **Voicemod Microphone** exist only
while Voicemod runs. They are removed when it exits.

## Voicemod's Keybinds in other applications

Voicemod's soundboard and other keybinds should also now work with the program. 
How far that reaches depends on the session, because Wayland only shows an application
the keys typed into its own windows, and Voicemod runs as an X11 application

| Session | Keybinds work while the focus is on |
| --- | --- |
| X11 | Any application |
| Wayland | Voicemod and other X11 applications |
| Wayland on KDE Plasma, with the setting below | Any application(probably) |

On KDE Plasma, **System Settings -> Legacy X11 App Support** has options that
let X11 applications read keys typed into all applications. It is off by default. \
You should change it to whatever you are comfortable with privacy-wise, but the default
*Prohibited* option may be fine for the applications you wish to use. I suggest 
trying it out as-is, then upping the support level if needed.

GNOME does not have such an option, as far as I understand, but the default behaviour might be fine.

## Requirements

- PipeWire with its PulseAudio server, or PulseAudio
- A Vulkan-capable GPU driver
- A network connection during setup. `./setup` downloads DXVK and whatever
  Voicemod's installer fetches.
- The packages below. `./setup` checks for them and prints the same lists if any
  are missing.

For `./setup --prebuilt`:

```sh
# Debian, Ubuntu, Mint
sudo apt install git curl xz-utils pulseaudio-utils util-linux \
    libfreetype6 libfontconfig1 libgnutls30t64 libvulkan1 libpulse0 libdbus-1-3 \
    libgl1 libegl1 libx11-6 libxext6 libxcomposite1 libxcursor1 libxfixes3 \
    libxinerama1 libxi6 libxrandr2 libxrender1 libxxf86vm1
# Fedora
sudo dnf install git curl xz pulseaudio-utils util-linux \
    freetype fontconfig gnutls vulkan-loader pulseaudio-libs dbus-libs \
    mesa-libGL mesa-libEGL libX11 libXext libXcomposite libXcursor libXfixes \
    libXinerama libXi libXrandr libXrender libXxf86vm
# Arch, CachyOS
sudo pacman -S --needed git curl xz libpulse util-linux \
    freetype2 fontconfig gnutls vulkan-icd-loader dbus libglvnd libx11 libxext \
    libxcomposite libxcursor libxfixes libxinerama libxi libxrandr libxrender \
    libxxf86vm
```
> These were confirmed to be the right choices in a distrobox container, but
> if there are any more missing packages, feel free to let me know.

The prebuilt Wine needs glibc 2.38 or newer: Ubuntu 24.04, Mint 22, Fedora 39,
Debian 13, Arch, or later. \
On older systems, build Wine instead.

For building Wine (`./setup` without `--prebuilt`):

```sh
# Debian, Ubuntu, Mint
sudo apt install git build-essential bison flex gcc-mingw-w64 \
    g++-mingw-w64 pulseaudio-utils util-linux curl libpulse-dev libgnutls28-dev \
    libvulkan-dev libfreetype-dev libfontconfig-dev libgl-dev libegl-dev \
    libx11-dev libxext-dev libxcomposite-dev libxcursor-dev libxfixes-dev \
    libxi-dev libxinerama-dev libxrandr-dev libxrender-dev libxxf86vm-dev \
    libxkbcommon-dev libwayland-dev libasound2-dev libdbus-1-dev libudev-dev \
    libavcodec-dev libavformat-dev libavutil-dev ocl-icd-opencl-dev
# Fedora
sudo dnf install git gcc make bison flex mingw64-gcc mingw32-gcc \
    mingw64-gcc-c++ mingw32-gcc-c++ pulseaudio-utils util-linux curl \
    pulseaudio-libs-devel gnutls-devel vulkan-loader-devel freetype-devel \
    fontconfig-devel mesa-libGL-devel mesa-libEGL-devel libX11-devel libXext-devel \
    libXcomposite-devel libXcursor-devel libXfixes-devel libXi-devel \
    libXinerama-devel libXrandr-devel libXrender-devel libXxf86vm-devel \
    libxkbcommon-devel wayland-devel alsa-lib-devel dbus-devel systemd-devel \
    ffmpeg-free-devel ocl-icd-devel
# Arch, CachyOS
sudo pacman -S --needed base-devel git mingw-w64-gcc libpulse gnutls \
    vulkan-headers vulkan-icd-loader freetype2 fontconfig mesa libglvnd libx11 \
    libxext libxcomposite libxcursor libxfixes libxi libxinerama libxrandr \
    libxrender libxxf86vm libxkbcommon wayland alsa-lib dbus systemd-libs ffmpeg \
    opencl-headers ocl-icd
```
> Same deal

## Layout

| Path | Contents |
| --- | --- |
| `setup`, `voicemod` | The two entry points |
| `lib/common.sh` | Shared paths and helpers |
| `wine/` | Wine with the Voicemod changes, a git submodule |
| `wine-build/` | Wine, built or downloaded by `setup` |
| `package-wine` | Packages a built Wine as a prebuilt release |
| `dxvk/` | DXVK, downloaded by `setup` |
| `prefix/` | The Wine prefix holding Voicemod and your Voicemod settings |
| `logs/` | Build, installer and last session logs |
| `config` | Optional overrides, see below |

`config` is an optional shell file. Useful settings:

```sh
VOICEMOD_PREFIX=/path/to/prefix       # keep the prefix elsewhere
VOICEMOD_DXVK_DIR=/path/to/dxvk/x64   # use this DXVK instead of downloading
VOICEMOD_WINEDEBUG=+voicemod          # Wine debug channels for session.log
JOBS=8                                # parallel build jobs
```

## Why a modified Wine

Voicemod relies on a Windows kernel audio driver and a few Windows behaviors
that Wine does not provide. The changes live in a small fork of Wine at:
[wine-voicemod](https://github.com/Hamilt79/wine-voicemod). \
This repository includes this fork as a submodule. 

| Change | Purpose |
| --- | --- |
| `winevoicemod.sys` | A stand-in for Voicemod's kernel driver |
| `ntdll` | Lets Voicemod register its event handle with that driver |
| `mmdevapi` | Reports a listener on the virtual microphone, so Voicemod processes your voice without "Listen to myself" |
| `setupapi`, `wbemprox` | Device lookup functions Voicemod calls at startup |
| `winepulse.drv` | Presents the bridge devices under the names Voicemod searches for |
| `msvcrt` | Fixes number parsing that made voices such as Clean mic fail to load |
| `winex11.drv`, `win32u` | Fixes maximizing and restoring the window, and passes keys pressed in other applications to Voicemod's keybinds |

## Updating Voicemod

You should be able to accept Voicemod's update prompts with no issue, and the program
*should* continue to work. It's been tested across a few minor changes, but nothing big yet. \  
If an update fails, you can try re-running the `./setup` script with the new installer.

When Voicemod asks **"Voicemod can't find its driver installed. Would you like
to install it now?"**, answer **No**. Its Windows driver cannot work under
Wine. 
> If the question keeps returning after an update and I haven't pushed out a new version,
> you can change the expected driver version by setting `VOICEMOD_DRIVER_VERSION` in `config`.

## Troubleshooting

Logs are in `logs/`: `wine-build.log`, `installer.log` and `session.log` for
the last start. Voicemod's own log is at
`prefix/drive_c/users/<you>/AppData/Local/VoicemodV3/logs/voicemod-desktop.log`.

- **"The prebuilt Wine does not run on this system."** Your system isn't
  compatible with the version of Wine I package; you will need to build Wine
  yourself:
  
  ```sh
  ./setup --rebuild-wine /path/to/VoicemodInstaller.exe
  ```

- **"Missing system libraries" or "Missing tools".** Install the packages
  named in the message, then run `./setup` again.
- **Black window.** DXVK needs a working Vulkan driver. Check that `vulkaninfo`
  (package `vulkan-tools`) lists your GPU.
- **"Not a Windows installer."** You didn't set the path to the EXE right, it should be:
  
  ```sh
  ./setup --rebuild-wine /path/to/VoicemodInstaller.exe
  ```

- **The browser's "Open app" button does nothing.** The login link handler
  is missing or points elsewhere. Run `./setup` again to register it, then
  sign in again.
- **Voicemod asks to install its driver.** Answer **No**, see
  [Updating Voicemod](#updating-voicemod).
- **No "Voicemod Microphone" in an application.** Start Voicemod first; the
  devices exist only while it runs. Some applications only list devices that
  existed when they started, so restart the application.

## Known issues

- **It can be hard to move the Voicemod window around again after maximizing it.** I'm working on it.

## Removing

```sh
./voicemod --stop
rm ~/.local/share/applications/voicemod-linux.desktop
```

Then delete this directory or only the prefix.

## License

The scripts in this repository are under the [MIT License](LICENSE). Wine, in
the `wine` submodule, is under the LGPL 2.1 or later.
