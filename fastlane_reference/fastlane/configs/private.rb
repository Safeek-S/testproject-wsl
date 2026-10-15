require_relative 'base'

module FastlaneConfig
    module Private
        APP_DIRECTORY = "apps/private"
        APP_PREFIX = "bayaan_private"
        SECRET_PATH = "../../.secret/private/environment"

        SERVICE_ACCOUNT_PATH = ".secret/private/serviceAccountKey.json"

        OUTPUT_PATH = "output/private"

        ANDROID_PACKAGE_NAME = "ae.gov.scad.adstatapp"
        IOS_PACKAGE_NAME = "ae.gov.scad.adstatapp"

        AND_FB_APP_ID_DEV = "1:782838202525:android:1ea03f63ddd1a2975ed474"
        AND_FB_APP_ID_DEMO = "1:782838202525:android:f39d7ebbccf8c5945ed474"
        AND_FB_APP_ID_STAGE = "1:782838202525:android:64659bb394527a285ed474"
        AND_FB_APP_ID_PROD = "1:782838202525:android:e28898439b6a53735ed474"

        IOS_FB_APP_ID_DEV = "1:782838202525:ios:f4e3e1878ddbe55f5ed474"
        IOS_FB_APP_ID_DEMO = "1:782838202525:ios:c8b6cbfac1c245705ed474"
        IOS_FB_APP_ID_STAGE = "1:782838202525:ios:a04f8adacedca5af5ed474"
        IOS_FB_APP_ID_PROD = "1:782838202525:ios:1964c167fe29a0b55ed474"

        IPA_FILE_NAME = "adstatapp.ipa"
    
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
                demo: AND_FB_APP_ID_DEMO,
                stage: AND_FB_APP_ID_STAGE,
                prod: AND_FB_APP_ID_PROD,
            },
            ios: {
                dev: IOS_FB_APP_ID_DEV,
                demo: IOS_FB_APP_ID_DEMO,
                stage: IOS_FB_APP_ID_STAGE,
                prod: IOS_FB_APP_ID_PROD,
            },
            ipa_file_name: IPA_FILE_NAME,
        }
        end
    end
end