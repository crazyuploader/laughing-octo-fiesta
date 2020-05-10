#!/usr/bin/env bash

# Created by Jugal Kishore -- 2020
# Kernel Automated Script

function SET_ENVIRONMENT() {
    cd "${TOOLCHAIN}" || { echo "Failure!"; exit 1; }
    cd clang || { echo "Failure!"; exit 1; }
    CLANG_DIR="$(pwd)"
    CC="${CLANG_DIR}/bin/clang"
    CLANG_VERSION="$(./bin/clang --version | grep 'clang version' | cut -c 37-)"
    cd ..
    git clone --depth=1 https://github.com/crazyuploader/AnyKernel3.git anykernel
}

# Variables Check
echo ""
if [[ -z ${TOOLCHAIN} ]]; then
    echo "Don't know where to get compilers from"
    exit 1
fi

if [[ -z "${KERNEL_REPO_URL}" ]]; then
    echo "'KERNEL_REPO_URL' variable not found, please set it first."
    exit 1
fi

if [[ -z "${DEF_CONFIG}" ]]; then
    echo "'DEF_CONFIG' variable not found, please set it first."
    exit 1
fi

if [[ -z "${KERNEL_NAME}" ]]; then
    echo "'KERNEL_NAME' variable not found, using default 'Kernel'"
    KERNEL_NAME="Daath"
fi

# Set Up Environment
SET_ENVIRONMENT

echo ""
git clone --depth=1 "${KERNEL_REPO_URL}" "${KERNEL_NAME}"
cd "${KERNEL_NAME}" || exit

# Variables
PWD="$(pwd)"
NAME="$(basename "${PWD}")"
TIME="$(date +%d%m%y%H%M)"
KERNEL_VERSION="$(make kernelversion)"

# Exporting Few Stuff
export ZIPNAME="${KERNEL_NAME}-${TIME}.zip"
export KERNEL_VERSION="${KERNEL_VERSION}"
export ANYKERNEL_DIR="${TOOLCHAIN}/anykernel"
export GCC_DIR="${TOOLCHAIN}/gcc/bin/aarch64-linux-android-"
export GCC32_DIR="${TOOLCHAIN}/gcc32/bin/arm-linux-androideabi-"
export KBUILD_BUILD_USER="crazyuploader"
export KBUILD_BUILD_HOST="github.com"
export CC="${CC}"
export KBUILD_COMPILER_STRING="${CLANG_VERSION}"
export ARCH="arm64"
export SUBARCH="arm64"

# Telegram Message
echo ""
curl -s -X POST https://api.telegram.org/bot"${BOT_API_TOKEN}"/sendMessage \
        -d text="CI Build -- ${NAME} at Version: ${KERNEL_VERSION}"         \
        -d chat_id="${KERNEL_CHAT_ID}"                                       \
        -d parse_mode=HTML
START="$(date +"%s")"
echo ""
echo "Compiling ${NAME} at version: ${KERNEL_VERSION} with Clang Version: ${CLANG_VERSION}"

# Compilation
echo ""
make O=out ARCH=arm64 "${DEF_CONFIG}"
make -j"$(nproc --all)"                                                     \
        O=out ARCH=arm64                                                     \
        CC="${CC}"                                                            \
        CLANG_TRIPLE="aarch64-linux-gnu-"                                      \
        CROSS_COMPILE="${GCC_DIR}"                                              \
        CROSS_COMPILE_ARM32="${GCC32_DIR}"

# Time Difference
END="$(date +"%s")"
DIFF="$((END - START))"

# Zipping
echo ""
if [[ -f "$(pwd)/out/arch/arm64/boot/Image.gz-dtb" ]]; then
  	cp "$(pwd)/out/arch/arm64/boot/Image.gz-dtb" "${ANYKERNEL_DIR}"
  	cd "${ANYKERNEL_DIR}" || exit
  	zip -r9 "${ZIPNAME}" ./*
  	echo "Build Finished in $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)."
	curl -F chat_id="${KERNEL_CHAT_ID}" \
         -F document=@"$(pwd)/${ZIPNAME}" \
         https://api.telegram.org/bot"${BOT_API_TOKEN}"/sendDocument
else
  	curl -s -X POST https://api.telegram.org/bot"${BOT_API_TOKEN}"/sendMessage \
            -d text="${NAME} Build finished with errors..."                     \
            -d chat_id="${KERNEL_CHAT_ID}"                                       \
            -d parse_mode=HTML
    echo "Built with errors! Time Taken: $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)."
    exit 1
fi
