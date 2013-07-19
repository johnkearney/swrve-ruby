require 'JSON'
require 'swrve/middleware/cache'
require 'swrve/middleware/http'

module Swrve
  module Api
    class Events
      extend Forwardable

      attr_accessor :api_endpoint

      def_instance_delegator :@api_endpoint, :post

      def initialize
        @api_endpoint    = Swrve::Middleware::Http.new(Swrve.config.api_url)
        @web_app_version = Swrve.config.web_app_version
        @api_key         = Swrve.config.api_key
      end

      def session_start(uuid, swrve_payload = {})
        post('session_start', query_options(uuid, swrve_payload: fill_nil_values(swrve_payload)))
      end

      def session_end(uuid, swrve_payload = {})
        post('session_end', query_options(uuid, swrve_payload: fill_nil_values(swrve_payload)))
      end

      def update_user(uuid, user_attributes = {})
        params = { user_initiated: (user_attributes.delete(:user_initiated) || true) }
        params.merge!(swrve_payload: fill_nil_values(user_attributes.delete(:swrve_payload) || {}))
  
        post('user', query_options(uuid, user_attributes.merge(params)))
      end

      def purchase(uuid, item_id, cost, options = {})
        options = { item: item_id.to_s, cost: cost.to_f, currency: "USD", quantity: 1}.merge(options)
        
        post('purchase', query_options(uuid, options)) 
      end

      def buy_in(uuid, amount, real_currency_name, reward_amount, reward_currency, options = {})
        payment_provider = options.delete( :payment_provider ) || "Default Payment Provider"
        swrve_payload = fill_nil_values(options[:swrve_payload] || {})

        post('buy_in', query_options(uuid, {cost: amount.to_f, local_currency: real_currency_name,
                                            reward_amount: reward_amount.to_f, reward_currency: reward_currency,
                                            payment_provider: payment_provider, swrve_payload: swrve_payload}))
      end

      def currency_given(uuid, given_amount, given_currency, payload={})
        validate_amount(given_amount, given_currency)
        payload = fill_nil_values(payload)
        
        post('currency_given', query_options(uuid, { given_currency: given_currency, given_amount: given_amount,
                                                     swrve_payload: payload}))

      end

      def create_event(uuid, name, payload = {})
        params = query_options(uuid, name: name, swrve_payload: fill_nil_values(payload))
        post('event', params)
      end

      private

      def validate_amount(amount, currency_name)
        raise Exception, "Invalid currency name #{currency_name}" if currency_name.empty?
        raise Exception, "Cannot give a zero amount #{amount.to_f}"    if amount.to_f == (0)
        raise Exception, "A negative amount is invalid #{amount.to_f}" if amount.to_f < (0)
      end

      def query_options(uuid, payload = {})
        { api_key: @api_key, app_version: @web_app_version, user: uuid }.merge(payload) 
      end

      #The swrve api does not accept nul JSON values
      def fill_nil_values(hash = {})
        ( hash.each { |k, v| hash[k] = '' if v.nil? } ).to_json
      end
    end
  end
end

