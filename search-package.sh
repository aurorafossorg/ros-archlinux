#!/usr/bin/env bash

REPOFY_DONE_DEPENDS=0
REPOFY_DEPENDS_TOTAL="$(yay -Ssq $(echo "$1" | tr -d '^$') | grep "$1")"

REPOFY_DEPENDS="$1"

while [ $REPOFY_DONE_DEPENDS == 0 ]; do
	REPOFY_PACKAGES=""
	for x in "$REPOFY_DEPENDS"; do
		REPOFY_PACKAGES+="$(yay -Si $(yay -Ssq $(echo "$x" | tr -d '^$') | grep "$x") | grep "Depends On" | cut -d: -f2 | tr -s ' ' '\n' | sort -u | grep -v "None") "
	done
	REPOFY_DEPENDS=""
	for x in $(echo $REPOFY_PACKAGES | tr -s ' ' '\n'); do
		x_tmp=$(echo ${x} | tr -s '>=<' ':' | cut -d":" -f1)
		if [ $(pacman -Ss "^${x_tmp}$" | wc -l) -eq 0 ]; then
			REPOFY_DEPENDS+="$x_tmp "
		fi
	done

	if [ "$REPOFY_DEPENDS" == "" ]; then
		REPOFY_DONE_DEPENDS=1
	fi

	REPOFY_DEPENDS_TOTAL+="$REPOFY_DEPENDS "
done

printf "$(echo $REPOFY_DEPENDS_TOTAL | tr -s ' ' '\n' | sort -u)"