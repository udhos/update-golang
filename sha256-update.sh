#!/usr/bin/env sh

sum=sha256sum
out=update-golang.sh.sha256

if hash $sum 2>/dev/null; then
    $sum update-golang.sh > $out
else
    echo >&2 "$0: missing $sum"
fi

echo $out
