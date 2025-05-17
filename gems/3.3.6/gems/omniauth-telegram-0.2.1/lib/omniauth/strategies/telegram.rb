require "omniauth"
require "openssl"
require "base64"

module OmniAuth
  module Strategies
    class Telegram
      include OmniAuth::Strategy

      args %i[bot_name bot_secret]

      option :name, "telegram"
      option :bot_name, nil
      option :bot_secret, nil
      option :button_config, {}

      REQUIRED_FIELDS = %w[id hash]
      HASH_FIELDS = %w[auth_date first_name id last_name photo_url username]

      def request_phase
        redirect_url =
          "https://oauth.telegram.org/auth?bot_id=#{options.bot_name}&origin=#{callback_url}&embed=1"
        html = <<-HTML
          <!DOCTYPE html>
          <html>
          <head>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
            <title>Telegram Login</title>
          </head>
          <body>
            <a href="#{redirect_url}" class="btn btn-primary">Login with Telegram</a> 
          </body>
          </html>
        HTML
        Rack::Response.new(html, 200, "content-type" => "text/html").finish
      end

      def callback_phase
        if error = check_errors
          fail!(error)
        else
          super
        end
      end

      uid { request.params["id"] }
      Rails.logger.warn("Telegram callback params: #{request.params.inspect}")

      info do
        {
          name: "#{request.params["first_name"]} #{request.params["last_name"]}",
          nickname: request.params["username"],
          first_name: request.params["first_name"],
          last_name: request.params["last_name"],
          image: request.params["photo_url"],
        }
      end

      extra { { auth_date: Time.at(request.params["auth_date"].to_i) } }

      private

      def check_errors
        return :field_missing unless check_required_fields
        return :signature_mismatch unless check_signature
        return :session_expired unless check_session
      end

      def check_required_fields
        REQUIRED_FIELDS.all? { |f| request.params.include?(f) }
      end

      def check_signature
        request.params["hash"] ==
          self.class.calculate_signature(options[:bot_secret], request.params)
      end

      def check_session
        Time.now.to_i - request.params["auth_date"].to_i <= 86_400
      end

      def self.calculate_signature(secret, params)
        secret = OpenSSL::Digest::SHA256.digest(secret)
        signature = generate_comparison_string(params)
        OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, secret, signature)
      end

      def self.generate_comparison_string(params)
        (params.keys & HASH_FIELDS).sort.map { |field| "%s=%s" % [field, params[field]] }.join("\n")
      end
    end
  end
end
