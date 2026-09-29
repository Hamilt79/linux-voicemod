# shellcheck shell=bash
# Shared paths and helpers for the Voicemod on Linux scripts.

vm_root=$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd)

# Optional local overrides (VOICEMOD_PREFIX, VOICEMOD_DXVK_DIR, JOBS, ...).
# shellcheck source=/dev/null
[[ -f "$vm_root/config" ]] && source "$vm_root/config"

wine_src="$vm_root/wine"
wine_build=${VOICEMOD_WINE_BUILD:-"$vm_root/wine-build"}
wine_bin="$wine_build/wine"

# Deliberately not inherited from the caller's WINEPREFIX, which usually
# belongs to an unrelated Wine installation.
export WINEPREFIX=${VOICEMOD_PREFIX:-"$vm_root/prefix"}
export WINESERVER="$wine_build/server/wineserver"
export WINEDEBUG=${VOICEMOD_WINEDEBUG:--all}
unset WINEARCH WINELOADER WINEDLLPATH
# winemenubuilder writes menu entries and file associations into the user's
# desktop which call a system-wide 'wine' on this prefix.  It must be disabled
# for every process: Wine's services keep the environment of whichever
# command started them.
export WINEDLLOVERRIDES='winemenubuilder.exe=d'

app_exe='C:\Program Files\Voicemod V3\Voicemod.exe'
app_unix="$WINEPREFIX/drive_c/Program Files/Voicemod V3/Voicemod.exe"
session_lock="$WINEPREFIX/.voicemod-session.lock"
log_dir="$vm_root/logs"

sink_name=voicemod_bridge
mic_name=voicemod_mic
driver_version=${VOICEMOD_DRIVER_VERSION:-2022.6.1.0}
dxvk_version=3.1.1
dxvk_sha256=40565b4a724aadc4433fa4e010b4b23916d9b1f1baeee64e17186db94f54e608

say()  { printf '\033[1m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

vm_wine()
{
    "$wine_bin" "$@"
}

require_wine()
{
    [[ -x "$wine_bin" && -x "$WINESERVER" &&
       -f "$wine_build/dlls/winevoicemod.sys/x86_64-windows/winevoicemod.sys" ]] ||
        die "Wine is not built yet. Run $vm_root/setup first."
}

require_pactl()
{
    command -v pactl >/dev/null ||
        die "pactl was not found. Install the PulseAudio client utilities (pulseaudio-utils)."
}

# --- audio devices ---------------------------------------------------------

pulse_module_ids()
{
    # $1: module name, $2: argument that identifies our instance
    pactl list short modules 2>/dev/null |
        awk -F'\t' -v module="$1" -v arg="$2" \
            '$2 == module && index(" " $3 " ", " " arg " ") { print $1 }'
}

audio_up()
{
    require_pactl
    if [[ -z "$(pulse_module_ids module-null-sink "sink_name=$sink_name")" ]]; then
        pactl load-module module-null-sink "sink_name=$sink_name" rate=48000 channels=2 \
            'sink_properties="device.description=\"Voicemod\" device.api=voicemod node.virtual=false"' \
            >/dev/null || die "Could not create the Voicemod output device."
    fi
    # Applications and desktop mixers hide monitor sources, so expose the
    # processed voice as a regular microphone.  device.api makes PipeWire
    # report it as hardware; Plasma hides sources without that flag.
    if [[ -z "$(pulse_module_ids module-remap-source "source_name=$mic_name")" ]]; then
        pactl load-module module-remap-source \
            "master=$sink_name.monitor" "source_name=$mic_name" rate=48000 channels=2 \
            'source_properties="device.description=\"Voicemod Microphone\" device.api=voicemod device.form_factor=microphone device.icon_name=audio-input-microphone node.virtual=false"' \
            >/dev/null || die "Could not create the Voicemod microphone."
    fi
}

audio_down()
{
    local id
    command -v pactl >/dev/null || return 0
    for id in $(pulse_module_ids module-remap-source "source_name=$mic_name") \
              $(pulse_module_ids module-null-sink "sink_name=$sink_name"); do
        pactl unload-module "$id" 2>/dev/null || true
    done
}

# --- prefix configuration --------------------------------------------------

# Imports registry text from stdin.  "Windows Registry Editor Version 5.00"
# files are UTF-16; Wine reads any other encoding as ANSI and then mangles
# expandable strings.
reg_import()
{
    local reg="$WINEPREFIX/.voicemod-$1.reg"

    { printf '\xff\xfe'; iconv -f UTF-8 -t UTF-16LE; } >"$reg"
    vm_wine regedit /S "$(vm_wine winepath -w "$reg" 2>/dev/null | tr -d '\r')"
}

# NUL-terminated UTF-16LE as the comma separated bytes a hex(2) value takes.
hex_utf16()
{
    printf '%s\0' "$1" | iconv -f UTF-8 -t UTF-16LE | od -An -v -tx1 |
        tr -s ' \n' ',' | sed 's/^,//; s/,$//'
}

# Registers the bridge driver and the values Voicemod checks before it offers
# to reinstall its native driver.  Safe to repeat; the vendor installer and
# updater overwrite the service path, so this runs before every launch.
driver_register()
{
    local source="$wine_build/dlls/winevoicemod.sys/x86_64-windows/winevoicemod.sys"
    local target="$WINEPREFIX/drive_c/windows/system32/drivers/winevoicemod.sys"

    mkdir -p -- "$(dirname -- "$target")"
    install -m 0644 -- "$source" "$target"

    reg_import driver <<EOF || die "Could not write the driver registration."
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Services\\VOICEMOD_Driver]
"DisplayName"="Voicemod Virtual Audio Device (WDM)"
"ImagePath"=hex(2):$(hex_utf16 'C:\windows\system32\drivers\winevoicemod.sys')
"Type"=dword:00000001
"Start"=dword:00000003
"ErrorControl"=dword:00000001

[HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Enum\\ROOT\\MEDIA\\0000]
"Class"="MEDIA"
"ClassGUID"="{4D36E96C-E325-11CE-BFC1-08002BE10318}"
"ConfigFlags"=dword:00000000
"DeviceDesc"="Voicemod Virtual Audio Device (WDM)"
"Driver"="{4D36E96C-E325-11CE-BFC1-08002BE10318}\\\\0000"
"Service"="VOICEMOD_Driver"

[HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Class\\{4D36E96C-E325-11CE-BFC1-08002BE10318}\\0000]
"DriverDesc"="Voicemod Virtual Audio Device (WDM)"
"DriverVersion"="$driver_version"
"ProviderName"="Voicemod"

[HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides]
"winemenubuilder.exe"=""
EOF
}

