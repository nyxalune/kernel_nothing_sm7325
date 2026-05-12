#!/bin/bash
# build.sh - Android Kernel Build Script to k5.x
# Make sure clang is added to your path before using this script
# Semi-automatic script suitable for use in Ubuntu, Debian, Kali and NetHunter
# Author Madara273
# ----------------------------------------------------------------------------

# ---- Define colors ----
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
MAGENTA='\033[1;35m'
LGREEN='\e[92m'
PINK='\033[38;5;206m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m' # No color

# ---- Get the absolute path of the current directory ----
CURRENT_DIR="$(pwd)"

# ---- Set Eastern Time timezone ----
export TZ=Europe/Kiev # Enter your time zone

# ---- random_color - generates a random color for output to the terminal ----
random_color() {
	local colors=($GREEN $RED $YELLOW $PURPLE $BLUE)	# Array of colors
	local random_index=$((RANDOM % ${#colors[@]}))		# Random index
	echo -e "${colors[$random_index]}"			# For color interpretation
}

# ---- Get information about the distribution and its version ----
. /etc/os-release 2>/dev/null || { OS=$(uname -s); VERSION_ID=$(uname -r); }

# ---- Output information to the terminal -----
echo -e "\n$(random_color)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "    - OS: $NAME $VERSION_ID"
echo -e "    - Kernel: $(uname -r)"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# ----  ASCII Art Logo with random colors ----
ascii_art_logo() {
	echo -e "
$(random_color)*******************************NothingPhone1*******************************${NC}
$(random_color) ______ ______ _______ _______ _______ _______ ___ ___ ______ _______ ${NC}
$(random_color)|   __ \   __ \       |_     _|       |_     _|   |   |   __ \    ___|${NC}
$(random_color)|    __/      <   -   | |   | |   -   | |   |  \     /|    __/    ___|${NC}
$(random_color)|___|  |___|__|_______| |___| |_______| |___|   |___| |___|  |_______|${NC}
"
}

# ---- Prompt user for input ----
echo -e "${PURPLE}Enter KBUILD_USER:${NC}"
read -t 5 -rp "KBUILD_USER: " KBUILD_USER
KBUILD_USER="${KBUILD_USER:-Willay}" # If user doesn't enter a value, use "Willay"
echo "$KBUILD_USER"	# Output the value of KBUILD_USER

echo -e "${PURPLE}Enter KBUILD_HOST:${NC}"
read -t 5 -rp "KBUILD_HOST: " KBUILD_HOST
KBUILD_HOST="${KBUILD_HOST:-Kali_GNU/Linux-2025.3}"	# If user doesn't enter a value, use "Kali_GNU/Linux-2025.3"
echo "$KBUILD_HOST"	# Output the value of KBUILD_HOST

# ----  Set environment variables ----
export CLANG_TRIPLE="aarch64-linux-gnu-"
export CROSS_COMPILE="aarch64-linux-gnu-"
export CROSS_COMPILE_ARM32="arm-linux-gnueabi-"

THREAD="${1:-$(nproc --all)}"
CC_ADDITIONAL_FLAGS="LLVM_IAS=1 LLVM=1 -Wno-error=unused-function"

# ---- Target Variables ----
TARGET_ARCH="arm64"
TARGET_SUBARCH="arm64"
TARGET_CC="clang"
TARGET_HOSTLD="ld.lld"
TARGET_CLANG_TRIPLE="aarch64-linux-gnu-"
TARGET_CROSS_COMPILE="aarch64-linux-gnu-"
TARGET_CROSS_COMPILE_COMPAT="arm-linux-gnueabi-"
TARGET_BUILD_USER="$KBUILD_USER"
TARGET_BUILD_HOST="$KBUILD_HOST"
TARGET_DEVICE="lahaina-qgki"
TARGET_PRODUCT="$TARGET_DEVICE"
TARGET_OUT="../out"
TARGET_DTC_FLAGS="-q"

TARGET_COMPILER_STRING="$COMPILER_STRING"
TARGET_LD_VERSION="$LD_VERSION"
TARGET_CC_VERSION="$CC_VERSION"

# ---- Kernel target parameters ----
TARGET_KERNEL_FILE="$TARGET_OUT/arch/arm64/boot/Image"
TARGET_KERNEL_DTB="$TARGET_OUT/arch/arm64/boot/dtb"
TARGET_KERNEL_DTB_IMG="$TARGET_OUT/arch/arm64/boot/dtb.img"
TARGET_KERNEL_DTBO_IMG="$TARGET_OUT/arch/arm64/boot/dtbo.img"
TARGET_KERNEL_NAME="Kernel"
get_kernel_version(){
	TARGET_KERNEL_MOD_VERSION="$(make kernelversion O=$TARGET_OUT ARCH=arm64)"
}

# ---- Final kernel build parameters ----
FINAL_KERNEL_BUILD_PARA="ARCH=$TARGET_ARCH \
				SUBARCH=$TARGET_SUBARCH \
				HOSTLD=$TARGET_HOSTLD \
				CC=$TARGET_CC \
				CROSS_COMPILE=$TARGET_CROSS_COMPILE \
				CROSS_COMPILE_COMPAT=$TARGET_CROSS_COMPILE_COMPAT \
				CLANG_TRIPLE=$TARGET_CLANG_TRIPLE \
				$CC_ADDITIONAL_FLAGS \
				DTC_FLAGS=$TARGET_DTC_FLAGS \
				O=$TARGET_OUT \
				CC_VERSION=$TARGET_CC_VERSION \
				LD_VERSION=$TARGET_LD_VERSION \
				TARGET_PRODUCT=$TARGET_DEVICE \
				KBUILD_COMPILER_STRING=$TARGET_COMPILER_STRING \
				KBUILD_BUILD_USER=$TARGET_BUILD_USER \
				KBUILD_BUILD_HOST=$TARGET_BUILD_HOST \
				-j$THREAD"

# ----  Defconfig parameters ----
DEFCONFIG_PATH=arch/arm64/configs/vendor
DEFCONFIG_NAME="lahaina-qgki_defconfig"

# ---- Time parameters ----
START_SEC=$(date +%s)
CURRENT_TIME=$(date '+%Y%m%d-%H%M')

# ---- Setup secure keystore paths ----
HOME="${HOME:-/tmp}"
[ "$HOME" = "/" ] && HOME="/tmp"
SIGNER_DIR="$HOME/tenzo_signer"

KEYSTORE="$SIGNER_DIR/tenzo.keystore"
PASSFILE="$SIGNER_DIR/.keystore_pass"
ALIASFILE="$SIGNER_DIR/.keystore_alias"
ROOTCA_KEY="$SIGNER_DIR/rootCA.key"
ROOTCA_CERT="$SIGNER_DIR/rootCA.crt"
TENZO_KEY="$SIGNER_DIR/tenzo.key"
TENZO_CERT="$SIGNER_DIR/tenzo.crt"
P12_FILE="$SIGNER_DIR/tenzo.p12"
CSR_FILE="$SIGNER_DIR/tenzo.csr"

# ---- Logging / Output ----
AK3_PATH="$TARGET_OUT/AnyKernel3"
LOG_FILE="$AK3_PATH/build.log"
WARNING_PATTERN="warning"
ERROR_PATTERN="error"
NORMAL_PATTERN="normal"

# ---- Getting information about git remote, branch and commit ----
remote=$(git remote -v 2>&1 | grep push | head -n1 | cut -f2 | sed "s/(push)//" | cut -f4 -d "/")
domain=$(git remote -v 2>&1 | grep push | head -n1 | cut -f2 | sed "s/(push)//" | cut -f5 -d "/" | xargs)
branch=$(git status 2>&1 | grep "On branch" | sed -e 's/On branch //g')
commit=$(git rev-parse --short=8 HEAD)

# ----  Kernel DIR ----
KERNEL_DIR=$(pwd)
echo -e "${GREEN}$KERNEL_DIR${NC}"

# ---- Function to display build information ----
display_build_info(){
	echo -e "${PURPLE}***************Spacewar-Kernel**************${NC}"
	echo -e "PRODUCT: $TARGET_DEVICE"
	echo -e "USER: $KBUILD_USER"
	echo -e "HOST: $KBUILD_HOST"
	echo -e "SUBLEVEL: $(grep -E '^SUBLEVEL =' Makefile | awk '{print $3}')"
	echo -e "${PURPLE}***************Device-Builder**************${NC}"
	echo -e "BUILD_DEVICE: $(lsb_release -a)"
	echo -e "Compiler: $(clang --version | head -n 1)"
	echo -e "Core count: $(nproc)"
	echo -e "Build Date: $(date +"%Y-%m-%d %H:%M")"
	echo -e "${PURPLE}*************last commit details***********${NC}"
	echo -e "Last commit (name): $(git log -1 --pretty=format:%s)"
	echo -e "Last commit (hash): $(git log -1 --pretty=format:%H)"
	echo -e "${PURPLE}*******************************************${NC}"
}

# ---- Function for interactive action selection with timeout ----
choose_action(){
	while true; do
		echo -e "Choose an action:"
		echo -e "${GREEN}1.👉 Install necessary packages${NC}"
		echo -e "${GREEN}2.👉 Start kernel compilation${NC}"
		echo -e "${GREEN}3.👉 Exit program${NC}"

		# Set timeout for user input (5 seconds)
		read -t 5 -p "Enter the action number (1/2/3): " choice

		# If no input is provided within 5 seconds, default to action 1 and then 2
		[ -z "$choice" ] && echo -e "${YELLOW}No input detected. Automatically selecting action 1.${NC}" && install_packages && echo -e "${YELLOW}Proceeding to action 2 automatically.${NC}" && compile_kernel && break

		case $choice in
			1 ) install_packages;;
			2 ) compile_kernel;;
			3 ) exit;;
			* ) echo -e "${RED}Invalid choice. Please enter 1, 2, or 3.${NC}";;
		esac
	done
}

