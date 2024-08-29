#!/bin/sh

target="$1"

if ! [ -d "$1" ]; then
	echo "$1 is not a directory" 1>&2
	exit 1
fi

for s in *.sh; do
	if ! [ "$s" = "install.sh" ]; then
		cp "$s" "$target/$(echo $s | sed -e 's/\.sh//')"
	fi
done
