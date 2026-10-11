#!/usr/bin/env bash
# Script tự động giải mã và cài đặt chứng chỉ iOS với mật khẩu: 1
set -e
echo "Configuring iOS Keychain with imported certificate..."
mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles

# Giải mã Provisioning Profile
if [ -n "$BUILD_PROVISION_PROFILE_BASE64" ]; then
  echo "$BUILD_PROVISION_PROFILE_BASE64" | base64 --decode > ~/Library/MobileDevice/Provisioning\ Profiles/cert.mobileprovision
elif [ -f "ci_certs/cert_provision.b64" ]; then
  cat "ci_certs/cert_provision.b64" | base64 --decode > ~/Library/MobileDevice/Provisioning\ Profiles/cert.mobileprovision
fi

# Tạo keychain với mật khẩu: 1
KEYCHAIN_PATH=$RUNNER_TEMP/build.keychain
security create-keychain -p "1" $KEYCHAIN_PATH
security set-keychain-settings -lut 21600 $KEYCHAIN_PATH
security unlock-keychain -p "1" $KEYCHAIN_PATH

# Giải mã và Import cert.p12 với mật khẩu: 1
if [ -n "$BUILD_CERTIFICATE_BASE64" ]; then
  echo "$BUILD_CERTIFICATE_BASE64" | base64 --decode > $RUNNER_TEMP/cert.p12
elif [ -f "ci_certs/cert_p12.b64" ]; then
  cat "ci_certs/cert_p12.b64" | base64 --decode > $RUNNER_TEMP/cert.p12
fi

if [ -f "$RUNNER_TEMP/cert.p12" ]; then
  security import "$RUNNER_TEMP/cert.p12" -P "1" -A -t cert -f pkcs12 -k $KEYCHAIN_PATH || true
  security set-key-partition-list -S apple-tool:,apple: -s -k "1" $KEYCHAIN_PATH || true
  security list-keychain -d user -s $KEYCHAIN_PATH
fi
echo "Certificate setup complete."