# ---- Install packages ----
install_packages(){
	echo -e "${YELLOW}Starting package installation...${NC}"

	sudo apt-get install -y bc
	sudo apt-get install -y bison
	sudo apt-get install -y build-essential
	sudo apt-get install -y zstd
	sudo apt-get install -y clang
	sudo apt-get install -y lld
	sudo apt-get install -y flex
	sudo apt-get install -y gnupg
	sudo apt-get install -y gperf
	sudo apt-get install -y ccache
	sudo apt-get install -y liblz4-tool
	sudo apt-get install -y libsdl1.2-dev
	sudo apt-get install -y libstdc++6
	sudo apt-get install -y libxml2
	sudo apt-get install -y libxml2-utils
	sudo apt-get install -y pngcrush
	sudo apt-get install -y schedtool
	sudo apt-get install -y squashfs-tools
	sudo apt-get install -y xsltproc
	sudo apt-get install -y zlib1g-dev
	sudo apt-get install -y libncurses5-dev
	sudo apt-get install -y bzip2
	sudo apt-get install -y git
	sudo apt-get install -y gcc
	sudo apt-get install -y g++
	sudo apt-get install -y libssl-dev
	sudo apt-get install -y openssl
	sudo apt-get install -y gcc-aarch64-linux-gnu
	sudo apt-get install -y llvm
	sudo apt-get install -y python3-pip
	sudo apt-get install -y cpio
	sudo apt-get install -y binutils
	sudo apt-get install -y zip
	sudo apt-get install -y device-tree-compiler
	sudo apt-get install -y default-jre
	sudo apt-get install -y openjdk-21-jdk

	echo -e "${GREEN}Necessary packages successfully installed.${NC}"
}

