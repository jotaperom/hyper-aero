#!/usr/bin/env bash

export LC_ALL=C
y=$(date +%Y)
m=$(date +%m)
today=$(date +%-d)
first=$(date -d "$y-$m-01" +%u)
days=$(date -d "$y-$m-01 +1 month -1 day" +%-d)
month=$(date +'%B %Y' | tr '[:lower:]' '[:upper:]')

cells=()
for ((i = 1; i < first; i++)); do
    cells+=('{"d":"","t":0}')
done
for ((d = 1; d <= days; d++)); do
    t=0
    [ "$d" -eq "$today" ] && t=1
    cells+=("{\"d\":\"$d\",\"t\":$t}")
done
while (( ${#cells[@]} % 7 )); do
    cells+=('{"d":"","t":0}')
done

weeks=""
for ((i = 0; i < ${#cells[@]}; i += 7)); do
    row=$(IFS=,; echo "${cells[*]:i:7}")
    weeks+="${weeks:+,}[$row]"
done

printf '{"month":"%s","weeks":[%s]}\n' "$month" "$weeks"
