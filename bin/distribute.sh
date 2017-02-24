#!/bin/bash

name="hellonature"
workspace="${name}.xcworkspace"
scheme=$name
configuration="Release"
archive_path="${name}.xcarchive"
ipa_path="${name}.ipa"
# make sure that this provisioning profile and its key are in the machine keychain
provisioning_profile="XC_iOS_nethellonatureios.mobileprovision"

# remove any previous artifact, or xcodebuild will not proceed
rm -rf $archive_path
rm -rf $ipa_path

# create archive
xcrun xcodebuild \
  -workspace "$workspace" \
  -scheme "$scheme" \
  -configuration "$configuration" \
  -sdk iphoneos \
  -destination generic/platform=iOS \
  -archivePath "$archive_path" \
  clean archive \
#  | bundle exec xcpretty -c

# export into ipa
xcrun xcodebuild \
  -exportArchive \
  -exportFormat IPA \
  -archivePath "$archive_path" \
  -exportPath "$ipa_path" \
  -exportProvisioningProfile "$provisioning_profile" \
#  | bundle exec xcpretty -c

# submit to TestFlight
# username and password are picked from the .env file
# env $(cat .env | grep -v "#" | xargs) bundle exec deliver testflight "$ipa_path"
