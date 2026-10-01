# Voicemod on Linux

Runs Voicemod 3 on Linux through a modified Wine, and exposes the changed voice
to Linux applications as a microphone called **Voicemod Microphone**.

## Install

Download the Windows installer from voicemod.net, then:

```sh
git clone https://github.com/Hamilt79/linux-voicemod
cd linux-voicemod
./setup --prebuilt /path/to/VoicemodInstaller.exe
# Remove --prebuilt to build Wine yourself, which takes 10 to 30 minutes.
```

After that, start Voicemod from the application menu or with:

```sh
./voicemod
```

Sign in when Voicemod asks. The browser's **Open app** button hands the login
back to Voicemod.

In the application you want to use the voice in (Discord, OBS, a game), select
**Voicemod Microphone** as the input device. Inside Voicemod, keep your real
microphone selected as the input.

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
lets X11 applications read keys typed into all applications. It is off by
default. You should change it to whatever you are comfortable with privacy-wise, but the default
*Prohibited* option may be fine for the applications you wish to use.

GNOME does not have such an option from my understanding, but the default behaviour might be fine.

## Requirements

- PipeWire with its PulseAudio server, or PulseAudio
- A Vulkan-capable GPU driver
- A network connection during setup. `setup` downloads DXVK and whatever
  Voicemod's installer fetches.
- The packages below. `setup` checks for them and prints the same lists if any
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

The prebuilt Wine needs glibc 2.38 or newer: Ubuntu 24.04, Mint 22, Fedora 39,
Debian 13, Arch, or later. On older systems, build Wine instead.

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
that Wine does not provide. The changes live in a fork of Wine,
[wine-voicemod](https://github.com/Hamilt79/wine-voicemod), which this
repository includes as the `wine` submodule. They are small, about 600 lines,
but some of them change Wine's Linux-side core, so they cannot be shipped as
drop-in DLLs for a stock Wine.

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

Voicemod refuses to start when a newer release exists and offers to update
itself. Accept the update; the launcher re-registers the bridge driver on the
next start. If the updater fails, download the new installer and run `setup`
with it again. Your settings and login are kept.

When Voicemod asks **"Voicemod can't find its driver installed. Would you like
to install it now?"**, answer **No**. Its Windows driver cannot work under
Wine. If the question keeps returning after an update, the expected driver
version changed; set `VOICEMOD_DRIVER_VERSION` in `config`.

## Troubleshooting

Logs are in `logs/`: `wine-build.log`, `installer.log` and `session.log` for
the last start. Voicemod's own log is
`prefix/drive_c/users/<you>/AppData/Local/VoicemodV3/logs/voicemod-desktop.log`.

- **"The prebuilt Wine does not run on this system."** Your system is older
  than the one the prebuilt Wine was built on. Install the build packages above
  and build Wine instead:

  ```sh
  ./setup --rebuild-wine /path/to/VoicemodInstaller.exe
  ```

- **"Missing system libraries" or "Missing tools".** Install the packages
  named in the message, then run `setup` again.
- **Blank text, unreadable windows, or "Program Error" dialogs.** Wine is
  missing system libraries. Run `./setup` again: it checks for them.
- **Black window.** DXVK needs a working Vulkan driver. Check that `vulkaninfo`
  (package `vulkan-tools`) lists your GPU.
- **"Not a Windows installer."** The path must point to the `.exe` from
  voicemod.net, not to a file from this repository.
- **The browser's "Open app" button does nothing.** The login link handler
  is missing or points elsewhere. Run `./setup` again to register it, then
  sign in again.
- **Voicemod asks to install its driver.** Answer **No**, see
  [Updating Voicemod](#updating-voicemod).
- **No "Voicemod Microphone" in an application.** Start Voicemod first; the
  devices exist only while it runs. Some applications only list devices that
  existed when they started, so restart the application.

## Known issues

- **Voicemod loses your real microphone.** If you make **Voicemod Microphone**
  the system's default input device, Voicemod may stop using your real
  microphone. Select your real microphone again in Voicemod's input settings.

## Removing

```sh
./voicemod --stop
rm ~/.local/share/applications/voicemod-linux.desktop
```

Then delete this directory.

## License

The scripts in this repository are under the [MIT License](LICENSE). Wine, in
the `wine` submodule, is under the LGPL 2.1 or later.
