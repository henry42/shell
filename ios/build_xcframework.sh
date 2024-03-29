#! /bin/sh -e
# set -x
TVOS_SUPPORT=0

# Usage info
show_help() {
cat << EOF
Usage: ${0##*/} [-h] -o OUTDIR -p PROJECT -s SCHEME [-c Configuration]
EOF
}

OUTPUT_DIR_PATH=""
PROJECT_NAME=""
CONFIGURATION="Release"
SCHEME=""

OPTIND=1 # Reset is necessary if getopts was used previously in the script.  It is a good idea to make this local in a function.
while getopts "ho:p:c:s:" opt; do
    case "$opt" in
        h)
            show_help
            exit 0
            ;;
        p)  PROJECT_NAME=$OPTARG
            ;;
        o)  OUTPUT_DIR_PATH=$OPTARG
            ;;
        s)  SCHEME=$OPTARG
            ;;
        c)  CONFIGURATION=$OPTARG
            ;;
        '?')
            show_help >&2
            exit 1
            ;;
    esac
done

if [[ -z $OUTPUT_DIR_PATH ]]; then
    show_help
    exit 1
fi
if [[ -z $PROJECT_NAME ]]; then
    show_help
    exit 1
fi

if [[ -z $SCHEME ]]; then
    show_help
    exit 1
fi


if [ -n "$CONFIGURATION" ]; then
    CONFIGURATION=("-configuration" "$CONFIGURATION")
fi

# Prints the archive path for simulator
function archivePathSimulator() {
    local DIR=${OUTPUT_DIR_PATH}/archives/"${1}-SIMULATOR"
    echo "${DIR}"
}
# Prints the archive path for device
function archivePathDevice() {
    local DIR=${OUTPUT_DIR_PATH}/archives/"${1}-DEVICE"
    echo "${DIR}"
}
# Archive takes 3 params
#
# 1st == SCHEME
# 2nd == destination
# 3rd == archivePath
function archive() {
    echo "📨 Starts archiving the scheme: ${1} for destination: ${2};\n📝 Archive path: ${3}.xcarchive"

    if [ "${PROJECT_NAME##*.}" = "xcworkspace" ]; then
        xcodebuild archive \
            -workspace ${PROJECT_NAME} ${CONFIGURATION[*]}\
            -scheme ${1} \
            -destination "${2}" \
            -archivePath "${3}" \
            SKIP_INSTALL=NO \
            BUILD_LIBRARY_FOR_DISTRIBUTION=YES
    else
        xcodebuild archive \
            -project ${PROJECT_NAME}.xcodeproj ${CONFIGURATION[*]}\
            -scheme ${1} \
            -destination "${2}" \
            -archivePath "${3}" \
            SKIP_INSTALL=NO \
            BUILD_LIBRARY_FOR_DISTRIBUTION=YES
    fi
}
# Builds archive for iOS/tvOS simulator & device
function buildArchive() {
    SCHEME=${1}
    archive $SCHEME "generic/platform=iOS Simulator" $(archivePathSimulator $SCHEME)
    archive $SCHEME "generic/platform=iOS" $(archivePathDevice $SCHEME)
    if [ $TVOS_SUPPORT -eq 1 ]; then
        archive "${SCHEME}TV" "generic/platform=tvOS Simulator" $(archivePathSimulator "${SCHEME}TV")
        archive "${SCHEME}TV" "generic/platform=tvOS" $(archivePathDevice "${SCHEME}TV")
    fi
}
# Creates xc framework
function createXCFramework() {
    FRAMEWORK_ARCHIVE_PATH_POSTFIX=".xcarchive/Products/Library/Frameworks"
    FRAMEWORK_SIMULATOR_DIR="$(archivePathSimulator $1)${FRAMEWORK_ARCHIVE_PATH_POSTFIX}"
    FRAMEWORK_DEVICE_DIR="$(archivePathDevice $1)${FRAMEWORK_ARCHIVE_PATH_POSTFIX}"
    if [ $TVOS_SUPPORT -eq 1 ]; then
        FRAMEWORK_SIMULATOR_TV_DIR="$(archivePathSimulator $1TV)${FRAMEWORK_ARCHIVE_PATH_POSTFIX}"
        FRAMEWORK_DEVICE_TV_DIR="$(archivePathDevice $1TV)${FRAMEWORK_ARCHIVE_PATH_POSTFIX}"
    fi

    if [ $TVOS_SUPPORT -eq 1 ]; then
        xcodebuild -create-xcframework \
            -framework ${FRAMEWORK_SIMULATOR_DIR}/${1}.framework \
            -framework ${FRAMEWORK_DEVICE_DIR}/${1}.framework \
            -framework ${FRAMEWORK_SIMULATOR_TV_DIR}/${1}TV.framework \
            -framework ${FRAMEWORK_DEVICE_TV_DIR}/${1}TV.framework \
            -output ${OUTPUT_DIR_PATH}/xcframeworks/${1}.xcframework
    else
        xcodebuild -create-xcframework \
            -framework ${FRAMEWORK_SIMULATOR_DIR}/${1}.framework \
            -framework ${FRAMEWORK_DEVICE_DIR}/${1}.framework \
            -output ${OUTPUT_DIR_PATH}/xcframeworks/${1}.xcframework
    fi
}
echo "🚀 Process started 🚀"
echo "📂 Evaluating Output Dir"
echo "🧼 Cleaning the dir: ${OUTPUT_DIR_PATH}"
rm -rf $OUTPUT_DIR_PATH
DYNAMIC_FRAMEWORK=${SCHEME}
echo "📝 Archive $DYNAMIC_FRAMEWORK"
buildArchive ${DYNAMIC_FRAMEWORK}
echo "🗜 Create $DYNAMIC_FRAMEWORK.xcframework"
createXCFramework ${DYNAMIC_FRAMEWORK}
mv ${OUTPUT_DIR_PATH}/xcframeworks/${DYNAMIC_FRAMEWORK}.xcframework ${OUTPUT_DIR_PATH}/${DYNAMIC_FRAMEWORK}.xcframework
rm -rf $OUTPUT_DIR_PATH/xcframeworks
rm -rf $OUTPUT_DIR_PATH/archives
