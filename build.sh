#!/bin/bash
#
# Thanks to Tkkg1994 and djb77 for the script
#
# MoRoKernel Build Script v1.2
#
# For
#
# Ultimate-Kernel
#

# SETUP
# -----
export ARCH=arm64
export SUBARCH=arm64
export BUILD_CROSS_COMPILE=$HOME/project/android/aarch64-linux-android-4.9/bin/aarch64-linux-android-
export CROSS_COMPILE=$BUILD_CROSS_COMPILE
export BUILD_JOB_NUMBER=`grep processor /proc/cpuinfo|wc -l`
export USE_CCACHE=1

export PLATFORM_VERSION=7.0

RDIR=$(pwd)
OUTDIR=$RDIR/arch/$ARCH/boot
DTSDIR=$RDIR/arch/$ARCH/boot/dts
DTBDIR=$OUTDIR/dtb
DTCTOOL=$RDIR/scripts/dtc/dtc
INCDIR=$RDIR/include
PAGE_SIZE=2048
DTB_PADDING=0

DEFCONFIG=G92X_defconfig

export K_NAME="Zenith-Kernel"
S6DEVICE="Nougat"
LOG=build.log


# FUNCTIONS
# ---------
FUNC_CLEAN_DTB()
{
	if ! [ -d $RDIR/arch/$ARCH/boot/dts ] ; then
		echo "no directory : "$RDIR/arch/$ARCH/boot/dts""
	else
		echo "rm files in : "$RDIR/arch/$ARCH/boot/dts/*.dtb""
		rm $RDIR/arch/$ARCH/boot/dts/*.dtb
		rm $RDIR/arch/$ARCH/boot/dtb/*.dtb
		rm $RDIR/arch/$ARCH/boot/dtb.img
		rm $RDIR/arch/$ARCH/boot/Image
		rm -rf $RDIR/build/ak3/Image
		rm -rf $RDIR/build/ak3/dtb.img
	fi
}

FUNC_BUILD_KERNEL()
{
	echo ""
        echo "build common config="$KERNEL_DEFCONFIG ""
        echo "build variant config="$MODEL ""

	cp -f $RDIR/arch/$ARCH/configs/$DEFCONFIG $RDIR/arch/$ARCH/configs/tmp_defconfig

	#FUNC_CLEAN_DTB

	make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			CROSS_COMPILE=$BUILD_CROSS_COMPILE \
			tmp_defconfig || exit -1
	make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			CROSS_COMPILE=$BUILD_CROSS_COMPILE || exit -1
	echo ""

	rm -f $RDIR/arch/$ARCH/configs/tmp_defconfig
}

FUNC_BUILD_DTB()
{
	[ -f "$DTCTOOL" ] || {
		echo "You need to run ./build.sh first!"
		exit 1
	}

	mkdir -p $OUTDIR $DTBDIR
	cd $DTBDIR || {
		echo "Unable to cd to $DTBDIR!"
		exit 1
	}
	rm -f ./*
	echo "=> Processing: G92X_universal.dts"
	${CROSS_COMPILE}cpp -nostdinc -undef -x assembler-with-cpp -I "$INCDIR" "$DTSDIR/G92X_universal.dts" > "G92X_universal.dts"
	echo "=> Generating: G92X_universal.dtb"
	$DTCTOOL -p $DTB_PADDING -i "$DTSDIR" -O dtb -o "G92X_universal.dtb" "G92X_universal.dts"
	echo "Generating dtb.img."
	$RDIR/scripts/dtbtool_exynos/dtbtool -o "$OUTDIR/dtb.img" -d "$DTBDIR/" -s $PAGE_SIZE
	echo "Done."
}

FUNC_CP_AK3()
{
	echo ""
	echo "Copying kernel and dtb image to AnyKernel3 Folder"
	mv $RDIR/arch/$ARCH/boot/Image $RDIR/build/ak3/Image
	mv $RDIR/arch/$ARCH/boot/dtb.img $RDIR/build/ak3/dt.img
}

FUNC_BUILD_FLASHABLES()
{
	cd $RDIR/build/ak3
	echo ""
	echo "Creating flashables..."
	zip -r9 ../$ZIP_NAME * -x README.md ../$ZIP_NAME
}

CLEAN()
{
	# Clean Build Data
	make clean
	make ARCH=arm64 distclean
	rm -rf $RDIR/build/ak3/Image
	rm -rf $RDIR/build/ak3/dt.img

	# Remove Release files
	rm -f $PWD/arch/arm64/configs/tmp_defconfig

	# Removed Created dtb Folder
	rm -rf $PWD/arch/arm64/boot/dtb
}



# MAIN PROGRAM
# ------------

MAIN()
{

(
	START_TIME=`date +%s`
	FUNC_BUILD_KERNEL
	FUNC_BUILD_DTB
	FUNC_CP_AK3
	FUNC_BUILD_FLASHABLES
	END_TIME=`date +%s`
	let "ELAPSED_TIME=$END_TIME-$START_TIME"
	echo "Total compile time is $ELAPSED_TIME seconds"
	echo ""
) 2>&1 | tee -a ./$LOG

	echo "Your flasheable release can be found in the build folder"
	echo ""
}


# PROGRAM START
# -------------
clear
echo "**********************************"
echo "Zenith-Kernel Build Script"
echo "**********************************"
echo ""
echo ""
echo "Build Kernel for:"
echo ""
echo "(1) G92X Nougat"
echo "(2) CLEAN"
echo ""
echo ""
read -p "Select an option to compile the kernel " prompt


if [ $prompt == "1" ]; then
    MODEL=G920
    DEVICE=$S6DEVICE
    KERNEL_DEFCONFIG=$DEFCONFIG_S6FLAT
    echo "S6 Flat G920F Selected"
    ZIP_NAME="${K_NAME}-${MODEL}-N-$(date +%Y-%m-%d).zip"
    MAIN
elif [ $prompt == "2" ]; then
    echo "Cleaning source directory..."
    CLEAN
fi
