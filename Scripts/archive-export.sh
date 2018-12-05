#!/bin/sh

while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -a|--app)
    APP="$2"
    shift # past argument
    shift
    ;;
esac
done

DIR="$HOME/Desktop/dotdigital/Chat/Builds"
OBJC_DIR="$DIR/Objective-C"

cd ..

xcrun agvtool next-version -all

if [ "$APP" = "objc" ] || [ "$APP" = "o" ] || [ "$APP" = "" ]; then
    xcodebuild archive -workspace CMPComapiChat.xcworkspace -scheme ComapiChatSample -archivePath $OBJC_DIR/ComapiChatSample.xcarchive
    xcodebuild -exportArchive -archivePath $OBJC_DIR/ComapiChatSample.xcarchive -exportOptionsPlist ComapiChatSample/SampleExportOptions.plist -exportPath $OBJC_DIR
    
    echo "Exported .ipa bundle to $OBJC_DIR"
fi