# ---- Clone Anykernel3 ----
clone_anykernel3(){
	while true; do
		echo -e "${YELLOW}Select branch to clone or skip:${NC}"
		echo -e "${BLUE}1.👉 NOS${NC}"
		echo -e "${BLUE}2.👉 Custom git clone command${NC}"
		echo -e "${BLUE}3.👉 Skip${NC}"

		# Set timeout for user input (5 seconds)
		read -t 5 -rp "Enter your choice (1, 2, or 3): " choice

		# If no input is provided within 5 seconds, default to action 1 (NOS)
		[ -z "$choice" ] && echo -e "${YELLOW}No input detected. Automatically selecting NOS.${NC}" && choice=1

		case $choice in
			1)
				branch="NOS"
				git clone --depth=1 https://github.com/William24hmar/AnyKernel3.git -b "$branch" "$AK3_PATH" &&
				{ echo -e "${GREEN}Clone successful.${NC}"; break; } || echo -e "${RED}Clone failed.${NC}"
				;;
			2)
				while true; do
					read -rp "Enter the full git clone command (e.g., git clone https://github.com/username/repository.git -b branch_name): " clone_command
					# Execute the custom command and check its success
					eval "$clone_command" && { echo -e "${GREEN}Clone successful.${NC}"; break; } || echo -e "${RED}Clone failed. Please try again.${NC}"
				done
				return 0
				;;
			3)
				echo -e "${YELLOW}Skipping AnyKernel3 cloning.${NC}"
				return 0
				;;
			*)
				echo -e "${RED}Invalid choice. Please try again.${NC}"
				;;
		esac
	done
}

