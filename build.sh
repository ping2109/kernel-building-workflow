#!/bin/bash
# shellcheck disable=SC2154
#Kernel building script

# Function to show an informational message
msg() {
	echo
    echo -e "\e[1;32m$*\e[0m"
    echo
}

err() {
    echo -e "\e[1;41m$*\e[0m"
}

cdir() {
	cd "$1" 2>/dev/null || \
		err "The directory $1 doesn't exists !"
}

installDependencies(){	
sudo rm -rf /usr/share/dotnet /etc/mysql /etc/php /etc/apt/sources.list.d
sudo -E apt-get -y purge azure-cli ghc* zulu* hhvm llvm* firefox google* dotnet* powershell openjdk* mysql* php*
sudo -E apt-get update
sudo -E apt-get -y autoremove --purge
sudo -E apt-get clean 
sudo apt -y update 
sudo apt -y install git automake lzop bison gperf build-essential zip \
 curl zlib1g-dev g++-multilib libxml2-utils bzip2 libbz2-dev libbz2-1.0 \
 libghc-bzlib-dev squashfs-tools pngcrush schedtool dpkg-dev liblz4-tool make \
 optipng bc libstdc++6 libncurses5 wget python3 python3-pip python gcc clang  \
 libssl-dev rsync flex git-lfs libz3-dev libz3-4 axel tar gcc llvm lld g++-multilib clang default-jre libxml2 ccache \
 git-core gnupg flex bison build-essential zip curl zlib1g-dev gcc-multilib libc6-dev-i386 lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z1-dev libgl1-mesa-dev libxml2-utils xsltproc unzip xz-utils fontconfig git automake lzop bison gperf build-essential zip curl zlib1g-dev g++-multilib libxml2-utils bzip2 libbz2-dev libbz2-1.0 libghc-bzlib-dev squashfs-tools pngcrush schedtool dpkg-dev liblz4-tool make optipng bc libstdc++6 libncurses5 wget python3 python3-pip python gcc clang libssl-dev rsync flex git-lfs libz3-dev libz3-4 axel tar gcc llvm lld g++-multilib default-jre libxml2

}

installDependencies

## clone Kernel
echo "Cloning Kernel"
git clone https://github.com/ping2109/NevaKernel-7870 -b pure10 kernel

##------------------------------------------------------##
##----------Basic Informations, COMPULSORY--------------##

# The defult directory where the kernel should be placed
KERNEL_DIR=$(pwd)/kernel
cd $KERNEL_DIR

# The name of the device for which the kernel is built
MODEL="Galaxy J7 2016"

# The codename of the device
DEVICE="j7xelte"

# The defconfig which should be used. Get it from config.gz from
# your device or check source
DEFCONFIG=exynos7870-j7xelte_defconfig

#Kernel version
KERN_VER="3.0"

EXTRA_NOTE="love you from the ceiling to the toilet"

# Show manufacturer info
MANUFACTURERINFO="Doofenshmirtz Evil Inc."

#TG Post description and notes
POST_DESC="Initial build"

#TG Post credits
CREDITS="@Astrako, @ping2109official"

# Kernel Variant
VARIANT=j7xelte

# Build Type
BUILD_TYPE="Nightly"

# Specify compiler.
# 'clang' or 'clangxgcc' or 'gcc'
COMPILER=gcc

# Kernel is LTO
LTO=0

# Specify linker.
# 'ld.lld'(default)
LINKER=ld.lld

# Clean source prior building. 1 is NO(default) | 0 is YES
INCREMENTAL=0

TELEGRAM_CHATID=1770565427

TOKEN=$TELEGRAM_TOKEN

# Push ZIP to Telegram. 1 is YES | 0 is NO(default)
PTTG=1
	if [ $PTTG = 1 ]
	then
		# Set Telegram Chat ID
		CHATID=$TELEGRAM_CHATID
	fi

# Generate a full DEFCONFIG prior building. 1 is YES | 0 is NO(default)
DEF_REG=0

# Files/artifacts
FILES=Image.gz-dtb

# Build dtbo.img (select this only if your source has support to building dtbo.img)
# 1 is YES | 0 is NO(default)
BUILD_DTBO=0

# Sign the zipfile
# 1 is YES | 0 is NO
SIGN=0
	if [ $SIGN = 1 ]
	then
		#Check for java
		if command -v java > /dev/null 2>&1; then
			SIGN=1
		else
			SIGN=0
		fi
	fi

# Silence the compilation
# 1 is YES(default) | 0 is NO
SILENCE=0

