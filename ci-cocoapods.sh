#!/bin/sh

pod cache clean --all
pod deintegrate
pod install
