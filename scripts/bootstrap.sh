#!/bin/bash
git submodule update --init --recursive
tools/mint bootstrap --verbose
tools/mint run xcodegen
