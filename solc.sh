#!/bin/bash
# Use solc with a small twist: assigned zeppelin directories

set -e

solc "@openzeppelin="$(pwd)"/node_modules/@openzeppelin" "$@"
