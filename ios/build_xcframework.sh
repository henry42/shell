#! /bin/sh -e
set -x
TVOS_SUPPORT=0

# Output Path
OUTPUT_DIR_PATH=$1
# Xcode Project Name
PROJECT_NAME=$2
if [[ -z $1 ]]; then
    echo "❌Output dir was not set. try to run ./build.sh Build"
    exit 1
fi
if [[ -z $2 ]]; then
    echo "❌Project name or workspace was not set. try to run ./build.sh Build Project"
    exit 1
fi

if [[ -z $3 ]]; then
    echo "Scheme name was not set. try to run ./build.sh Build Project Scheme"
    exit 1
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
            -workspace ${PROJECT_NAME} \
            -scheme ${1} \
            -destination "${2}" \
            -archivePath "${3}" \
            SKIP_INSTALL=NO \
            BUILD_LIBRARY_FOR_DISTRIBUTION=YES | xcpretty
    else
        xcodebuild archive \
            -project ${PROJECT_NAME}.xcodeproj \
            -scheme ${1} \
            -destination "${2}" \
            -archivePath "${3}" \
            SKIP_INSTALL=NO \
            BUILD_LIBRARY_FOR_DISTRIBUTION=YES | xcpretty
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
DYNAMIC_FRAMEWORK=${3}
echo "📝 Archive $DYNAMIC_FRAMEWORK"
buildArchive ${DYNAMIC_FRAMEWORK}
echo "🗜 Create $DYNAMIC_FRAMEWORK.xcframework"
createXCFramework ${DYNAMIC_FRAMEWORK}
mv ${OUTPUT_DIR_PATH}/xcframeworks/${DYNAMIC_FRAMEWORK}.xcframework ${OUTPUT_DIR_PATH}/${DYNAMIC_FRAMEWORK}.xcframework
rm -rf $OUTPUT_DIR_PATH/xcframeworks
rm -rf $OUTPUT_DIR_PATH/archives
