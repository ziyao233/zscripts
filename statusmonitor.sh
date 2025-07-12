#!/bin/env bash

#	SPDX-License-Identifier: MPL-2.0
#	zscripts: statusmonitor.sh
#	A simple script for monitoring machine online status and synchronize
#	messages to Telegram chats.
#	Copyright (C) 2025 Yao Zi <ziyao@disroot.org>

die() {
	echo $@ 1>&2
	exit
}

send_message() {
	curl "https://api.telegram.org/bot${APIKEY}/sendMessage" \
		-d "chat_id=$CHATID" -d "text=$1"
}

go_online() {
	local name="$1"
	if ! grep -q "$name" "$ONLINELIST"; then
		echo "$name" >> "$ONLINELIST"
		send_message "$name is now online"
	fi

	sed -i -e "/$name/d" "$OFFLINELIST"
}

go_offline() {
	local name="$1"
	if ! grep -q "$name" "$OFFLINELIST"; then
		echo "$name" >> "$OFFLINELIST"
		send_message "$name is now offline"
	fi

	sed -i -e "/$name/d" "$ONLINELIST"
}

[ "$1" ] || die "Must be called with a configuration"

source "$1"

[ -f "$ONLINELIST" ] || touch "$ONLINELIST"
[ -f "$OFFLINELIST" ] || touch "$OFFLINELIST"

for pair in "${DEVICES[@]}"; do
	name="${pair%% *}"
	ip="${pair##* }"

	if ping -W 3 -c 1 "$ip"; then
		go_online "$name"
	else
		go_offline "$name"
	fi
done
