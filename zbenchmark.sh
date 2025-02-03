#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Simple script for benchmarking

programName="$0"
warmup=3
runs=3

print_help() {
	echo "$programName: Benchmark a program"
	echo "USAGE:"
	echo "	$programName [--warmup N] [--runs N] <test_program> [args ...]"
}

take_time() {
	echo "$2"
}

timeReal=()
timeUser=()
timeSys=()

timed_run() {
	tmp="$(mktemp)"
	args=($@)
	sh -c "time -p ${args[*]}" 2>"$tmp"
	while read line; do
		value=$(take_time $line)
		case "$line" in
		real*)
			timeReal+=("$value") ;;
		user*)
			timeUser+=("$value") ;;
		sys*)
			timeSys+=("$value") ;;
		*)
		esac
	done < "$tmp"
	rm "$tmp"
}

calc() {
	bc <<-EOF
	scale=5
	$1
	EOF
}

calc_mean() {
	sum=0
	for v in "$@"; do
		sum=$(calc "$sum + $v")
	done
	calc "$sum / $#"
}

calc_variance() {
	mean=$1
	shift
	variance=0
	for v in "$@"; do
		variance=$(calc "$variance + ($v - $mean)^2")
	done
	calc "$variance / $#"
}

while true; do
	case "$1" in
	--warmup)
		shift
		warmup="$1"
		shift ;;
	--runs)
		shift
		runs="$1"
		shift ;;
	--help)
		print_help
		exit ;;
	*)
		break;
	esac
done

if ! [ "$1" ]; then
	exec 2>&1
	echo "missing test_program"
	print_help
	exit 1
fi

if [ "$runs" = 0 ]; then
	exec 2>&1
	echo "Argument of --runs cannot be 0"
	print_help
	exit 1
fi

for i in $(seq 1 "$warmup"); do
	"$@"
done

for i in $(seq 1 "$runs"); do
	timed_run "$@"
done

echo "=================== DONE =========================="
meanReal=$(calc_mean "${timeReal[@]}")
meanSys=$(calc_mean "${timeSys[@]}")
meanUser=$(calc_mean "${timeUser[@]}")
varReal=$(calc_variance "$meanReal" "${timeReal[@]}")
varSys=$(calc_variance "$meanSys" "${timeSys[@]}")
varUser=$(calc_variance "$meanUser" "${timeUser[@]}")

echo "Mean Real Time:	$meanReal	(variance $varReal)"
echo "Mean System Time: $meanSys	(variance $varSys)"
echo "Mean User Time:	$meanUser	(variance $varUser)"
