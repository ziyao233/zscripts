#!/usr/bin/env sh
# SPDX-License-Identifier: MPL-2.0
# Copyright (c) 2025 Yao Zi.
# Recursively find tags file and call readtags

cpath="$PWD"
while ! [ "$(realpath "$cpath")" = '/' ]; do
	if test -f "$cpath/tags"; then
		readtags -t "$cpath/tags" "$@"
		exit
	fi

	cpath="$cpath/../"
done

echo 'Iteration reaches "/" but no tags file found' >&2
exit 1
