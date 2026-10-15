module IOSBuilder
    def self.app_config
        app = Context.lane_context[Context.sv::FL_APP]
        FastlaneConfig.get_app_config(app)
    end

	def self.build_xcarchive(options = {})
		prefix = Context.lane_context[Context.sv::FL_APP]
		Context.UI.message "Building iOS xcarchive for #{prefix}"
		
		mode = (options[:mode] || (options[:clean] ? "clean" : "fast")).to_s.downcase
		should_pod_install = (mode == "clean" || mode == "full" || options[:pod_install] == true || options[:pod_install] == "true") && options[:skip_pod_install] != true && options[:skip_pod_install] != "true"

		# Install CocoaPods dependencies
		if should_pod_install
			Context.UI.message "Installing CocoaPods dependencies"
			ios_dir = "#{Context.get_app_directory}/ios"
			Dir.chdir(ios_dir) do
				success = system("pod install")
				raise "CocoaPods install failed" unless success
			end
		else
			Context.UI.message "Skipping CocoaPods install"
		end

		# Clean previous IPA build directory to avoid copying stale artifacts if export fails
		ipa_dir = "#{Context.get_app_directory}/#{FastlaneConfig::IPA_PATH}"
		FileUtils.rm_rf(ipa_dir) if Dir.exist?(ipa_dir)

		# Build and export IPA (default export-method: ad-hoc for Firebase App Distribution)
		Dir.chdir(Context.get_app_directory) do
			env = Context.lane_context[Context.sv::FL_ENV]
			export_method = options[:export_method] || "ad-hoc"
			Context.UI.message "Exporting IPA with method: #{export_method}"

			system <<~CMD
				flutter build ipa \
					--release \
					--flavor=#{env} \
					--export-method=#{export_method} \
					--dart-define-from-file=#{Context.get_env_path}
			CMD
		end

		# Copy xcarchive to output directory if generated
		file_name = Utils.get_release_file_name("Runner", "xcarchive")
		source_path = "#{Context.get_app_directory}/#{FastlaneConfig::XC_PATH}/#{FastlaneConfig::XC_FILE_NAME}"
		target_path = "#{Context.get_output_directory}/#{file_name}"

		if File.exist?(source_path)
			Utils.copy_xcarchive(source_path, target_path)
			Context.UI.success "iOS xcarchive saved to: #{target_path}"
		end

		# Verify and copy newly generated IPA file
		source_ipa = "#{Context.get_app_directory}/#{FastlaneConfig::IPA_PATH}/#{app_config[:ipa_file_name]}"
		ipa_file_name = Utils.get_release_file_name(app_config[:app_prefix], "ipa")
		target_ipa = "#{Context.get_output_directory}/#{ipa_file_name}"

		unless File.exist?(source_ipa)
			error_msg = [
				"❌ IPA generation/export failed.",
				File.exist?(target_path) ? "The xcarchive was saved to: #{target_path}" : nil,
				File.exist?(target_path) ? "You can distribute manually via Xcode: open \"#{target_path}\"" : nil
			].compact.join("\n")

			Context.UI.error error_msg
			raise "Flutter IPA export failed (no IPA found at #{source_ipa})."
		end

		Utils.copy_file(source_ipa, target_ipa)
		Context.UI.success "iOS IPA saved to: #{target_ipa}"
		return ipa_file_name
	end
end