# ---- Function to check for necessary tools ----
check_tools(){
	echo -e "${YELLOW}Checking for necessary tools...${NC}"
	command -v clang > /dev/null 2>&1 || { echo -e "${RED}clang is not installed.${NC}"; exit 1; }
	command -v make > /dev/null 2>&1 || { echo -e "${RED}make is not installed.${NC}"; exit 1; }
	command -v mke2fs > /dev/null 2>&1 || { echo -e "${RED}mke2fs is not installed.${NC}"; exit 1; }
	command -v dtc > /dev/null 2>&1 || { echo -e "${RED}dtc (Device Tree Compiler) is not installed.${NC}"; exit 1; }
	echo -e "${GREEN}All necessary tools are installed.${NC}"
}

# ---- Function to create default kernel configuration ----
make_defconfig(){
	echo -e "${YELLOW}------------------------------${NC}"
	echo -e "${YELLOW} Generating kernel configuration...${NC}"
	make $FINAL_KERNEL_BUILD_PARA $DEFCONFIG_NAME || { echo -e "${RED}Failed to create default kernel configuration.${NC}"; exit 1; }
	echo -e "${GREEN}Default kernel configuration created successfully.${NC}"
	echo -e "${YELLOW}------------------------------${NC}"
}

# ---- Function for building a kernel with color output and countdown ----
build_kernel(){
	echo -e "${YELLOW}---------------------------------------"
	echo " Building the kernel..."
	echo -e "---------------------------------------${NC}"

	set -e  # Exit on unsuccessful commands

	# Function for outputting with color and writing to the log
	log_echo(){
		local color=$1
		shift
		local message="$@"
		echo -e "${color}${message}${NC}"  # Output to terminal
		echo -e "${color}${message}${NC}" >> "$LOG_FILE"  # Write to the log file
	}

	# Set the start time
	START_SEC=$(date +%s)

	# Set initial colors for time and build
	TIME_COLOR="${BLUE}"
	BUILD_COLOR="${GREEN}"

	# Creating an array for conditions and their colors
	declare -A COLORS
	COLORS["warning"]=$PURPLE
	COLORS["error"]=$RED
	COLORS["normal"]=$GREEN

	# Running a kernel build with real-time log processing
	eval make $FINAL_KERNEL_BUILD_PARA 2>&1 | {
		while IFS= read -r line; do
			# Get the current time for each line
			CURRENT_SEC=$(date +%s)
			COST_SEC=$(($CURRENT_SEC - $START_SEC))

			# Time formatting
			TIME_FORMAT=$(printf "%02d:%02d" $(($COST_SEC / 60)) $(($COST_SEC % 60)))

			# Color change based on patterns
			color="normal"
			[[ $line =~ "$WARNING_PATTERN" ]] && color="warning"
			[[ $line =~ "$ERROR_PATTERN" ]] && color="error"

			# Display time in blue and message depending on color
			log_echo "${TIME_COLOR}$TIME_FORMAT ${COLORS[$color]}$line${NC}"
		done
	}

	# Calculate the total execution time
	END_SEC=$(date +%s)
	COST_SEC=$(($END_SEC - $START_SEC))
	# Output the execution time to the terminal and write it to the log
	echo -e "${GREEN}Kernel build took $(($COST_SEC / 60))m $(($COST_SEC % 60))s${NC}" | tee -a "$LOG_FILE"
}

