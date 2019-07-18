#!/bin/sh

pod cache clean --all
pod deintegrate
pod install

xcodebuild clean -workspace CMPComapiChat.xcworkspace -scheme ComapiChatSample
xcodebuild build -workspace CMPComapiChat.xcworkspace -scheme ComapiChatSample

xcodebuild clean -workspace CMPComapiChat.xcworkspace -scheme CMPComapiChat
xcodebuild test -workspace CMPComapiChat.xcworkspace -scheme CMPComapiChatTests
