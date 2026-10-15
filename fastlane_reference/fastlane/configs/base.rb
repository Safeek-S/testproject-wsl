module FastlaneConfig
    # Shared constants across all apps
    PUBSPEC_FILE = "pubspec.yaml"
    CHANGE_LOGS_FILE = "CHANGE_LOGS.md"
  
    # Android build paths
    APK_PATH = "build/app/outputs/flutter-apk"
    AAB_PATH = "build/app/outputs/bundle/release"
    SPLIT_APK_PATH = "build/app/outputs/flutter-apk"
    
    # iOS build paths
    XC_PATH = "build/ios/archive"
    IPA_PATH = "build/ios/ipa"
    
    # Output file names
    APK_FILE_NAME = "app-release.apk"
    AAB_FILE_NAME = "app-release.aab"

    ARM64_V8_FILE_NAME = "app-arm64-v8a-release.apk"
    ARMEABI_V7_FILE_NAME = "app-armeabi-v7a-release.apk"
    X86_64_FILE_NAME = "app-x86_64-release.apk"

    XC_FILE_NAME = "Runner.xcarchive"

    # Iteration cache file
    ITERATION_FILE = "iteration.yaml"

    # Teams notification config file
    TEAMS_CONFIG_FILE = ".secret/teams_config.json"

    # Shared module for SharedValues
    module SharedValues
        FL_APP = :FL_APP
        FL_PROJECT_ROOT = :FL_PROJECT_ROOT

        FL_PLATFORM = :FL_PLATFORM
        FL_ENV = :FL_ENV
        FL_ENV_FILE = :FL_ENV_FILE

        FL_ARTIFACTS = :FL_ARTIFACTS
        FL_VERSION = :FL_VERSION
        FL_ITERATION = :FL_ITERATION
    end

    def self.get_app_config(app)
        case app
        when 'private'
            require_relative 'private'
            FastlaneConfig::Private.config
        when 'public'
            require_relative 'public'
            FastlaneConfig::Public.config
        else
            FastlaneCore::UI.user_error!("Invalid app: #{app}. Valid options: private, public")
        end
    end
end