# ---- Function to link all dtb files -----
link_all_dtb_files(){
	echo -e "${YELLOW}Linking all dtb and dtbo files...${NC}"

	# Ensure the output directories exist
	mkdir -p $TARGET_OUT/arch/arm64/boot

	# Link .dtb files
	echo -e "${YELLOW}Linking .dtb files...${NC}"
	find $TARGET_OUT/arch/arm64/boot/dts/ -name '*.dtb' -exec cat {} + > $TARGET_OUT/arch/arm64/boot/dtb || echo -e "${RED}Failed to link .dtb files.${NC}"

	echo -e "${YELLOW}Linking completed.${NC}"
}

# ---- Generate a secure keystore with a trusted cert for ZIP/APK signing ----
generate_secure_keystore() {
	[[ -f "$KEYSTORE" ]] && echo -e "${GREEN}✔ Keystore already exists: $KEYSTORE${NC}" && return

	echo -e "${YELLOW}Creating new keystore and full trust chain...${NC}"

	rm -rf "$SIGNER_DIR"
	mkdir -p "$SIGNER_DIR" && chmod 700 "$SIGNER_DIR"

	PASS=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 18)
	UNIQUE_ID=$(date +%Y%m%d_%H%M%S)
	KEYALIAS="tenzoKey_${UNIQUE_ID}"

	echo "$PASS" > "$PASSFILE"
	echo "$KEYALIAS" > "$ALIASFILE"
	chmod 600 "$PASSFILE" "$ALIASFILE"

	echo -e "${CYAN}Generating root CA...${NC}" &&
	openssl genrsa -out "$ROOTCA_KEY" 4096 &&
	openssl req -x509 -new -nodes -key "$ROOTCA_KEY" -sha256 -days 9125 \
		-out "$ROOTCA_CERT" -subj "/CN=Tenzo Root CA/O=Madara273/C=UA" ||
	{ echo -e "${RED}✘ Root CA generation failed${NC}"; return 1; }

	echo -e "${CYAN}Generating Tenzo keypair and CSR...${NC}" &&
	openssl genrsa -out "$TENZO_KEY" 4096 &&
	openssl req -new -key "$TENZO_KEY" -out "$CSR_FILE" \
		-subj "/CN=Tenzo/OU=Root/O=Madara273/L=UA/ST=Ukraine/C=UA" ||
	{ echo -e "${RED}✘ Keypair or CSR failed${NC}"; return 1; }

	openssl x509 -req -in "$CSR_FILE" -CA "$ROOTCA_CERT" -CAkey "$ROOTCA_KEY" \
		-CAcreateserial -out "$TENZO_CERT" -sha256 -days 365 || \
	{ echo -e "${RED}✘ Signing failed${NC}"; return 1; }

	echo -e "${CYAN}Exporting to PKCS#12...${NC}" &&
	openssl pkcs12 -export \
		-inkey "$TENZO_KEY" \
		-in "$TENZO_CERT" \
		-certfile "$ROOTCA_CERT" \
		-out "$P12_FILE" \
		-password pass:"$PASS" \
		-name "$KEYALIAS" ||
	{ echo -e "${RED}✘ PKCS#12 export failed${NC}"; return 1; }

	keytool -importkeystore \
		-srckeystore "$P12_FILE" -srcstoretype PKCS12 -srcstorepass "$PASS" \
		-destkeystore "$KEYSTORE" -deststoretype PKCS12 -deststorepass "$PASS" \
		-alias "$KEYALIAS" -noprompt || \
	{ echo -e "${RED}✘ PKCS12 import failed${NC}"; return 1; }

	keytool -importcert -trustcacerts -alias "rootCA_${UNIQUE_ID}" -file "$ROOTCA_CERT" \
		-keystore "$KEYSTORE" -storepass "$PASS" -noprompt ||
	{ echo -e "${RED}✘ Failed to add rootCA to keystore${NC}"; return 1; }

	# Java truststore
	echo -e "${CYAN}Adding Root CA to Java truststore...${NC}"

	sudo keytool -list -cacerts -storepass changeit -alias "tenzoRoot" >/dev/null 2>&1 && \
	sudo keytool -delete -cacerts -storepass changeit -alias "tenzoRoot" -noprompt

	sudo keytool -importcert -alias "tenzoRoot" -file "$ROOTCA_CERT" \
		-cacerts -storepass changeit -noprompt && \
		echo -e "${GREEN}✔ Added to Java truststore (cacerts)${NC}" || \
		echo -e "${RED}✘ Failed to add to Java truststore${NC}"

	echo -e "${GREEN}✔ Keystore created: $KEYSTORE${NC}"
	show_fingerprint
}

