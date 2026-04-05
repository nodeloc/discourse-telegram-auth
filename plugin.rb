# frozen_string_literal: true

# name: discourse-telegram-auth
# about: Enable Login via Telegram
# version: 1.0
# authors: Marco Sirabella
# url: https://github.com/mjsir911/discourse-telegram-auth

gem "omniauth-telegram", "0.2.1", require: false

enabled_site_setting :telegram_auth_enabled

register_svg_icon "fab-telegram"

extend_content_security_policy(
  script_src: %w[https://telegram.org],
  frame_src: %w[https://t.me https://telegram.org],
  child_src: %w[https://t.me https://telegram.org],
)

require "omniauth/telegram"

after_initialize do
  # Patch request_phase to inject a CSP nonce into the Telegram widget <script> tag.
  # Discourse uses 'strict-dynamic' which ignores hostname allowlists, so a nonce is required.
  reloadable_patch do
    OmniAuth::Strategies::Telegram.prepend(
      Module.new do
        define_method(:request_phase) do
          headers = { "content-type" => "text/html" }
          nonce = ContentSecurityPolicy.nonce_placeholder(headers)

          data_attrs = options.button_config.map { |k, v| "data-#{k}=\"#{v}\"" }.join(" ")

          html = <<~HTML
            <!DOCTYPE html>
            <html>
            <head>
              <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
              <title>Telegram Login</title>
            </head>
            <body>
              <script async
                src="https://telegram.org/js/telegram-widget.js?4"
                nonce="#{nonce}"
                data-telegram-login="#{options.bot_name}"
                data-auth-url="#{callback_url}"
                #{data_attrs}></script>
            </body>
            </html>
          HTML

          Rack::Response.new(html, 200, headers).finish
        end
      end,
    )
  end
end

class ::TelegramAuthenticator < ::Auth::ManagedAuthenticator # rubocop:disable Discourse/Plugins/NoMonkeyPatching
  def name
    "telegram"
  end

  def enabled?
    SiteSetting.telegram_auth_enabled
  end

  def register_middleware(omniauth)
    omniauth.provider :telegram,
                      setup:
                        lambda { |env|
                          strategy = env["omniauth.strategy"]
                          strategy.options[:bot_name] = SiteSetting.telegram_auth_bot_name
                          strategy.options[:bot_secret] = SiteSetting.telegram_auth_bot_token
                        }
  end

  def after_authenticate(auth_token, existing_account: nil)
    result = super
    telegram_uid = auth_token[:uid]
    if result.user && telegram_uid
      result.user.custom_fields["telegram_chat_id"] = telegram_uid
      result.user.save_custom_fields
    end
    result
  end
end

auth_provider authenticator: ::TelegramAuthenticator.new, icon: "fab-telegram"
