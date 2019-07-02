#!/usr/bin/env bash

for packages in $(find ./packages/ -maxdepth 1 -mindepth 1 -type d); do
	pushd $packages
	git clean -fxd
	popd
done