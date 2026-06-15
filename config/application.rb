# frozen_string_literal: true

require_relative 'boot'

require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'action_mailer/railtie'
require 'active_job/railtie'
require 'rails/health_controller'

require_relative '../lib/api_path_consider_json_middleware'
require_relative '../lib/normalize_client_ip_middleware'

Bundler.require(*Rails.groups)

module DocuSeal
  class Application < Rails::Application
    config.load_defaults 8.1

    # Rails 8.1 removed several Active Record config accessors that older
    # load_defaults still populate (e.g. has_many_inversing,
    # belongs_to_required_by_default) — their behaviors are now permanent. The
    # stale keys remain in config.active_record, and when applied to
    # ActiveRecord::Base during boot, DynamicMatchers makes respond_to? a false
    # positive, so the setter falls through to method_missing and crashes with
    # "undefined method '<flag>=' for class ActiveRecord::Base".
    #
    # Strip any config.active_record key that has no real setter on the
    # ActiveRecord module — this mirrors the guard fixed Rails uses
    # (`if ActiveRecord.respond_to?(setter)`) and is not fooled by
    # DynamicMatchers. Checking the module (not ActiveRecord::Base) avoids
    # force-loading the class here. :encryption is a hash applied separately.
    config.active_record.keys.each do |key|
      next if key == :encryption

      config.active_record.delete(key) unless ActiveRecord.respond_to?("#{key}=")
    end

    config.autoload_lib(ignore: %w[assets tasks puma])

    config.active_storage.routes_prefix = ''

    config.active_storage.draw_routes = ENV['MULTITENANT'] != 'true'

    config.i18n.available_locales = %i[en en-US en-GB es-ES fr-FR pt-PT de-DE it-IT nl-NL
                                       es it de fr nl pl uk cs pt he ar ko ja]
    config.i18n.fallbacks = [:en]

    config.exceptions_app = ->(env) { ErrorsController.action(:show).call(env) }

    config.content_security_policy_nonce_generator = ->(_) { SecureRandom.base64(16) }
    config.content_security_policy_nonce_directives = %w[script-src]

    config.action_view.frozen_string_literal = true

    config.middleware.insert_before ActionDispatch::Static, Rack::Deflater
    config.middleware.insert_before ActionDispatch::Static, NormalizeClientIpMiddleware
    config.middleware.insert_before ActionDispatch::Static, ApiPathConsiderJsonMiddleware

    config.generators.system_tests = nil

    autoloaders.once.do_not_eager_load("#{Turbo::Engine.root}/app/channels") # https://github.com/hotwired/turbo-rails/issues/512

    ActiveSupport.run_load_hooks(:application_config, self)
  end
end
