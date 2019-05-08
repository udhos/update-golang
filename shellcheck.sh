#!/usr/bin/env bash

shellcheck -e SC2153,SC2016 shellcheck.sh pre-commit sha256-update.sh update-golang.sh