# Debug purpose. Send logs on every successfull builds
# 1 is YES | 0 is NO(default)
LOG_DEBUG=0

##------------------------------------------------------##
##---------Do Not Touch Anything Beyond This------------##

#Check Kernel Version
LINUXVER=$(make kernelversion)

# Set a commit head
COMMIT_HEAD=$(git log --oneline -1)

# Set Date
DATE=$(TZ=Asia/HoChiMinh date +"%Y-%m-%d")

#Now Its time for other stuffs like cloning, exporting, etc

 clone() {
	echo " "
	if [ $COMPILER = "clang" ]
	then
		msg "|| Cloning toolchain ||"
		git clone --depth=1 https://github.com/kdrag0n/proton-clang -b master $KERNEL_DIR/clang

	elif [ $COMPILER = "gcc" ]
	then
		msg "|| Cloning GCC 10.3 ||"
		git clone https://github.com/ping2109/aarch64-none-linux-gnu-compiler.git $KERNEL_DIR/gcc64 --depth=1

	elif [ $COMPILER = "clangxgcc" ]
	then
		msg "|| Cloning toolchain ||"
		git clone --depth=1 https://github.com/kdrag0n/proton-clang -b master $KERNEL_DIR/clang

		msg "|| Cloning GCC 10.3 ||"
		git clone https://github.com/ping2109/aarch64-none-linux-gnu-compiler.git $KERNEL_DIR/gcc64 --depth=1
	fi

	# Toolchain Directory defaults to clang-llvm
		TC_DIR=$KERNEL_DIR/clang

	# GCC Directory
		GCC64_DIR=$KERNEL_DIR/gcc64
		GCC32_DIR=$KERNEL_DIR/gcc32

	# AnyKernel Directory
		AK_DIR=$KERNEL_DIR/Anykernel3

	    msg "|| Cloning Anykernel ||"
        git clone https://github.com/ping2109/AnyKernel3.git -b 7870 $KERNEL_DIR/Anykernel3

	if [ $BUILD_DTBO = 1 ]
	then
		msg "|| Cloning libufdt ||"
		git clone https://android.googlesource.com/platform/system/libufdt $KERNEL_DIR/scripts/ufdt/libufdt
	fi
}

##----------------------------------------------------------##

# Function to replace defconfig versioning
setversioning() {
    # For staging branch
    KERNELNAME="NevaKernel-$KERN_VER-$DEVICE-$(TZ=Asia/HoChiMinh date +"%Y-%m-%d-%s")"
    # Export our new localversion and zipnames
    export KERNELNAME
    export ZIPNAME="$KERNELNAME.zip"
}

##--------------------------------------------------------------##

