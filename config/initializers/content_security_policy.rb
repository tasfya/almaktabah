Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none

    # Allow Vite development server in development
    if Rails.env.development?
      policy.script_src :self, :unsafe_eval, :unsafe_inline, "http://localhost:3036", "http://127.0.0.1:3036", "http://127.0.0.1:3000"
      policy.connect_src :self, :https, "http://localhost:3036", "ws://localhost:3036", "http://127.0.0.1:3036", "ws://127.0.0.1:3036", "http://127.0.0.1:3000"
      policy.style_src :self, :unsafe_inline, "http://localhost:3036", "http://127.0.0.1:3036", "http://127.0.0.1:3000"
    else
      policy.script_src :self
      policy.style_src :self, :unsafe_inline
    end
  end

  # Generate session nonces for permitted importmap and inline scripts
  config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]

  # Remove or comment out the report-only mode to actually enforce the policy
  # config.content_security_policy_report_only = true
end
