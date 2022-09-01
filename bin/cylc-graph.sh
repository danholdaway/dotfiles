#!/usr/bin/env bash

set -eu

SUITE="$1"
FMT="$2"

TMP=dotfile

cylc graph --reference "$SUITE" 2>/dev/null > "$TMP.ref"

gsed \
    -e 's/node "\(.*\)" "\(.*\)"/"\1" [label="\2"]/' \
    -e 's/edge "\(.*\)" "\(.*\)"/"\1" -> "\2"/' \
    -e '1i digraph {' \
    -e '$a}' \
    -e '/^graph$/d' \
    -e '/^stop$/d' \
    "$TMP.ref" \
    > "$TMP.dot"

dot \
    "$TMP.dot" \
    -T$FMT \
    -o "$TMP.$FMT"

rm "$TMP.ref" "$TMP.dot"
echo "$TMP.$FMT"
