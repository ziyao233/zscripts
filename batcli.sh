#!/bin/bash
# SPDX-License-Identifier: MPL-2.0

#	zscripts: batcli - Battery tool
#	Copyright (c) 2024 Yao Zi.`

die() {
	echo "$1" >&2
	exit 1
}

warn() {
	echo "$1" >&2
}

batlist=()
for bat in /sys/class/power_supply/BAT*;
do
	batlist+=("$bat")
done

get_prop() {
	local bat=$1
	local prop=$2

	if [ -f "$bat/$prop" ]; then
		cat "$bat/$prop"
	else
		echo "(Not exist)"
	fi
}

do_info() {
	for bat in "${batlist[@]}"; do
		printf "BATTERY %s:\n" "$bat"
		for prop in "$@"; do
			echo $(get_prop "$bat" "$prop")
		done
	done
}

calc_percentage() {
	local num="$1"
	local deno="$2"

	local tmp="$((num * 1000 / deno))"
	echo "$((tmp / 10)).$((tmp % 10))%"
}

do_interesting_info() {
	local interested=('Status\t/status' 'Voltage\t/voltage_now'
			  'FullEnergy/energy_full' 'EnergyNow/energy_now'
			  'DesignedEnergy/energy_full_design')
	for bat in "${batlist[@]}"; do
		printf "BATTERY %s:\n" "$bat"
		for item in "${interested[@]}"; do
			local prop=$(basename "$item")
			local prettyProp=$(dirname "$item")
			printf "$prettyProp\t: %s\n" "$(get_prop "$bat" "$prop")"
		done
	done
}

do_percentage() {
	for bat in "${batlist[@]}"; do
		local now=$(get_prop "$bat" "energy_now")
		local full=$(get_prop "$bat" "energy_full")
		echo "$(calc_percentage $now $full)"
	done
}

#####################################################################
# The main program
#####################################################################

opt=$1
[ "$opt" ] || opt="list"
shift

case "$opt" in
list)
	for bat in "${bat[@]}"; do
		# shellcheck disable=SC2086
		echo "$bat"
	done ;;
info)
	if [ "$@" ]; then
		do_info "$@"
	else
		do_interesting_info
	fi ;;
percentage)
	do_percentage ;;
*)
	die "Unknown operation '$opt'" ;;
esac
