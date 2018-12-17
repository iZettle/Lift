#!/bin/sh

set -o errexit
set -o errtrace
set -o pipefail

PROJECT="Lift.xcodeproj"
SCHEME="Lift"

IOS_SDK="iphonesimulator12.1"
IOS_DESTINATION="OS=12.1,name=iPhone 8"

usage() {
cat << EOF
Usage: sh $0 command
  [Building]

  iOS           Build iOS framework
  native		Build using `swift build`
  clean         Clean up all un-neccesary files

  [Testing]

  test-iOS      Run tests on iOS host
  test-native	Run tests using `swift test`
EOF
}

COMMAND="$1"

case "$COMMAND" in
  "clean")
    find . -type d -name build -exec rm -r "{}" +\;
    exit 0;
  ;;

   "iOS" | "ios")
    xcodebuild clean \
    -project $PROJECT \
    -scheme "${SCHEME}" \
    -sdk "${IOS_SDK}" \
    -destination "${IOS_DESTINATION}" \
    -configuration Debug ONLY_ACTIVE_ARCH=YES \
    CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO \
    build | xcpretty -c
    exit 0;
  ;;

  "native" | "")
    swift build
    exit 0;
  ;;

   "test-iOS" | "test-ios")
    xcodebuild clean \
    -project $PROJECT \
    -scheme "${SCHEME}" \
    -sdk "${IOS_SDK}" \
    -destination "${IOS_DESTINATION}" \
    -configuration Release \
    ONLY_ACTIVE_ARCH=YES \
    CODE_SIGNING_REQUIRED=NO \
    ENABLE_TESTABILITY=YES \
    build test | xcpretty -c
    exit 0;
  ;;

  "test-native")
    swift package clean
    swift build
    swift test
    exit 0;
  ;;
esac

usage
