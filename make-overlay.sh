#! /bin/bash -e

CORE="$1"
SRC="$2"
DST="$3"

show_help()
{
	cat <<EOF
Usage: $0 <core-name> <source-configuration-overlay> <result-directory>

	core-name			the name of the Xtensa core as used in
       					Linux or U-Boot

	source-configuration-overlay	configuration overlay from the Xtensa
					core build. It is located in the
					<release>/<core-name>/src/xtensa-config-overlay.tar.gz

	result-directory		directory where the repackaged overlay
					xtensa_<core-name>.tar.gz will be saved.

EOF
	exit 1
}

split_binutils()
{
	A="$DIR"/binutils
	B="$DIR"/res/binutils

	mkdir -p "$B"/{bfd,include}
	cp "$A"/xtensa-modules.c "$B"/bfd
	cp "$A"/xtensa-config.h "$B"/include
}

split_gcc()
{
	A="$DIR"/gcc
	B="$DIR"/res/gcc

	mkdir -p "$B"/include
	cp "$A"/xtensa-config.h "$B"/include
}

split_gdb()
{
	A="$DIR"/gdb
	B="$DIR"/res/gdb

	mkdir -p "$B"/{bfd,gdb/{gdbserver,regformats},include}
	cp "$A"/xtensa-modules.c "$B"/bfd
	cp "$A"/xtensa-config.h "$B"/include
	cp "$A"/xtensa-config.c "$B"/gdb
	sed -e '0,/#include/s/#include/#include "defs.h"\n#include/' -i "$B"/gdb/xtensa-config.c
	cp "$A"/xtensa-xtregs.c "$B"/gdb
	cp "$A"/xtensa-xtregs.c "$B"/gdb/gdbserver
	cp "$A"/xtensa-regmap.c "$B"/gdb/gdbserver
	cp "$A"/reg-xtensa.dat "$B"/gdb/regformats
}

split_newlib()
{
	A="$DIR"/config
	B="$DIR"/res/newlib

	mkdir -p "$B"/newlib/libc/sys/xtensa/include/xtensa/config
	cp "$A"/core.h "$B"/newlib/libc/sys/xtensa/include/xtensa/config/core-isa.h
}

split_linux()
{
	A="$DIR"/config
	B="$DIR"/res/linux

	mkdir -p "$B"/arch/xtensa/variants/$CORE/include/variant
	cp "$A"/{core.h,tie.h,tie-asm.h} "$B"/arch/xtensa/variants/$CORE/include/variant
}

split_uboot()
{
	A="$DIR"/config
	B="$DIR"/res/u-boot

	mkdir -p "$B"/arch/xtensa/include/asm/arch-$CORE
	cp "$A"/{core.h,tie.h,tie-asm.h} "$B"/arch/xtensa/include/asm/arch-$CORE
}

combine_overlay()
{
	B="$DIR"/res
	tar -czf "$DST"/xtensa_${CORE}.tar.gz -C "$B" {binutils,gcc,gdb,newlib,linux,u-boot}
}

[ $# -eq 3 ] || show_help

DIR=`mktemp -d`
trap 'rm -rf "$DIR"' EXIT
tar -xf "$SRC" -C "$DIR"

split_binutils "$@"
split_gcc "$@"
split_gdb "$@"
split_newlib "$@"
split_linux "$@"
split_uboot "$@"
combine_overlay "$@"
