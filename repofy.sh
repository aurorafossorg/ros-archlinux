#!/usr/bin/env bash
git submodule sync
git submodule update

mkdir -p ./repo/

repo-add -q ./repo/ros.db.tar.xz
repo-add -q ./repo/ros-local.db.tar.xz

if [ ! -d ./chroot/root ]; then
	mkdir -p ./.tmp/
	cp contrib/pacman.conf .tmp/pacman.conf
	echo "[ros-local]
SigLevel = Optional TrustAll
Server = file://$(realpath ./repo)

[ros]
SigLevel = Optional TrustAll
Server = https://dl.aurorafoss.org/aurorafoss/pub/repo/ros-archlinux/" >> .tmp/pacman.conf

	mkdir -p ./chroot/
	mkarchroot -C .tmp/pacman.conf ./chroot/root base-devel
fi

arch-nspawn ./chroot/root --bind-ro="$(realpath ./repo)" pacman -Syu


REPOFY_FOLDERS=$(find ./packages/ -maxdepth 1 -mindepth 1 -type d)
REPOFY_PACKAGES=""
for x in $(find ./repo/ -maxdepth 1 -mindepth 1 -type f | grep '.pkg.tar.xz$'); do
	REPOFY_PACKAGES+="$(basename $x)\n"
done

if [ $(printf "$REPOFY_FOLDERS" | wc -l) -gt 0 ]; then
	for folder in $REPOFY_FOLDERS; do
		pushd $folder

		eval "$(cat ./PKGBUILD | sed -e 's/^[ \t]*//' | grep -E "^pkgname=|^pkgver=|^pkgrel=" | tr '\n' ';')"

		REPOFY_NEEDED="0"

		if [ "$1" != "-f" ]; then
			for name in $pkgname; do
				if [ ! $(printf "$REPOFY_PACKAGES" | grep "^${name}-${pkgver}-${pkgrel}-" | wc -l) -gt 0 ]; then
					REPOFY_NEEDED="1"
					break
				fi
			done
		fi

		if [[ "$1" == "-f" || "$REPOFY_NEEDED" == "1" ]]; then
			makechrootpkg -c -r ../../chroot -D "$(realpath ../../repo)" -u
	
			for package in $(find . -maxdepth 1 -mindepth 1 -type f | grep ".pkg.tar.xz$"); do
				mv $package ../../repo
				repo-add -q ../../repo/ros.db.tar.xz ../../repo/$package
				repo-add -q ../../repo/ros-local.db.tar.xz ../../repo/$package
	
				date +%s > ../../repo/lastupdate
			done
		fi

		popd
	done
fi
