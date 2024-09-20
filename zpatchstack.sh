#!/bin/sh
# SPDX-License-Identifier: MPL-2.0
# A bash script to patch PT_GNU_STACK entry, to avoid stack overflow with musl

# The logic is simple, find the program header, search for PT_GNU_STACK entry,
# if succeeds, rewriten it.

progname="$(basename "$0")"

warn() {
	echo "$progname: $*" 2>&1
}

die() {
	warn "$@"
	exit 1
}

inputFile="$1"
targetSize="$2"
outputFile="${3:-$1}"

[ "$inputFile" ] || die "No input file speicifed"
[ "$targetSize" ] || die "No target PT_GNU_STACK size specified"
[ -f "$inputFile" ] || die "$inputFile: No such file or directory"
case "$targetSize" in
	*[!0-9]*)  die "Invalid target size: $targetSize" ;;
	*) ;;
esac

# $1: start position
# $2: bytes
# $3: format
readn() {
	_f="${3:-d}"
	od -j "$1" -N "$2" -An -v -t"$_f$2" "$inputFile" | sed 's/[[:space:]]//g'
}

calc() {
	bc <<-EOF
	$1
	EOF
}

# $1: data as string
# $2: bytes
to_binary_le() {
	_d="$1"
	_i=0
	while [ "$_i" -lt "$2" ]; do
		# shellcheck disable=SC2059
		printf "\x$(calc "obase=16; $_d % 256")"
		_d="$(calc "$_d / 256")"
		_i="$((_i + 1))"
	done
}

# $1: offset
writen() {
	dd of="$outputFile" oflag=direct conv=notrunc bs=1 seek="$1" status=none
}

head -n 4 "$inputFile" | grep -q "\x7fELF" || die "$1 is not an ELF file"

# typedef struct {
#	unsigned char e_ident[EI_NIDENT];	// 0
#		// EI_CLASS = 4
# 	uint16_t      e_type;			// 16
#	uint16_t      e_machine;		// 18
#	uint32_t      e_version;		// 20
#	ElfN_Addr     e_entry;			// 24
#	ElfN_Off      e_phoff;			// 32
#	ElfN_Off      e_shoff;			// 40
#	uint32_t      e_flags;			// 48
#	uint16_t      e_ehsize;			// 52
#	uint16_t      e_phentsize;		// 54
#	uint16_t      e_phnum;			// 56
#	uint16_t      e_shentsize;		// 58
#	uint16_t      e_shnum;			// 60
#	uint16_t      e_shstrndx;		// 62
# } ElfN_Ehdr;
# sizeof(Elf64_Ehdr) = 64 bytes

# ELFCLASS64: 2
[ "$(readn 4 1)" = 2 ] ||
	die "Only EI_CLASS = ELFCLASS64 (2) is supported"

phOff="$(readn 32 8)"
[ "$(readn 54 2)" = 56 ] ||
	die "Only e_phentsize = 56 is supported"
phNum="$(readn 56 2)"

# typedef struct {
#	uint32_t   p_type;		// 0
#	uint32_t   p_flags;		// 4
#	Elf64_Off  p_offset;		// 8
#	Elf64_Addr p_vaddr;		// 16
#	Elf64_Addr p_paddr;		// 24
#	uint64_t   p_filesz;		// 32
#	uint64_t   p_memsz;		// 40
#	uint64_t   p_align;		// 48
# } Elf64_Phdr;

gnuStk=0
while [ "$gnuStk" -lt "$phNum" ]; do
	off="$(calc "$phOff + 56 * $gnuStk + 0")"
	# PT_GNU_STACK = 1685382481
	[ "$(readn "$off" 4)" = 1685382481 ] && break
	gnuStk="$((gnuStk + 1))"
done

[ "$gnuStk" = "$phNum" ] && die "No PT_GNU_STACK entry found"

off="$(calc "$off + 40")"
[ "$inputFile" = "$outputFile" ] || cp -f "$inputFile" "$outputFile"
to_binary_le "$targetSize" 8 | writen "$off"