# ----  SIGN ZIP FILE ----
sign_zip() {
	ZIP="$1"
	OUT="$2"

	[[ -f "$ZIP" ]] || {
		echo -e "${RED}✘ ZIP file not found: $ZIP${NC}"
		exit 1
	}

	generate_secure_keystore

	PASS=$(cat "$PASSFILE")
	KEYALIAS=$(cat "$ALIASFILE")

	cp "$ZIP" "$OUT"

	echo -e "${CYAN}Signing ZIP with timestamp...${NC}"
	SIGNING_OUTPUT=$(jarsigner -keystore "$KEYSTORE" -storepass "$PASS" -keypass "$PASS" \
		-sigalg SHA256withRSA -digestalg SHA-256 \
		-tsa http://timestamp.digicert.com \
		"$OUT" "$KEYALIAS" 2>&1)

	echo "$SIGNING_OUTPUT" | grep -q "jar signed." &&
	{
		echo -e "${GREEN}✔ Signed successfully: $OUT${NC}"
		echo "$SIGNING_OUTPUT" | grep -q "The timestamp will expire" &&
			echo -e "${YELLOW}$(echo "$SIGNING_OUTPUT" | grep "The timestamp will expire")${NC}"
	} || {
		echo -e "${RED}❌ Signing failed!${NC}"
		echo "$SIGNING_OUTPUT"
		exit 1
	}
}

# ---- SHOW FINGERPRINT ----
show_fingerprint() {
	[[ -f "$KEYSTORE" && -f "$PASSFILE" && -f "$ALIASFILE" ]] &&
	{
		PASS=$(cat "$PASSFILE")
		KEYALIAS=$(cat "$ALIASFILE")
		echo -e "${CYAN}SHA256 Fingerprint:${NC}"
		keytool -list -v -keystore "$KEYSTORE" -storepass "$PASS" -alias "$KEYALIAS" 2>/dev/null | grep "SHA256:"
	} || {
		echo -e "${RED}✘ Cannot display fingerprint. Keystore or data missing.${NC}"
	}
}

