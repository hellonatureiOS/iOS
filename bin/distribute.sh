#!/bin/bash
xcodebuild -exportArchive -exportOptionsPlist app.plist  -archivePath app.xcarchive -exportPath app.ipa
