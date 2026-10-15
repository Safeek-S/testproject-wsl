require_relative '../lib/notification'
require_relative '../lib/teams'
require_relative '../lib/input'

module FirebaseBuilder
  def self.get_latest_build_number(app, platform, env)
    config = FastlaneConfig.get_app_config(app)
    service_credentials_file = "#{Context.lane_context[Context.sv::FL_PROJECT_ROOT]}/#{config[:service_account_path]}"
    platforms = platform == "both" ? ["android", "ios"] : [platform]

    build_numbers = []

    platforms.each do |p|
      app_id = config[p.to_sym][env.to_sym]
      if app_id.nil? || app_id.empty?
        Context.UI.important "Firebase App ID not configured for #{p} (#{env})"
        next
      end

      begin
        Context.UI.message "Fetching latest release from Firebase App Distribution for #{p} (#{env})..."
        release = Fastlane::Actions::FirebaseAppDistributionGetLatestReleaseAction.run(
          app: app_id,
          service_credentials_file: service_credentials_file
        )

        build_version = nil
        if release.is_a?(Hash)
          build_version = release[:buildVersion] || release['buildVersion'] || release[:build_version] || release['build_version']
        elsif release.respond_to?(:build_version)
          build_version = release.build_version
        end

        if build_version
          build_num = build_version.to_s.to_i
          Context.UI.message "Found latest raw build number on Firebase for #{p}: #{build_num}"

          # If Android and using split APK (e.g. private app), normalize Flutter's arm64-v8a (+2000) ABI offset
          artifacts = Context.lane_context[Context.sv::FL_ARTIFACTS]
          is_split_apk = (app == "private" || artifacts == "split_apk")
          if p == "android" && is_split_apk && build_num >= 2000
            normalized = build_num - 2000
            Context.UI.message "Normalized Android split APK build number: #{build_num} - 2000 = #{normalized}"
            build_num = normalized
          end

          build_numbers << build_num if build_num > 0
        else
          Context.UI.message "No previous release build version found on Firebase for #{p} (#{env})"
        end
      rescue => e
        Context.UI.important "Could not fetch latest release from Firebase for #{p} (#{env}): #{e.message}"
      end
    end

    build_numbers.max
  end

  def self.distribute(options)
    app = Context.lane_context[Context.sv::FL_APP]
    platform = Context.lane_context[Context.sv::FL_PLATFORM]
    env = Context.lane_context[Context.sv::FL_ENV]

    config = Context.app_config
    platforms = platform == "both" ? ["android", "ios"] : [platform]

    begin
      # 1. Retrieve release notes derived from Git commits since the last tag matching "#{app}/v*"
      release_notes = nil
      begin
        release_notes = Fastlane::Actions::ChangelogFromGitCommitsAction.run(
          pretty: "- %s",
          merge_commit_filtering: "exclude_merges",
          tag_match_pattern: "#{app}/v*"
        )
        Context.UI.message "Derived release notes from Git commits since last tag:\n#{release_notes}"
      rescue => e
        Context.UI.important "Could not derive release notes from commits: #{e.message}"
      end

      if release_notes.nil? || release_notes.empty?
        release_notes = "Distributed version #{Context.lane_context[Context.sv::FL_VERSION]} via Fastlane."
      end

      binary_links = {}

      # 2. Distribute each platform
      platforms.each do |p|
        app_id = config[p.to_sym][env.to_sym]

        if app_id.nil? || app_id.empty?
          Context.UI.error "App ID is empty for #{p} #{env}. Please check app config."
          next
        end

        service_credentials_file = "#{Context.lane_context[Context.sv::FL_PROJECT_ROOT]}/#{config[:service_account_path]}"
        
        release_res = nil
        if p == "android"
          file_path = "#{Context.get_output_directory}/#{Context.lane_context[:android_file_name]}"
          Context.UI.message "Distributing Android app to Firebase App Distribution..."
          
          release_res = Fastlane::Actions::FirebaseAppDistributionAction.run(
            app: app_id,
            service_credentials_file: service_credentials_file,
            groups: "scad-internal",
            android_artifact_type: "APK",
            android_artifact_path: file_path,
            release_notes: release_notes
          )
        elsif p == "ios"
          file_path = "#{Context.get_output_directory}/#{Context.lane_context[:ios_file_name]}"
          Context.UI.message "Distributing iOS app to Firebase App Distribution..."
          
          release_res = Fastlane::Actions::FirebaseAppDistributionAction.run(
            app: app_id,
            service_credentials_file: service_credentials_file,
            groups: "scad-internal",
            ipa_path: file_path,
            release_notes: release_notes
          )
        end

        distro_release = release_res || (defined?(Fastlane::Actions::SharedValues::FIREBASE_APP_DISTRO_RELEASE) ? Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::FIREBASE_APP_DISTRO_RELEASE] : nil)

        if distro_release.is_a?(Hash)
          bin_uri = distro_release[:binary_download_uri] || distro_release['binary_download_uri'] || distro_release[:binaryDownloadUri] || distro_release['binaryDownloadUri']
          test_uri = distro_release[:testing_uri] || distro_release['testing_uri'] || distro_release[:testingUri] || distro_release['testingUri']

          binary_links[p] = {
            binary_download_uri: bin_uri,
            testing_uri: test_uri
          }
        end
      end

      Notification.success("Distributed #{app} (#{platform} - #{env}) to Firebase")

      # Post to Microsoft Teams if enabled
      if UserInput.should_notify_teams?(options)
        TeamsNotifier.post_distribution(
          app: app,
          platform: platform,
          env: env,
          version: Context.lane_context[Context.sv::FL_VERSION],
          release_notes: release_notes,
          binary_links: binary_links
        )
      else
        Context.UI.message "Skipping Microsoft Teams notification as requested."
      end
    rescue => e
      Context.UI.error "Distribution Failed: #{e.message}"
      Notification.failure(e.message)
      raise e
    end
  end
end
