require_relative '../configs/base'
require_relative 'utils'

module Context
    include FastlaneConfig

    def self.sv
        FastlaneConfig::SharedValues
    end

    def self.UI
        FastlaneCore::UI
    end

    def self.lane_context
        Fastlane::Actions.lane_context
    end
    
    def self.success_notification_sound
        "#{lane_context[sv::FL_PROJECT_ROOT]}/fastlane/sounds/build-success.mp3"
    end

    def self.failed_notification_sound
        "#{lane_context[sv::FL_PROJECT_ROOT]}/fastlane/sounds/build-failed.mp3"
    end

    def self.app_config
        app = lane_context[sv::FL_APP]
        FastlaneConfig.get_app_config(app)
    end

    def self.get_env_path
        env_file = lane_context[sv::FL_ENV_FILE]
        secret_path = app_config[:secret_path]
        return "#{secret_path}/#{env_file}"
    end

    def self.save_project_root(pwd)
        lane_context[sv::FL_PROJECT_ROOT] = pwd
        self.UI.success "Project root set: #{pwd}"
    end

    def self.get_app_directory
        root = lane_context[sv::FL_PROJECT_ROOT]
        return "#{root}/#{app_config[:app_directory]}"
    end

    def self.get_output_directory
        project_root = lane_context[sv::FL_PROJECT_ROOT]
        return "#{project_root}/#{app_config[:output_path]}"
    end

    def self.set_env(options)
        env = UserInput.get_env(options)
        file = "#{env}.json"
        lane_context[sv::FL_ENV_FILE] = file
        self.UI.success "Env file set: #{file}"
    end

    def self.set_version
        pubspec_path = "#{get_app_directory}/#{FastlaneConfig::PUBSPEC_FILE}"
        version = Utils.get_pubspec_version(pubspec_path)
        lane_context[sv::FL_VERSION] = version
        self.UI.success "Version set to: #{version}"
    end

    def self.bump_build_number_from_firebase(options = {})
        require_relative '../builders/firebase'

        app = lane_context[sv::FL_APP]
        platform = lane_context[sv::FL_PLATFORM]
        env = lane_context[sv::FL_ENV]

        pubspec_path = "#{get_app_directory}/#{FastlaneConfig::PUBSPEC_FILE}"
        current_version_str = Utils.get_pubspec_version(pubspec_path)
        
        # Split version name and build number, e.g. "1.0.18+35" => "1.0.18", "35"
        version_parts = current_version_str.split('+')
        version_name = version_parts[0]
        pubspec_build = (version_parts[1] || "0").to_i

        skip_bump = options[:skip_bump] == true || options[:skip_bump].to_s.downcase == 'true' || options[:bump] == false || options[:bump].to_s.downcase == 'false'
        if skip_bump
            lane_context[sv::FL_VERSION] = current_version_str
            self.UI.message "Skipping build number bump as requested. Using current version: #{current_version_str}"
            return current_version_str
        end

        # Query Firebase App Distribution for the latest build number
        latest_fb_build = FirebaseBuilder.get_latest_build_number(app, platform, env)
        
        base_build = [latest_fb_build || 0, pubspec_build].max
        new_build = base_build + 1

        new_version_str = "#{version_name}+#{new_build}"
        Utils.update_pubspec_version(pubspec_path, new_version_str)

        lane_context[sv::FL_VERSION] = new_version_str
        if latest_fb_build
            self.UI.success "Latest Firebase build was #{latest_fb_build}. Auto-incremented version to: #{new_version_str}"
        else
            self.UI.success "No Firebase build found. Auto-incremented from pubspec to: #{new_version_str}"
        end

        new_version_str
    end

    def self.set_iteration
        current = 0
        
        if File.exist?(ITERATION_FILE)
            content = File.read(ITERATION_FILE)
            require 'yaml'
            data = YAML.safe_load(content)
            app = lane_context[sv::FL_APP]
            current = data&.fetch(app, {})&.fetch(Utils.get_date, 0) || 0
        end

        iteration = current + 1
        if iteration <= current
            self.UI.error "Sorry, this iteration (#{iteration}) is already built. Current: #{current}. Try next number."
            iteration = current + 1
        end

        lane_context[sv::FL_ITERATION] = iteration
        self.UI.success "Iteration set to: #{iteration}"
    end

    def self.save_iteration
        iteration = lane_context[sv::FL_ITERATION]
        return unless iteration
        
        # Ensure the directory exists
        dir = File.dirname(ITERATION_FILE)
        Dir.mkdir(dir) unless Dir.exist?(dir)
        
        require 'yaml'
        app = lane_context[sv::FL_APP]
        date = Utils.get_date
        data = {}
        if File.exist?(ITERATION_FILE)
            content = File.read(ITERATION_FILE)
            data = YAML.safe_load(content) || {}
        end

        data[app] ||= {}
        data[app][date] = iteration

        File.open(ITERATION_FILE, "w") { |f| f.write(data.to_yaml) }
        self.UI.success "Iteration #{iteration} saved to #{ITERATION_FILE}"
    end
end