driver_start()
{
    vm_wine sc start VOICEMOD_Driver >/dev/null 2>&1 || true
}

# Prints the directory holding the 64-bit DXVK DLLs, downloading the pinned
# release on first use.
find_dxvk()
{
    local dir=${VOICEMOD_DXVK_DIR:-} archive

    if [[ -z "$dir" ]]; then
        dir="$vm_root/dxvk/dxvk-$dxvk_version/x64"
        if [[ ! -f "$dir/d3d11.dll" ]]; then
            archive="$vm_root/dxvk/dxvk-$dxvk_version.tar.gz"
            mkdir -p -- "$vm_root/dxvk"
            curl -fsSL -o "$archive" \
                "https://github.com/doitsujin/dxvk/releases/download/v$dxvk_version/dxvk-$dxvk_version.tar.gz" ||
                return 1
            if ! printf '%s  %s\n' "$dxvk_sha256" "$archive" | sha256sum -c --status; then
                rm -f -- "$archive"
                warn "The DXVK download does not match its expected checksum."
                return 1
            fi
            tar -xzf "$archive" -C "$vm_root/dxvk" && rm -f -- "$archive"
        fi
    fi
    [[ -f "$dir/d3d11.dll" && -f "$dir/dxgi.dll" ]] || return 1
    printf '%s\n' "$dir"
}

# Wine's own D3D renderer lacks the shared D3D11 textures Qt WebEngine needs,
# which leaves Voicemod's window black, so install DXVK into the prefix.
dxvk_install()
{
    local dir

    dir=$(find_dxvk) || die "Could not get DXVK. Check the network connection, or download
a release from https://github.com/doitsujin/dxvk/releases and set
VOICEMOD_DXVK_DIR in $vm_root/config to its x64 directory."

    install -m 0644 -- "$dir/d3d11.dll" "$dir/dxgi.dll" "$WINEPREFIX/drive_c/windows/system32/"
    reg_import dxvk <<'EOF' || die "Could not enable DXVK."
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Wine\DllOverrides]
"d3d11"="native"
"dxgi"="native"
EOF
    printf '%s\n' "$dir" >"$WINEPREFIX/.voicemod-dxvk-source"
}
