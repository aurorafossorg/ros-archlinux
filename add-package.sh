#!/usr/bin/env bash

pushd ./packages
git submodule add --force ssh://aur@aur.archlinux.org/$1.git $1
popd