# ----  Generate flashable archive and sign it ----
generate_flashable() {
	echo -e "${YELLOW}------------------------------${NC}"
	echo -e "${YELLOW} Generating flashable kernel ${NC}"
	echo -e "${YELLOW}------------------------------${NC}"

	AK3_PATH=$TARGET_OUT/AnyKernel3

	echo -e "${YELLOW} Fetching AnyKernel ${NC}"

	cd "$TARGET_OUT"
	ANYKERNEL_PATH=AnyKernel3

	echo -e "${YELLOW} Copying kernel file ${NC}"
	cp -r "$TARGET_KERNEL_FILE" "$ANYKERNEL_PATH/" || echo -e "${RED}Failed to copy $TARGET_KERNEL_FILE.${NC}"
	cp -r "$TARGET_KERNEL_DTB" "$ANYKERNEL_PATH/" || echo -e "${RED}Failed to copy $TARGET_KERNEL_DTB.${NC}"
	cp -r "$TARGET_KERNEL_DTB_IMG" "$ANYKERNEL_PATH/" || echo -e "${RED}Failed to copy $TARGET_KERNEL_DTB_IMG.${NC}"
	cp -r "$TARGET_KERNEL_DTBO_IMG" "$ANYKERNEL_PATH/" || echo -e "${RED}Failed to copy $TARGET_KERNEL_DTBO_IMG.${NC}"

	echo -e "${YELLOW} Packing flashable kernel ${NC}"

	CURRENT_TIME=${CURRENT_TIME:-$(date +"%Y%m%d-%H%M")}
	CLEAN_TIME=$(echo "$CURRENT_TIME" | sed 's/[^a-zA-Z0-9._-]//g')

	cd "$ANYKERNEL_PATH" || {
		echo -e "${RED}Failed to enter $ANYKERNEL_PATH directory.${NC}"
		exit 1
	}

	FLASHABLE_ZIP="Spacewar-$CLEAN_TIME.zip"
	SIGNED_ZIP="Spacewar-$CLEAN_TIME-signed.zip"

	zip -q -r "$FLASHABLE_ZIP" * -x "README.md" "changelog.txt" "defconfig" "kernel-changelog.txt" "build.log" || {
		echo -e "${RED}Failed to pack flashable kernel.${NC}"
		exit 1
	}

	echo -e "${YELLOW} Signing ZIP file securely... ${NC}"
	sign_zip "$FLASHABLE_ZIP" "$SIGNED_ZIP"

	echo -e "${GREEN}✔ Flashable signed zip ready: $TARGET_OUT/$ANYKERNEL_PATH/$SIGNED_ZIP${NC}"

	cd "$KERNEL_DIR"
}

# ---- Save kernel configuration with timeout ----
save_defconfig() {
	echo -e "${YELLOW}------------------------------${NC}"
	echo -e "${YELLOW} Saving kernel configuration...${NC}"
	echo -e "${YELLOW}------------------------------${NC}"

	echo -en "${PURPLE}Do you want to save the kernel configuration?${NC} (y/n): "

	read -t 3 answer
	[ -z "$answer" ] && answer="n"

	case $answer in
		[Yy]* )
			[ -f "$TARGET_OUT/.config" ] && cp "$TARGET_OUT/.config" "$AK3_PATH/defconfig" && \
			END_SEC=$(date +%s) && \
			COST_SEC=$((END_SEC - START_SEC)) && \
			echo -e "${YELLOW}Completed. Kernel configuration saved to ${AK3_PATH}/defconfig${NC}" && \
			echo -e "${YELLOW}Kernel configuration save took ${COST_SEC} seconds.${NC}" || \
			echo -e "${RED}Error: '$TARGET_OUT/.config' not found. Cannot save configuration.${NC}"
			;;
		[Nn]* )
			echo -e "${YELLOW}Skipping kernel configuration save.${NC}"
			;;
		* )
			echo -e "${RED}Invalid input. Defaulting to no save.${NC}"
			;;
	esac
}

