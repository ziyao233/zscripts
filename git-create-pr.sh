#!/bin/bash
# SPDX-License-Identifier: MPL-2.0

# 	zscripts: git-create-pr - Print a link to Create GitHub Pull Request
#	Copyright (c) 2024 Yao Zi.

warn() {
	echo "$1" >&2
}

die() {
	warn "$1"
	exit 1
}

doInfo=y

info() {
	[ "$doInfo" = y ] && echo "$@"
}

checkGitHub() {
	echo "$1" | grep -q 'github.com/' ||
		die "$url is not a GitHub HTTPS repository"
}


branchNow="$(git branch --show-current)" ||
	die "Cannot determine current git branch"

# disable information if we are not printing to a tty
tty 0<&1 1>/dev/null 2>/dev/null || doInfo=n

usage() {
	echo "git-create-pr.sh - zscripts"
	echo
	echo "A script to create GitHub Pull Requests quickly"
	echo
	echo "	-r: Specify original remote"
	echo "	-d: Specify development remote"
	echo "	-o: OPEN FIREFOX IN PLACE"
}

while [ "$1" ]; do
	case "$1" in
	-r)	# original remote
		shift
		[ "$1" ] || die "Option '-r' needs an argument"
		remote="$1" ;;
	-d)	# development remote
		shift
		[ "$1" ] || die "Option '-d' needs an argument"
		devremote="$1" ;;
	-o)	# OPEN FIREFOX, I MEAN NOW!
		openFirefox=y ;;
	-h)
		usage
		exit 0 ;;
	*)
		usage
		exit 1 ;;
	esac
	shift
done

# just do guessing
if ! [ "$remote" ]; then
	if git remote get-url origin 2>/dev/null 1>/dev/null; then
		# we just use it
		remote=origin
	else
		warn "Original remote not specified and 'origin' does not exist"
		die "Use '-r ORIGIN' explicitly'"
	fi
fi
info "Original Remote: $remote"
remoteURL="$(git remote get-url "$remote")" ||
	die "Cannot get URL for remote '$remote'"
checkGitHub "$remoteURL"

# more guessing
if ! [ "$devremote" ]; then
	if git remote get-url mydev 2>/dev/null 1>/dev/null; then
		devremote=mydev
	else
		warn "Development remote not specified and 'mydev' does not exist"
		die "Use '-d DEV' explicitly"
	fi
fi
info "Development Remote: $devremote"
devremoteURL="$(git remote get-url "$devremote")" ||
	die "Cannot get URL for remote '$devremote'"
checkGitHub "$devremoteURL"

info "From: $branchNow"
info "To: $branchNow"

remoteURL="$(echo "$remoteURL" | sed -e 's/https:\/\///' | sed -e 's/\.git//')"
srcUser="$(basename "$(dirname "$devremoteURL")")"
srcRepo="$(basename "$devremoteURL" | sed -e 's/\.git//')"
src="${srcUser}:${srcRepo}:${branchNow}"
url="https://${remoteURL}/compare/${branchNow}...${src}/?expand=1"
if [ "$openFirefox" = y ]; then
	firefox "$url"
else
	echo "$url"
fi
