require_relative '../configs/base'
require_relative '../lib/context'

module UserInput
    def self.get_app(options)
        default = options[:app] || Context.lane_context[Context.sv::FL_APP]
        app = default || Context.UI.select("[app] Select app:", ["private", "public"])
        unless %w(private public).include?(app)
            Context.UI.user_error!("Invalid app: #{app}, Valid values are [private, public]")
        end
        Context.lane_context[Context.sv::FL_APP] = app
        app
    end

    def self.get_platform(options)
        default = options[:platform] || Context.lane_context[Context.sv::FL_PLATFORM]
        platform = default || Context.UI.select("[platform] Select build type:", ["both", "android", "ios"])
        unless %w(both ios android).include?(platform)
            Context.UI.user_error!("Invalid platform: #{platform}, Valid values are [both, android, ios]")
        end
        Context.lane_context[Context.sv::FL_PLATFORM] = platform
        platform
    end

    def self.get_env(options)
        default = options[:env] || Context.lane_context[Context.sv::FL_ENV]
        
        app = get_app(options)
        if app == "private" then
            env_options = ["prod", "stage", "demo", "dev"]
        else
            env_options = ["prod", "stage", "dev"]
        end

        env = default || Context.UI.select("[env] Select environment:", env_options)
        unless env_options.include?(env)
            Context.UI.user_error!("Invalid environment: #{env}, Valid values are #{env_options}")
        end
        Context.lane_context[Context.sv::FL_ENV] = env
        env
    end

    def self.get_android_artifacts(options)
        default = options[:artifacts] || Context.lane_context[Context.sv::FL_ARTIFACTS]
        artifact = default || Context.UI.select("[artifacts] Select artifacts:", ["fat_apk", "split_apk", "aab"])
        unless %w(fat_apk split_apk aab).include?(artifact)
            Context.UI.user_error!("Invalid artifacts: #{artifact}, Valid values are [fat_apk, split_apk, aab]")
        end
        Context.lane_context[Context.sv::FL_ARTIFACTS] = artifact
        artifact
    end

    def self.should_notify_teams?(options)
        return false if options[:skip_teams] == true || options[:skip_teams].to_s.downcase == 'true'
        return false if options[:notify_teams] == false || options[:notify_teams].to_s.downcase == 'false'
        return false if options[:teams] == false || options[:teams].to_s.downcase == 'false'
        true
    end
end