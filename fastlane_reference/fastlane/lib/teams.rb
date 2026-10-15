require 'net/http'
require 'uri'
require 'json'
require_relative '../configs/base'
require_relative 'context'
require_relative 'utils'

module TeamsNotifier
  def self.get_webhook_url
    project_root = Context.lane_context[Context.sv::FL_PROJECT_ROOT] || Dir.pwd
    config_file_path = File.join(project_root, FastlaneConfig::TEAMS_CONFIG_FILE)

    unless File.exist?(config_file_path)
      Context.UI.important "Teams config file not found at: #{config_file_path}"
      return nil
    end

    begin
      content = File.read(config_file_path)
      data = JSON.parse(content)
      webhook_url = data['webhook_url']

      if webhook_url.nil? || webhook_url.strip.empty? || webhook_url.include?('YOUR_TEAMS_WEBHOOK_URL_HERE')
        Context.UI.important "Teams webhook_url is empty or unset in: #{config_file_path}"
        return nil
      end

      webhook_url.strip
    rescue JSON::ParserError => e
      Context.UI.error "Failed to parse Teams config JSON: #{e.message}"
      nil
    rescue => e
      Context.UI.error "Error reading Teams config: #{e.message}"
      nil
    end
  end

  def self.format_app_name(app)
    case app.to_s.downcase
    when 'private'
      'Bayaan Gov'
    when 'public'
      'Bayaan Public'
    else
      app.to_s.capitalize
    end
  end

  def self.format_environment(env)
    case env.to_s.downcase
    when 'dev'
      '🟡 DEV'
    when 'stage'
      '🔵 STAGE'
    when 'demo'
      '🟣 DEMO'
    when 'prod'
      '🟢 PROD'
    else
      env.to_s.upcase
    end
  end

  def self.format_platform(platform)
    case platform.to_s.downcase
    when 'both'
      '🤖 Android & 🍎 iOS'
    when 'android'
      '🤖 Android'
    when 'ios'
      '🍎 iOS'
    else
      platform.to_s
    end
  end

  def self.build_card_payload(app:, env:, platform:, version:, release_notes:, binary_links: {})
    app_name = format_app_name(app)
    env_badge = format_environment(env)
    platform_text = format_platform(platform)
    version_text = version.to_s.empty? ? 'N/A' : version.to_s
    notes_text = (release_notes.nil? || release_notes.to_s.strip.empty?) ? 'No release notes provided.' : release_notes.to_s.strip

    card_body = [
      {
        "type" => "TextBlock",
        "size" => "Large",
        "weight" => "Bolder",
        "text" => "🚀 Bayaan Mobile Distributed",
        "style" => "heading"
      },
      {
        "type" => "FactSet",
        "facts" => [
          { "title" => "App", "value" => app_name },
          { "title" => "Environment", "value" => env_badge },
          { "title" => "Platform", "value" => platform_text },
          { "title" => "Version", "value" => version_text }
        ]
      }
    ]

    # Add release notes section
    card_body << {
      "type" => "TextBlock",
      "text" => "**📋 Release Notes:**",
      "weight" => "Bolder",
      "spacing" => "Medium"
    }
    card_body << {
      "type" => "TextBlock",
      "text" => notes_text,
      "wrap" => true
    }

    # Build action buttons (Action.OpenUrl) for App Tester
    actions = []
    if binary_links && !binary_links.empty?
      has_multiple = binary_links.keys.length > 1
      binary_links.each do |plt, info|
        test_uri = nil
        if info.is_a?(Hash)
          test_uri = info[:testing_uri] || info[:testingUri] || info['testing_uri'] || info['testingUri']
        elsif info.is_a?(String)
          test_uri = info
        end

        next if test_uri.nil? || test_uri.to_s.strip.empty?

        button_title = if has_multiple
          plt_name = plt.to_s.downcase == 'android' ? 'Android' : (plt.to_s.downcase == 'ios' ? 'iOS' : plt.to_s.capitalize)
          "Open in App Tester (#{plt_name})"
        else
          "Open in App Tester"
        end

        actions << {
          "type" => "Action.OpenUrl",
          "title" => button_title,
          "url" => test_uri
        }
      end
    end

    card_content = {
      "$schema" => "http://adaptivecards.io/schemas/adaptive-card.json",
      "type" => "AdaptiveCard",
      "version" => "1.4",
      "body" => card_body
    }
    card_content["actions"] = actions unless actions.empty?

    {
      "type" => "message",
      "attachments" => [
        {
          "contentType" => "application/vnd.microsoft.card.adaptive",
          "contentUrl" => nil,
          "content" => card_content
        }
      ]
    }
  end

  def self.post_distribution(app:, platform:, env:, version:, release_notes:, binary_links: {})
    webhook_url = get_webhook_url
    if webhook_url.nil?
      Context.UI.important "Skipping Teams notification because webhook URL is not configured."
      return
    end

    Context.UI.message "Posting distribution notification to Microsoft Teams..."

    begin
      payload = build_card_payload(
        app: app,
        env: env,
        platform: platform,
        version: version,
        release_notes: release_notes,
        binary_links: binary_links
      )

      uri = URI.parse(webhook_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.open_timeout = 10
      http.read_timeout = 10

      request = Net::HTTP::Post.new(uri.request_uri, { 'Content-Type' => 'application/json' })
      request.body = payload.to_json

      response = http.request(request)

      if response.code.to_i.between?(200, 299)
        Context.UI.success "✅ Successfully posted distribution notification to Microsoft Teams"
      else
        Context.UI.important "⚠️ Microsoft Teams webhook returned HTTP #{response.code}: #{response.body}"
      end
    rescue => e
      Context.UI.important "⚠️ Failed to post notification to Microsoft Teams: #{e.message}"
    end
  end
end
