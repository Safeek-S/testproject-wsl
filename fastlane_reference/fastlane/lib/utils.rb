require_relative '../configs/base'
require_relative 'context'

module Utils
    include FastlaneConfig

    def self.get_date
        now = DateTime.now
        "#{Date::ABBR_MONTHNAMES[now.month].downcase}-#{now.day}"
    end

    def self.get_pubspec_version(pubspec_path)
        content = File.read(pubspec_path)
        require 'yaml'
        data = YAML.safe_load(content)
        return data["version"]
    end

    def self.update_pubspec_version(pubspec_path, new_version)
        raise "pubspec.yaml not found at #{pubspec_path}" unless File.exist?(pubspec_path)
        content = File.read(pubspec_path)
        unless content =~ /^version:\s*.+$/
            raise "Could not find 'version:' line in #{pubspec_path}"
        end
        updated_content = content.sub(/^version:\s*.+$/, "version: #{new_version}")
        File.write(pubspec_path, updated_content)
        FastlaneCore::UI.success "Updated #{pubspec_path} version to #{new_version}"
    end

    def self.ensure_output_directory
        app = Context.lane_context[Context.sv::FL_APP]
        app_config = FastlaneConfig.get_app_config(app)
        output_path = app_config[:output_path]

        # Get project root
        root = Context.lane_context[Context.sv::FL_PROJECT_ROOT]
        output_path = "#{root}/#{output_path}"

        # Ensure output directory exists
        FileUtils.mkdir_p(output_path) unless Dir.exist?(output_path)
        Context.UI.success "Output directory ready: #{output_path}"
    end

    def self.get_release_file_name(prefix, extension)
        env = Context.lane_context[Context.sv::FL_ENV]
        version = Context.lane_context[Context.sv::FL_VERSION]
        date = Utils.get_date
        iteration = Context.lane_context[Context.sv::FL_ITERATION]
        return "#{prefix}_#{env}_#{version}_#{date}_#{iteration}.#{extension}"
    end

    def self.copy_file(source_path, target_path)
        if File.exist?(source_path)
            FileUtils.copy_file(source_path, target_path)
            Context.UI.success "Moved artifact to output directory"
        else
            raise "Source file not found: #{source_path}"
        end
    end

    def self.copy_xcarchive(source_path, target_path)
        if File.exist?(source_path)
            FileUtils.cp_r(source_path, target_path)
            Context.UI.success "Moved artifact to output directory"
        else
            Context.UI.error "Source file not found: #{source_path}"
        end
    end
    
    def self.get_latest_change_log(changelog_file)
        Context.UI.message "Extracting latest change logs from #{changelog_file}"

        latest_version = nil
        latest_changes = []

        File.open(changelog_file, 'r') do |file|
            file.each_line do |line|
            if line =~ /^## v\d+\.\d+\.\d+/
                break if latest_version
                latest_version = line.strip.gsub(/^##\s? /, '')
            elsif latest_version
                next if line.strip.empty?
                latest_changes << line.strip.gsub(/\*+$/, '')
            end
          end
        end

        changes = latest_changes.join("\n")

        { version: latest_version, changes: changes }
    end
end