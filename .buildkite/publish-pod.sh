#!/bin/bash -eu

PODSPEC_PATH="WPMediaPicker.podspec"
SLACK_WEBHOOK=$PODS_SLACK_WEBHOOK

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :cocoapods: Publishing Pod to CocoaPods CDN"
publish_pod $PODSPEC_PATH

echo "--- :slack: Notifying Slack"
slack_notify_pod_published $PODSPEC_PATH "$SLACK_WEBHOOK"
