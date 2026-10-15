require_relative '../configs/base'
require_relative '../lib/utils'
require_relative 'android'
require_relative 'ios'

module FlutterBuilder
    include FastlaneConfig

    def self.language_gen
        Context.UI.message "Running easy_localization code generation"

        Dir.chdir(Context.get_app_directory) do
            system <<~CMD
            dart run easy_localization:generate \
                --source-dir assets/translations \
                --output-dir lib/translations
            CMD

            system <<~CMD
            dart run easy_localization:generate \
                --source-dir assets/translations \
                --output-dir lib/translations \
                --output-file locale_keys.g.dart \
                --format keys
            CMD
        end
    end

    def self.prebuild_setup(options = {})
        mode = (options[:mode] || (options[:clean] ? "clean" : "fast")).to_s.downcase

        case mode
        when "clean"
            Context.UI.message "Mode: clean (Running flutter clean, pub get, and code generation)..."
            system('flutter clean')
            system('flutter pub get')
            system <<~CMD
              dart run build_runner build \
                --delete-conflicting-outputs
            CMD
            language_gen
        when "full", "codegen"
            Context.UI.message "Mode: full (Running code generation & localization)..."
            system <<~CMD
              dart run build_runner build \
                --delete-conflicting-outputs
            CMD
            language_gen
        else # "fast" (default)
            Context.UI.message "Mode: fast (Skipping clean & code generation for quick incremental build)..."
        end

        Context.UI.success "Prebuild setup completed"
    end

    def self.code_generation(app)
        Context.UI.message "Running code generation for #{app} app"

        Dir.chdir(Context.get_app_directory) do
            system <<~CMD
              dart run build_runner build \
                --delete-conflicting-outputs
            CMD

            language_gen
        end

        Context.UI.success "Code generation completed"
    end

    def self.build(options)
        Context.UI.message "Initialising build process..."

        # Get platform from options
        platform = UserInput.get_platform(options)

        # Get android artifacts if building for android
        if %w(both android).include?(platform)
            UserInput.get_android_artifacts(options)
        end

        # Sets environment, version and iteration to lane context
        Context.set_env(options)
        Context.set_version
        Context.set_iteration

        # Ensure output directory exists
        Utils.ensure_output_directory

        Dir.chdir(Context.get_app_directory) do
            prebuild_setup(options)
        end
        
        built_files = []
        
        begin
            case platform
            when "both"
                Context.UI.message "Building for Android 🤖 & iOS 🍎"
                
                # Building for Android
                android_file = AndroidBuilder.build_artifacts
                Context.lane_context[:android_file_name] = android_file

                # Building for iOS
                ios_file = IOSBuilder.build_xcarchive(options)
                Context.lane_context[:ios_file_name] = ios_file

                built_files = [android_file, ios_file].compact
            when "android"
                Context.UI.message "Building for Android 🤖"
                android_file = AndroidBuilder.build_artifacts
                built_files = [android_file].compact

                Context.lane_context[:android_file_name] = android_file
            when "ios"
                Context.UI.message "Building for iOS 🍎"
                ios_file = IOSBuilder.build_xcarchive(options)
                built_files = [ios_file].compact

                Context.lane_context[:ios_file_name] = ios_file
            else
                FastlaneCore::UI.error "Unimplemented platform: #{platform}"
            end

            Context.UI.success "Build complete"
            
            # Show success notification unless suppressed (e.g. during distribute lane)
            notify = options[:notify] != false && options[:notify] != "false"
            if notify
                file_list = built_files.empty? ? "No files generated" : built_files.join(", ")
                Notification.success(file_list)
            end
        rescue => e
            Context.UI.error "Build Failed: #{e.message}"
            
            Notification.failure(e.message)
            raise e
        end

        Context.save_iteration
    end

    def self.clean_deps(app)
        Context.UI.message "Cleaning dependencies for #{app} app"

        Dir.chdir(Context.get_app_directory) do
            system('dart pub cache clean')
            system('flutter pub get')

            app = Context.lane_context[Context.sv::FL_APP]
            if app == 'private' then
                Context.UI.message "Installing arcgis_maps package"
                system('flutter pub run arcgis_maps install')
            end

            Dir.chdir('ios') do
                system('pod repo update')
                system('pod update')
            end
        end
    end
end