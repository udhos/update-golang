#!/usr/bin/env sh

out=update-golang.sh.sha256

sha256sum update-golang.sh > $out

echo $out
