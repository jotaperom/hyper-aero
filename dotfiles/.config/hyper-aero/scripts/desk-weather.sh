#!/usr/bin/env bash

loc_file="$HOME/.config/hyper-aero/weather-location"
loc=""
[ -f "$loc_file" ] && loc=$(head -n1 "$loc_file" | sed 's/ /+/g')

offline='{"ok":false,"place":"","icon":"","temp":"--","desc":"","hi":"--","lo":"--","hum":"--","wind":"--"}'

data=$(curl -sf --max-time 10 "https://wttr.in/${loc}?format=j1")
if [ -z "$data" ]; then
    echo "$offline"
    exit 0
fi

echo "$data" | jq -c '
    def icon(c):
        if c == "113" then ""
        elif c == "116" then ""
        elif (c == "119" or c == "122") then ""
        elif (["143", "248", "260"] | index(c)) then ""
        elif (["200", "386", "389", "392", "395"] | index(c)) then ""
        elif (["179", "182", "185", "227", "230", "281", "284", "311", "314", "317", "320", "323", "326", "329", "332", "335", "338", "350", "362", "365", "368", "371", "374", "377"] | index(c)) then ""
        else "" end;
    .current_condition[0] as $c
    | .weather[0] as $w
    | .nearest_area[0] as $a
    | {
        ok: true,
        place: ($a.areaName[0].value | ascii_upcase),
        icon: icon($c.weatherCode),
        temp: $c.temp_C,
        desc: ($c.weatherDesc[0].value | ascii_upcase),
        hi: $w.maxtempC,
        lo: $w.mintempC,
        hum: $c.humidity,
        wind: ($c.windspeedKmph + " km/h")
    }
' 2>/dev/null || echo "$offline"
