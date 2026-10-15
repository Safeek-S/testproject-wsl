require_relative 'base'

module FastlaneConfig
	module Public
		APP_DIRECTORY = "apps/public"
		APP_PREFIX = "bayaan_public"
		SECRET_PATH = "../../.secret/public/environment"

		SERVICE_ACCOUNT_PATH = ".secret/public/serviceAccountKey.json"

		OUTPUT_PATH = "output/public"

		ANDROID_PACKAGE_NAME = "ae.gov.scad.bayaan.open"
		IOS_PACKAGE_NAME = "ae.gov.scad.bayaan.open"

		AND_FB_APP_ID_DEV = "1:905007265822:android:044d26d33b47b19ff7160f"
		AND_FB_APP_ID_STAGE = "1:905007265822:android:10d5b8d5eeb7833df7160f"
		AND_FB_APP_ID_PROD = "1:905007265822:android:ffb58ddc3f67e466f7160f"

		IOS_FB_APP_ID_DEV = "1:905007265822:ios:21779d613a201696f7160f"
		IOS_FB_APP_ID_STAGE = "1:905007265822:ios:0e06fa948757a11cf7160f"
		IOS_FB_APP_ID_PROD = "1:905007265822:ios:4669a2195dda18a8f7160f"

        IPA_FILE_NAME = "bayaanopen.ipa"

		def self.config
		{
			app_directory: APP_DIRECTORY,
			app_prefix: APP_PREFIX,
			secret_path: SECRET_PATH,
			output_path: OUTPUT_PATH,
			android_package_name: ANDROID_PACKAGE_NAME,
			ios_package_name: IOS_PACKAGE_NAME,
            service_account_path: SERVICE_ACCOUNT_PATH,
			android: {
                dev: AND_FB_APP_ID_DEV,
                stage: AND_FB_APP_ID_STAGE,
                prod: AND_FB_APP_ID_PROD,
			},
			ios: {
                dev: IOS_FB_APP_ID_DEV,
                stage: IOS_FB_APP_ID_STAGE,
                prod: IOS_FB_APP_ID_PROD,
			},
            ipa_file_name: IPA_FILE_NAME,
		}
		end
	end
end
