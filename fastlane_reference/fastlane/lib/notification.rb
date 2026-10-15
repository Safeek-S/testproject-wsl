module Notification 
    def self.success(message)
        system("osascript -e 'display notification \"#{message}\" with title \"✅ Success\"'")
        system("afplay #{Context.success_notification_sound}")
    end

    def self.failure(message)
        system("osascript -e 'display notification \"#{message}\" with title \"❌ Failure\"'")
        system("afplay #{Context.failed_notification_sound}")
    end
end