# ----  Clean ----
clean() {
	echo -e "${YELLOW}Cleaning source tree and build files...${NC}"
	make mrproper -j$THREAD > /dev/null 2>&1
	make clean -j$THREAD > /dev/null 2>&1
	rm -rf $TARGET_OUT
	rm -rf .config
	rm -rf output
	echo -e "${GREEN}Clean completed.${NC}"
}

# ---- Setup colour for the script ----
purple='\033[0;35m'

# Function to show an informational message
msg() {
	echo -e "\e[1;32m$*\e[0m"
}

err() {
	echo -e "\e[1;41m$*\e[0m"
	exit 1
}

# ---- Function to create a changelog file with the last 400 commits and move it to $TARGET_OUT ----
create_changelog() {
	# Define the filename for the changelog
	local changelog_file="changelog.txt"

	# Use git log to get the last 400 commits and format them
	git log -n 400 --pretty=format:"%h - %s (%an)" > "$changelog_file"

	# Print the location of the changelog file
	msg "${purple}Changelog saved to $changelog_file ${white}"

	# Add a dash before each commit line for better readability
	sed -i -e "s/^/- /" "$changelog_file"

	# Move the changelog file to $TARGET_OUT
	mv "$changelog_file" "$TARGET_OUT/$AK3_PATH/"
}

# ----  End Build Info ----
# Function to display kernel version and config information
display_kernel_version_info() {
	# Find lahaina-qgki_defconfig file
	lahaina-qgki_defconfig=$(find . -name 'lahaina-qgki_defconfig' -print -quit)

	[ -z "$lahaina-qgki_defconfig" ] && echo -e "${RED}lahaina-qgki_defconfig not found!${NC}" && return 1

	echo -e "${GREEN}===================END_BUILD=================${NC}"
	echo -e "${PURPLE}***************Spacewar-Kernel**************${NC}"
	echo -e "USER: $KBUILD_USER"
	echo -e "HOST: $KBUILD_HOST"
	echo -e "${PURPLE}*************last commit details************${NC}"
	echo -e "Last commit (name): $(git log -1 --pretty=format:%s)"
	echo -e "Last commit (hash): $(git log -1 --pretty=format:%H)"
	echo -e "${PURPLE}********************************************${NC}"
	echo -e "VERSION: $(grep -E '^VERSION =' Makefile | awk '{print $3}')"
	echo -e "PATCHLEVEL: $(grep -E '^PATCHLEVEL =' Makefile | awk '{print $3}')"
	echo -e "SUBLEVEL: $(grep -E '^SUBLEVEL =' Makefile | awk '{print $3}')"
	echo -e "EXTRAVERSION: $(grep -E '^EXTRAVERSION =' Makefile | awk '{print $3}')"
	echo -e "NAME: $(grep -E '^NAME =' Makefile | awk '{print $3}')"
	echo -e "CONFIG_LOCALVERSION: $(grep -E '^CONFIG_LOCALVERSION=' $lahaina-qgki_defconfig | awk -F'=' '{print $2}')"
	echo -e "CONFIG_UNAME_OVERRIDE_STRING: $(grep -E '^CONFIG_UNAME_OVERRIDE_STRING=' $lahaina-qgki_defconfig | awk -F'=' '{print $2}')"
	echo -e "${PURPLE}**********************************************${NC}"
}

# ---- Kernel compilation function ----
compile_kernel() {
	random_color
	ascii_art_logo
	clean
	check_tools
	clone_anykernel3
	make_defconfig
	display_build_info
	create_changelog
	save_defconfig
	build_kernel
	link_all_dtb_files
	generate_flashable
	display_kernel_version_info
}

# ----  Prompt successive steps ----
choose_action

echo -e "${GREEN}Done.${NC}"