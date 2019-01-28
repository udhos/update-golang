#!/bin/bash

shellcheck -e SC2153,SC2016 pre-commit sha256-update.sh update-golang.sh
