fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### code_gen

```sh
[bundle exec] fastlane code_gen
```

Run build_runner and easy_localization code generation commands

### lang_gen

```sh
[bundle exec] fastlane lang_gen
```

Run easy_localization code generation commands

### build

```sh
[bundle exec] fastlane build
```

Build releases with Flutter (supports mode: fast|full|clean)

### clean_deps

```sh
[bundle exec] fastlane clean_deps
```

Clean install flutter dependencies & run pod updates

### tag_release

```sh
[bundle exec] fastlane tag_release
```

Tag release with version and changes from CHANGE_LOGS.md

### distribute

```sh
[bundle exec] fastlane distribute
```

Build and distribute to Firebase App Distribution (supports mode: fast|full|clean, skip_teams: true, skip_bump: true)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
