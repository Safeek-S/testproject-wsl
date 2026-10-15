module Git
    def self.tag_release(app)
        diff = `git diff`
        if diff.length > 0
            Context.UI.user_error! "There are uncommitted changes. Please commit them before cleanup"
        end
        
        pubspec_path = "#{Context.get_app_directory}/#{FastlaneConfig::PUBSPEC_FILE}" 
        pubspec_version = Utils.get_pubspec_version(pubspec_path)

        changelog_file = "#{Context.get_app_directory}/#{FastlaneConfig::CHANGE_LOGS_FILE}"
        result = Utils.get_latest_change_log(changelog_file)
        
        latest_changelog_version = result[:version]
        
        version, _ = pubspec_version.split('+')
        if ("v#{version}" != latest_changelog_version)
            Context.UI.user_error! "Version mismatch: Latest CHANGE_LOGS version #{latest_changelog_version} does not match with pubspec version #{version}"
        end

        change_logs = result[:changes]
        
        Context.UI.message "Latest Version: #{version}"
        Context.UI.message "Latest Changes:\n#{change_logs}"
        
        # Create git tag with version and changes in description
        tag_name = "#{app}/v#{version}"
        system("git tag -a #{tag_name} -m '#{change_logs}'")
        system("git push origin tag #{tag_name}")

        Context.UI.success "Tagged release: #{tag_name}"
    end
end