# Voicemod on Linux

Runs Voicemod 3 on Linux through a modified Wine, and exposes the changed voice
to Linux applications as a microphone called **Voicemod Microphone**.

## Install

Download the Windows installer from voicemod.net, then:

```sh
git clone --recursive https://github.com/Hamilt79/linux-voicemod
cd linux-voicemod
./setup /path/to/VoicemodInstaller.exe
```

The first run builds Wine, which takes 10 to 30 minutes. After that, start
Voicemod from the application menu or with:

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
| `./setup --rebuild-wine` | Rebuild Wine from scratch |

The **Voicemod** output device and the **Voicemod Microphone** exist only
while Voicemod runs. They are removed when it exits.

## Requirements

- PipeWire with its PulseAudio server, or PulseAudio
- A Vulkan-capable GPU driver
- A network connection during setup. `setup` downloads DXVK and whatever
  Voicemod's installer fetches.
- Build tools: `setup` lists the packages to install if any are missing.

## Layout

| Path | Contents |
| --- | --- |
| `setup`, `voicemod` | The two entry points |
| `lib/common.sh` | Shared paths and helpers |
| `wine/` | Wine with the Voicemod changes, a git submodule |
| `wine-build/` | The Wine build, created by `setup` |
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

Voicemod relies on a Windows kernel audio driver and a few Windows behaviours
that Wine does not provide. The changes live in a fork of Wine,
[wine-voicemod](https://github.com/Hamilt79/wine-voicemod), which this
repository includes as the `wine` submodule. They are small, about 450 lines,
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

## Updating Voicemod

Voicemod refuses to start when a newer release exists and offers to update
itself. Accept the update; the launcher re-registers the bridge driver on the
next start. If the updater fails, download the new installer and run `setup`
with it again. Your settings and login are kept.

When Voicemod asks **"Voicemod can't find its driver installed. Would you like
to install it now?"**, answer **No**. Its Windows driver cannot work under
Wine. If the question keeps returning after an update, the expected driver
version changed; set `VOICEMOD_DRIVER_VERSION` in `config`.

## Known issues

- **Voicemod loses your real microphone.** If you make **Voicemod Microphone**
  the system's default input device, Voicemod may stop using your real
  microphone. Select your real microphone again in Voicemod's input settings.

## Privacy

Voicemod contacts its update, API and telemetry services when it runs. It
verifies their certificates by pinned key, so it does not start behind an
intercepting proxy.

## Removing

```sh
./voicemod --stop
rm ~/.local/share/applications/voicemod-linux.desktop
```

Then delete this directory.
