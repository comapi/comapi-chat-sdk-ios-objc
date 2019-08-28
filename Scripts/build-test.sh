#!/bin/sh

xcodebuild clean analyze -workspace CMPComapiChat.xcworkspace -scheme CMPComapiChat
xcodebuild build -workspace CMPComapiChat.xcworkspace -scheme CMPComapiChat
xcodebuild test -workspace CMPComapiChat.xcworkspace -scheme CMPComapiChatTests -destination 'platform=iOS Simulator,name=iPhone SE'