#!/usr/bin/env bash

dev=""
for d in /sys/class/net/*; do
    [ -d "$d/wireless" ] && dev=$(basename "$d") && break
done

if systemctl is-active --quiet NetworkManager; then
    backend=nm
elif systemctl is-active --quiet iwd; then
    backend=iwd
else
    notify-send -a "SIGNAL" "Wireless" "No network service is running (NetworkManager or iwd)."
    exit 1
fi

if [ -z "$dev" ]; then
    notify-send -a "SIGNAL" "Wireless" "No Wi-Fi adapter found."
    exit 1
fi

if [ "$1" = "advanced" ]; then
    if [ "$backend" = nm ]; then
        exec kitty --class aero-wifi -e nmtui
    else
        exec kitty --class aero-wifi -e iwctl
    fi
fi

theme='
    window        { width: 560px; location: north east; anchor: north east; x-offset: -310px; y-offset: 54px; }
    mainbox       { children: [ box-header, inputbar, message, listview ]; }
    textbox-title { content: "NEXUS // WIRELESS"; }
    inputbar      { children: [ textbox-orb, prompt, entry ]; }
    entry         { placeholder: "Search networks"; font: "Exo 2 12"; }
    listview      { columns: 1; lines: 10; spacing: 2px; }
    element       { orientation: horizontal; padding: 8px 14px; border-radius: 10px; }
    element-icon  { size: 0; }
    element-text  { horizontal-align: 0; font: "JetBrainsMono Nerd Font 10"; }
'

pw_theme='
    window        { width: 420px; location: north east; anchor: north east; x-offset: -310px; y-offset: 54px; }
    mainbox       { children: [ box-header, message, inputbar ]; }
    textbox-title { content: "NEXUS // ACCESS CODE"; }
    inputbar      { children: [ textbox-orb, prompt, entry ]; }
    entry         { placeholder: "Network password"; font: "JetBrainsMono Nerd Font 12"; }
'

radio_on() {
    if [ "$backend" = nm ]; then
        [ "$(nmcli radio wifi)" = "enabled" ]
    else
        iwctl device "$dev" show 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | grep -q "Powered *on"
    fi
}

set_radio() {
    if [ "$backend" = nm ]; then
        nmcli radio wifi "$1"
    else
        [ "$1" = on ] && v=on || v=off
        iwctl device "$dev" set-property Powered "$v"
    fi
}

list_nm() {
    nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID device wifi list --rescan "$1" 2>/dev/null \
        | sed 's/\\\\/\x02/g; s/\\:/\x01/g' \
        | awk -F: '{
            ssid = $4
            if (ssid == "") next
            sec = $3
            gsub("\x01", ":", ssid); gsub("\x02", "\\", ssid)
            gsub("\x01", ":", sec)
            printf "%d\t%d\t%s\t%s\n", ($1 == "*"), $2, sec, ssid
        }'
}

list_iwd() {
    if [ "$1" = "yes" ]; then
        iwctl station "$dev" scan >/dev/null 2>&1
        sleep 3
    fi
    iwctl station "$dev" get-networks rssi-dbms 2>/dev/null \
        | sed 's/\x1b\[[0-9;]*m//g' \
        | grep -v -e 'Available networks' -e 'Network name' -e '^-*$' -e '^ *$' \
        | awk '{
            cur = 0
            if ($1 == ">") { cur = 1; $1 = "" }
            sig = $NF; sec = $(NF - 1)
            $NF = ""; $(NF - 1) = ""
            name = $0
            gsub(/^ +| +$/, "", name)
            if (name == "") next
            pct = int(2 * (sig / 100 + 100))
            if (pct > 100) pct = 100
            if (pct < 0) pct = 0
            printf "%d\t%d\t%s\t%s\n", cur, pct, sec, name
        }'
}

networks() {
    if [ "$backend" = nm ]; then
        list_nm "$1"
    else
        list_iwd "$1"
    fi | sort -t$'\t' -k1,1nr -k2,2nr | awk -F'\t' '!seen[$4]++'
}

sec_label() {
    case "$1" in
        ""|"--"|open) echo "OPEN" ;;
        *802.1X*|*8021x*) echo "ENTERPRISE" ;;
        *) echo "SECURED" ;;
    esac
}

bars() {
    if [ "$1" -ge 75 ]; then echo "▂▄▆█"
    elif [ "$1" -ge 50 ]; then echo "▂▄▆ "
    elif [ "$1" -ge 25 ]; then echo "▂▄  "
    else echo "▂   "
    fi
}

ask_password() {
    rofi -dmenu -password -p "KEY" -mesg "Enter the password for <b>$1</b>" -theme-str "$pw_theme" < /dev/null
}

connect_nm() {
    local ssid="$1" label="$2"
    if nmcli -t -f NAME connection show | grep -Fxq "$ssid"; then
        nmcli connection up id "$ssid" >/dev/null 2>&1 && return 0
        nmcli connection delete id "$ssid" >/dev/null 2>&1
    fi
    case "$label" in
        OPEN)
            nmcli device wifi connect "$ssid" >/dev/null 2>&1
            ;;
        ENTERPRISE)
            notify-send -a "SIGNAL" "$ssid" "Enterprise network: opening advanced setup for username and password."
            kitty --class aero-wifi -e nmtui &
            return 2
            ;;
        *)
            local pw
            pw=$(ask_password "$ssid")
            [ -z "$pw" ] && return 3
            if ! nmcli device wifi connect "$ssid" password "$pw" >/dev/null 2>&1; then
                nmcli connection delete id "$ssid" >/dev/null 2>&1
                return 1
            fi
            ;;
    esac
}

connect_iwd() {
    local ssid="$1" label="$2"
    iwctl --dont-ask station "$dev" connect "$ssid" >/dev/null 2>&1 && return 0
    case "$label" in
        OPEN)
            return 1
            ;;
        ENTERPRISE)
            notify-send -a "SIGNAL" "$ssid" "Enterprise networks need a profile file with iwd. Create one with iwctl or in /var/lib/iwd."
            return 2
            ;;
        *)
            local pw
            pw=$(ask_password "$ssid")
            [ -z "$pw" ] && return 3
            iwctl --passphrase "$pw" station "$dev" connect "$ssid" >/dev/null 2>&1
            ;;
    esac
}

disconnect() {
    if [ "$backend" = nm ]; then
        nmcli device disconnect "$dev" >/dev/null 2>&1
    else
        iwctl station "$dev" disconnect >/dev/null 2>&1
    fi
}

rescan="auto"

while true; do
    entries=()
    actions=()
    ssids=()
    labels=()

    if ! radio_on; then
        mesg="Wi-Fi is <b>OFF</b>"
        entries+=("⏻  TURN WI-FI ON")
        actions+=("radio-on"); ssids+=(""); labels+=("")
    else
        mapfile -t rows < <(networks "$rescan")
        rescan="auto"

        linked=""
        for row in "${rows[@]}"; do
            IFS=$'\t' read -r cur sig sec ssid <<< "$row"
            [ "$cur" = 1 ] && linked="$ssid"
        done

        if [ -n "$linked" ]; then
            ip=$(ip -4 -o addr show dev "$dev" 2>/dev/null | awk '{ sub("/.*", "", $4); print $4; exit }')
            mesg="LINKED  ·  <b>$linked</b>  ·  ${ip:-acquiring address}"
        else
            mesg="NOT CONNECTED  ·  ${#rows[@]} networks in range"
        fi

        for row in "${rows[@]}"; do
            IFS=$'\t' read -r cur sig sec ssid <<< "$row"
            label=$(sec_label "$sec")
            if [ "$cur" = 1 ]; then
                state="● LINKED"
            else
                state=""
            fi
            entries+=("$(printf '%s  %-28.28s  %-10s  %s' "$(bars "$sig")" "$ssid" "$label" "$state")")
            if [ "$cur" = 1 ]; then
                actions+=("disconnect")
            else
                actions+=("connect")
            fi
            ssids+=("$ssid"); labels+=("$label")
        done

        entries+=("⟳     RESCAN")
        actions+=("rescan"); ssids+=(""); labels+=("")
        entries+=("⏻     TURN WI-FI OFF")
        actions+=("radio-off"); ssids+=(""); labels+=("")
    fi

    entries+=("⚙     ADVANCED SETTINGS")
    actions+=("advanced"); ssids+=(""); labels+=("")

    choice=$(printf '%s\n' "${entries[@]}" \
        | rofi -dmenu -i -no-custom -format i -p "WIFI" -mesg "$mesg" -theme-str "$theme")

    [ -z "$choice" ] && exit 0

    action="${actions[$choice]}"
    ssid="${ssids[$choice]}"
    label="${labels[$choice]}"

    case "$action" in
        rescan)
            notify-send -a "SIGNAL" "Wireless" "Scanning for networks…" -t 2500
            rescan="yes"
            ;;
        radio-on)
            set_radio on
            sleep 3
            ;;
        radio-off)
            set_radio off
            notify-send -a "SIGNAL" "Wireless" "Wi-Fi turned off"
            exit 0
            ;;
        advanced)
            exec "$0" advanced
            ;;
        disconnect)
            disconnect
            notify-send -a "SIGNAL" "$ssid" "Disconnected"
            exit 0
            ;;
        connect)
            notify-send -a "SIGNAL" "$ssid" "Linking…" -t 3000
            if [ "$backend" = nm ]; then
                connect_nm "$ssid" "$label"
            else
                connect_iwd "$ssid" "$label"
            fi
            case $? in
                0) notify-send -a "SIGNAL" "$ssid" "Connected" ;;
                1) notify-send -a "SIGNAL" -u critical "$ssid" "Couldn't connect. Check the password and try again." ;;
            esac
            exit 0
            ;;
    esac
done
