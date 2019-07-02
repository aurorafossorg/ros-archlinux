#!/usr/bin/env bash
git submodule sync
git submodule update

if [ ! -d ./chroot/root ]; then
	cat /etc/pacman.conf > ./pacman.conf
	echo "[ros]
SigLevel = Optional TrustAll
Server = file://$(realpath ./repo)" >> ./pacman.conf

	mkdir -p ./chroot/
	mkarchroot -C contrib/pacman.conf ./chroot/root base-devel
fi

arch-nspawn ./chroot/root --bind-ro="$(realpath ./repo)" pacman -Syu

mkdir -p ./repo/

repo-add -q ./repo/ros.db.tar.xz


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
	
				date +%s > ../../repo/lastupdate
			done
		fi

		popd
	done
fi
