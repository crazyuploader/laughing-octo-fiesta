#!/bin/bash

git clone --depth=1 https://github.com/crazyuploader/kernel_xiaomi_whyred.git -b v4.4.186 Perf && cd Perf
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
export KERNEL_VERSION=$(make kernelversion)
export BRANCH="$(git rev-parse --abbrev-ref HEAD)"
export ZIPNAME="CR-${NAME}-${KERNEL_VERSION}_Kunnel.zip"
export KBUILD_BUILD_USER=Jungle
export KBUILD_BUILD_HOST=AMD
export KBUILD_COMPILER_STRING="Clang Version 10.0.4"
export ARCH=arm64 && export SUBARCH=arm64

curl -s -X POST https://api.telegram.org/bot${BOT_API_TOKEN}/sendMessage -d text="Cirrus CI Build -- ${NAME} at Version: ${KERNEL_VERSION}" -d chat_id=${KERNEL_CHAT_ID} -d parse_mode=HTML
START=$(date +"%s")
echo ""
echo "Compiling ${NAME} at version: ${KERNEL_VERSION}"
echo ""
make O=out ARCH=arm64 whyred-perf_defconfig
make -j$(nproc --all) O=out ARCH=arm64 CC="$(pwd)/clang-r377782b/bin/clang" CLANG_TRIPLE="aarch64-linux-gnu-" CROSS_COMPILE="$(pwd)/gcc/bin/aarch64-linux-android-" CROSS_COMPILE_ARM32="$(pwd)/gcc32/bin/arm-linux-androideabi-"
END=$(date +"%s")
DIFF=$((END - START))

if [ -f $(pwd)/out/arch/arm64/boot/Image.gz-dtb ]
	then
  	cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb $(pwd)/anykernel
  	cd anykernel
  	zip -r9 ${ZIPNAME} *
  	echo "Build Finished in $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)."
	curl -F chat_id="${KERNEL_CHAT_ID}" -F document=@"$(pwd)/${ZIPNAME}" https://api.telegram.org/bot${BOT_API_TOKEN}/sendDocument
else
  	curl -s -X POST https://api.telegram.org/bot${BOT_API_TOKEN}/sendMessage -d text="Cirrus CI: ${NAME} Build finished with errors... ${KERNEL_VERSION}" -d chat_id=${KERNEL_CHAT_ID} -d parse_mode=HTML
    echo "Built with errors! Time Taken: $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)."
    exit 1
fi
