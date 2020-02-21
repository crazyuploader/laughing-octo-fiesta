#!/bin/bash

git clone --depth=1 https://github.com/crazyuploader/InsigniuX.git -b q-4.4.214 InsigniuX && cd InsigniuX
git clone --depth=1 https://github.com/crazyuploader/AnyKernel3.git anykernel
git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 gcc
git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 gcc32
mkdir clang-r377782b && cd clang-r377782b && wget -nv https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master/clang-r377782b.tar.gz
tar -xf clang-r377782b.tar.gz
rm clang-r377782b.tar.gz
cd ..

PWD="$(pwd)"
NAME="$(basename "${PWD}")"
TIME="$(date +%d%m%y%H%M)"
export BRANCH="$(git rev-parse --abbrev-ref HEAD)"
export ZIPNAME="${NAME}_Kunnel-${TIME}.zip"
export KBUILD_BUILD_USER=Jungle
export KBUILD_BUILD_HOST=AMD
export KERNEL_VERSION=$(make kernelversion)
export KBUILD_COMPILER_STRING="Clang Version 10.0.4"
export ARCH=arm64 && export SUBARCH=arm64

START=$(date +"%s")
echo ""
echo "Compiling ${NAME} at version: ${KERNEL_VERSION}"
echo ""
make O=out ARCH=arm64 whyred_defconfig
make -j$(nproc --all) O=out ARCH=arm64 CC="$(pwd)/clang-r377782b/bin/clang" CLANG_TRIPLE="aarch64-linux-gnu-" CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-linux-android-" CROSS_COMPILE_ARM32="$(pwd)/gcc32/bin/arm-linux-androideabi-"
END=$(date +"%s")
DIFF=$((END - START))

if [ -f $(pwd)/out/arch/arm64/boot/Image.gz-dtb ]
	then
  	cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel
  	cd anykernel
  	zip -r9 ${ZIPNAME} *
  	echo "Build Finished in $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)."
else
    echo "Built with errors! Time Taken: $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)."
    exit 1
fi
