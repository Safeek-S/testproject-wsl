module AndroidBuilder
    def self.app_config
        app = Context.lane_context[Context.sv::FL_APP]
        FastlaneConfig.get_app_config(app)
    end

    def self.build_artifacts
        artifacts = Context.lane_context[Context.sv::FL_ARTIFACTS]
        raise "[artifacts] not set" unless artifacts

        Dir.chdir("../#{app_config[:app_directory]}") do
            case artifacts
            when "split_apk"
                return build_split_apk
            when "fat_apk"
                return build_apk
            when "aab"
                return build_aab
            else
                Context.UI.user_error! "Invalid artifacts selection: #{artifacts}"
            end
        end
    end

    def self.build_split_apk
        prefix = app_config[:app_prefix]
        env = Context.lane_context[Context.sv::FL_ENV]
        Context.UI.message "Building split APK for #{prefix} - #{env}"

        success = system <<~CMD
          flutter build apk \
            --release \
            --split-per-abi \
            --flavor=#{env} \
            --dart-define-from-file=#{Context.get_env_path}
        CMD
        raise "Flutter Android split APK build failed" unless success

        file_name = Utils.get_release_file_name("#{prefix}_arm64_v8", "apk")

        # Source file name changes with flavor: app-arm64-v8a-#{env}-release.apk
        source_file = "app-arm64-v8a-#{env}-release.apk"
        source_path = "#{Context.get_app_directory}/#{FastlaneConfig::APK_PATH}/#{source_file}"
        target_path = "#{Context.get_output_directory}/#{file_name}"

        Utils.copy_file(source_path, target_path)
        return file_name
    end

    def self.build_apk
        prefix = app_config[:app_prefix]
        env = Context.lane_context[Context.sv::FL_ENV]
        Context.UI.message "Building fat APK for #{prefix} - #{env}"

        success = system <<~CMD
          flutter build apk \
            --release \
            --flavor=#{env} \
            --dart-define-from-file=#{Context.get_env_path}
        CMD
        raise "Flutter Android APK build failed" unless success

        file_name = Utils.get_release_file_name(prefix, "apk")

        # Source file name changes with flavor: app-#{env}-release.apk
        source_file = "app-#{env}-release.apk"
        source_path = "#{Context.get_app_directory}/#{FastlaneConfig::APK_PATH}/#{source_file}"
        target_path = "#{Context.get_output_directory}/#{file_name}"

        Utils.copy_file(source_path, target_path)
        return file_name
    end

    def self.build_aab
        prefix = app_config[:app_prefix]
        env = Context.lane_context[Context.sv::FL_ENV]
        Context.UI.message "Building AAB for #{prefix} - #{env}"

        success = system <<~CMD
          flutter build appbundle \
            --release \
            --flavor=#{env} \
            --dart-define-from-file=#{Context.get_env_path}
        CMD
        raise "Flutter Android AAB build failed" unless success

        file_name = Utils.get_release_file_name(prefix, "aab")

        # For flavored AABs, the path includes the variant name in camelCase
        # e.g., build/app/outputs/bundle/devRelease/app-dev-release.aab
        variant_name = "#{env}Release"
        source_file = "app-#{env}-release.aab"
        bundle_base_path = "build/app/outputs/bundle"
        
        source_path = "#{Context.get_app_directory}/#{bundle_base_path}/#{variant_name}/#{source_file}"
        target_path = "#{Context.get_output_directory}/#{file_name}"

        Utils.copy_file(source_path, target_path)
        return file_name
    end
end