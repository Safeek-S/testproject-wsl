fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios build

```sh
[bundle exec] fastlane ios build
```

Build signed iOS IPA

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Release IPA (from ios-linux/runner.ipa) to TestFlight

### ios release

```sh
[bundle exec] fastlane ios release
```

Release IPA (from ios-linux/runner.ipa) to App Store

----


## Android

### android build

```sh
[bundle exec] fastlane android build
```

Build Flutter Android App Bundle (AAB) with --dart-define-from-file=env.json

### android build_apk

```sh
[bundle exec] fastlane android build_apk
```

Build Flutter Android APK with --dart-define-from-file=env.json

### android beta

```sh
[bundle exec] fastlane android beta
```

Build and upload AAB to Google Play Internal Testing

### android release

```sh
[bundle exec] fastlane android release
```

Build and upload AAB to Google Play Production

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