exports() {
	export KBUILD_BUILD_USER="ping2109"
	export KBUILD_BUILD_HOST="pings-FreeFire-GamingPC"
	# export KBUILD_USERNAME="ping2109"
	# export KBUILD_HOST="pings-FreeFire-GamingPC"
	export ARCH=arm64
	# export SUBARCH=arm64
	export ANDROID_MAJOR_VERSION=q
	export ANDROID_PLATFORM_VERSION=10

	if [ $COMPILER = "clang" ]
	then
		KBUILD_COMPILER_STRING=$("$TC_DIR"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
		PATH=$TC_DIR/bin/:$PATH
	elif [ $COMPILER = "clangxgcc" ]
	then
		KBUILD_COMPILER_STRING=$("$TC_DIR"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
		PATH=$TC_DIR/bin:$GCC64_DIR/bin:/usr/bin:$PATH
	elif [ $COMPILER = "gcc" ]
	then
		KBUILD_COMPILER_STRING=$("$GCC64_DIR"/bin/aarch64-none-linux-gnu-gcc --version | head -n 1)
		PATH=$GCC64_DIR/bin/:/usr/bin:$PATH
	fi

	if [ $LTO = "1" ];then
		export LD=ld.lld
        export LD_LIBRARY_PATH=$TC_DIR/lib
	fi

	export PATH KBUILD_COMPILER_STRING
	PROCS=$(nproc)
	export PROCS

	BOT_MSG_URL="https://api.telegram.org/bot$TOKEN/sendMessage"
	BOT_BUILD_URL="https://api.telegram.org/bot$TOKEN/sendDocument"
	PROCS=$(nproc)

	if [ $COMPILER = "gcc" ];then

    if [ -e $GCC64_DIR/bin/aarch64-none-linux-gnu-gcc ];then
        gcc64Type="$($GCC64_DIR/bin/aarch64-none-linux-gnu-gcc --version | head -n 1)"
    else
        cd $GCC64_DIR
        gcc64Type=$(git log --pretty=format:'%h: %s' -n1)
        cd $KERNEL_DIR
    fi
   fi


	export KBUILD_BUILD_USER ARCH SUBARCH PATH \
		KBUILD_COMPILER_STRING BOT_MSG_URL \
		BOT_BUILD_URL PROCS TOKEN
}

##---------------------------------------------------------##

tg_post_msg() {
	curl -s -X POST "$BOT_MSG_URL" -d chat_id="$CHATID" \
	-d "disable_web_page_preview=true" \
	-d "parse_mode=html" \
	-d text="$1"

}

##---------------------------------------------------------##

tg_post_build() {
	#Post MD5Checksum alongwith for easeness
	MD5CHECK=$(md5sum "$1" | cut -d' ' -f1)

	#Show the Checksum alongwith caption
	curl --progress-bar -F document=@"$1" "$BOT_BUILD_URL" \
	-F chat_id="$CHATID"  \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$2 | <b>MD5 Checksum : </b><code>$MD5CHECK</code>"
}

##----------------------------------------------------------##

tg_send_sticker() {
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendSticker" \
        -d sticker="$1" \
        -d chat_id="$CHATID"
}

##----------------------------------------------------------------##

tg_send_files(){
    KernelFiles="$(pwd)/$KERNELNAME.zip"
	MD5CHECK=$(md5sum "$KernelFiles" | cut -d' ' -f1)
	SID="CAACAgUAAxkBAAIlv2DEzB-BSFWNyXkkz1NNNOp_pm2nAAIaAgACXGo4VcNVF3RY1YS8HwQ"
	STICK="CAACAgUAAxkBAAIlwGDEzB_igWdjj3WLj1IPro2ONbYUAAIrAgACHcUZVo23oC09VtdaHwQ"
    MSG="✅ <b>Build done</b>
- <b>Took:</b> <code>$((DIFF / 60)) minute(s) $((DIFF % 60)) second(s) </code>
- <b>Build type:</b> <code>$BUILD_TYPE</code>
- <b>MD5 checksum:</b> <code>$MD5CHECK</code>
- <b>Zip name:</b> <code>$KERNELNAME.zip</code>

- <b>Name: </b><code>NevaKernel Mi $KERN_VER</code>
- <b>Device: </b><code>$MODEL</code>
- <b>Codename: </b><code>$DEVICE</code>
- <b>Build date: </b><code>$DATE</code>
- <b>SELinux version: </b><code>$LINUXVER</code>
- <b>Description: </b><code>$POST_DESC</code>
- <b>Credits: </b><code>$CREDITS</code>"

        curl --progress-bar -F document=@"$KernelFiles" "https://api.telegram.org/bot$TOKEN/sendDocument" \
        -F chat_id="$CHATID"  \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="$MSG"

}

##----------------------------------------------------------##

build_kernel() {
	if [ $INCREMENTAL = 0 ]
	then
		msg "|| Cleaning Sources ||"
		make clean
	fi

	if [ "$PTTG" = 1 ]
 	then
            tg_post_msg "<b>🔨 NevaKernel Build Triggered</b>
<b>Host Core Count : </b><code>$PROCS</code>
<b>Device: </b><code>$MODEL</code>
<b>Codename: </b><code>$DEVICE</code>
<b>Build Date: </b><code>$DATE</code>
<b>Kernel Name: </b><code>NevaKernel-$KERN_VER-$DEVICE</code>
<b>SELinux Version: </b><code>$LINUXVER</code>
<b>Notes: </b><code>$EXTRA_NOTE</code>"

	fi

	if [ $SILENCE = "1" ]
	then
		MAKE+=( -s )
	fi

	msg "|| Started Compilation ||"
	make O=out $DEFCONFIG
	if [ $DEF_REG = 1 ]
	then
		cp .config arch/arm64/configs/$DEFCONFIG
		git add arch/arm64/configs/$DEFCONFIG
		git commit -m "$DEFCONFIG: Regenerate
						This is an auto-generated commit"
	fi

	BUILD_START=$(date +"%s")

	if [ $COMPILER = "clang" ]
	then
		make -j"$PROCS" -k O=out \
				CROSS_COMPILE=aarch64-linux-gnu- \
				CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
				CC=clang \
				AR=llvm-ar \
				OBJDUMP=llvm-objdump \
				STRIP=llvm-strip "${MAKE[@]}" 2>&1 | tee build.log

	elif [ $COMPILER = "gcc" ]
	then
		make -j"$PROCS" -k O=out \
				CROSS_COMPILE=aarch64-none-linux-gnu- \
				AR=aarch64-none-linux-gnu-ar \
				OBJDUMP=aarch64-none-linux-gnu-objdump \
				STRIP=aarch64-none-linux-gnu-strip

	elif [ $COMPILER = "clangxgcc" ]
	then
		make -j"$PROCS" -k O=out \
					CC=clang \
					CROSS_COMPILE=aarch64-linux-gnu- \
					AR=llvm-ar \
					AS=llvm-as \
					NM=llvm-nm \
					STRIP=llvm-strip \
					OBJCOPY=llvm-objcopy \
					OBJDUMP=llvm-objdump \
					OBJSIZE=llvm-size \
					READELF=llvm-readelf \
					HOSTCC=clang \
					HOSTCXX=clang++ \
					HOSTAR=llvm-ar \
					CLANG_TRIPLE=aarch64-linux-gnu- "${MAKE[@]}" 2>&1 | tee build.log
	fi

		BUILD_END=$(date +"%s")
		DIFF=$((BUILD_END - BUILD_START))

		if [ -f $KERNEL_DIR/out/arch/arm64/boot/$FILES ]
		then
			msg "|| Kernel successfully compiled ||"
			if [ $BUILD_DTBO = 1 ]
			then
				msg "|| Building DTBO ||"
				tg_post_msg "<code>Building DTBO..</code>"
				python2 "$KERNEL_DIR/scripts/ufdt/libufdt/utils/src/mkdtboimg.py" \
					create "$KERNEL_DIR/out/arch/arm64/boot/dtbo.img" --page_size=4096 "$KERNEL_DIR/out/arch/arm64/boot/dts/$DTBO_PATH"
			fi
				gen_zip
			else
			if [ "$PTTG" = 1 ]
 			then
				tg_post_msg "<b>❌Error! Compilaton failed: Kernel Image missing</b>
<b>Build Date: </b><code>$DATE</code>
<b>Kernel Name: </b><code>NevaKernel-$KERN_VER-$DEVICE</code>
<b>Linux Tag Version: </b><code>$LINUXVER</code>
<b>Time Taken: </b><code>$((DIFF / 60)) minute(s) $((DIFF % 60)) second(s)</code>"

				exit -1
			fi
		fi

}

##--------------------------------------------------------------##

gen_zip() {
	msg "|| Zipping into a flashable zip ||"
	mv "$KERNEL_DIR"/out/arch/arm64/boot/Image.gz-dtb $AK_DIR/Image.gz-dtb
	if [ $BUILD_DTBO = 1 ]
	then
		mv "$KERNEL_DIR"/out/arch/arm64/boot/dtbo.img $AK_DIR/dtbo.img
	fi
	cd $AK_DIR
	#cp -af "$KERNEL_DIR"/init.ElectroSpectrum.rc init.spectrum.rc && sed -i "s/persist.spectrum.kernel.*/persist.spectrum.kernel ElectroPerf-LTO-$VARIANT-v2.3/g" init.spectrum.rc
    cp -af anykernel-real.sh anykernel.sh
	sed -i "s/kernel.string=.*/kernel.string=NevaKernel Mi $KERN_VER/g" anykernel.sh
	sed -i "s/kernel.for=.*/kernel.for=$VARIANT/g" anykernel.sh
	sed -i "s/kernel.compiler=.*/kernel.compiler=GCC/g" anykernel.sh
	sed -i "s/kernel.made=.*/kernel.made=ping2109/g" anykernel.sh
	sed -i "s/kernel.version=.*/kernel.version=$LINUXVER/g" anykernel.sh
	sed -i "s/build.date=.*/build.date=$DATE/g" anykernel.sh

	cd $AK_DIR
	zip -r9 "$KERNELNAME.zip" * -x .git README.md anykernel-real.sh .gitignore zipsigner* *.zip

	if [ $SIGN = 1 ]
	then
		## Sign the zip before sending it to telegram
		if [ "$PTTG" = 1 ]
 		then
 			msg "|| Signing Zip ||"
			tg_post_msg "<code>Signing Zip file with AOSP keys..</code>"
 		fi
		cd $AK_DIR
		java -jar zipsigner-3.0.jar $KERNELNAME.zip $KERNELNAME-signed.zip
	fi

	if [ "$PTTG" = 1 ]
 	then
		tg_send_files "$1"
	fi
}

setversioning
clone
exports
build_kernel
