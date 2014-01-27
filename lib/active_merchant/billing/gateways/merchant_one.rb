require "cgi"

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class MerchantOneGateway < Gateway

      class MerchantOneSslConnection < ActiveMerchant::Connection
        def configure_ssl(http)
          super(http)
          http.use_ssl = true
          http.ssl_version = :SSLv3
        end
      end

      BASE_URL = 'https://secure.merchantonegateway.com/api/transact.php'

      self.supported_countries = ['US']
      self.supported_cardtypes = [:visa, :master, :american_express, :discover]
      self.homepage_url = 'http://merchantone.com/'
      self.display_name = 'Merchant One Gateway'
      self.money_format = :dollars

      def initialize(options = {})
        requires!(options, :username, :password)
        super
      end

      def authorize(money, creditcard, options = {})
        post = {}
        add_customer_data(post, options)
        add_creditcard(post, creditcard)
        add_address(post, creditcard, options)
        add_customer_data(post, options)
        add_amount(post, money, options)
        commit('auth', money, post)
      end

      def purchase(money, creditcard, options = {})
        post = {}
        add_customer_data(post, options)
        add_creditcard(post, creditcard)
        add_address(post, creditcard, options)
        add_customer_data(post, options)
        add_amount(post, money, options)
        add_frequency(post, options)
        commit('sale', money, post)
      end

      def capture(money, authorization, options = {})
        post = {}
        post.merge!(:transactionid => authorization)
        add_amount(post, money, options)
        commit('capture', money, post)
      end

      def new_connection(endpoint)
        MerchantOneSslConnection.new(endpoint)
      end

      def recurring(money, creditcard, options={})
        post = {}
        add_customer_data(post, options)
        add_creditcard(post, creditcard)
        add_address(post, creditcard, options)
        add_amount(post, money, options, true)
        add_frequency(post, options)
        commit_recurring('add_subscription', money, post)
      end

      def status_recurring(subscription_id)

      end

      def update_recurring(options={})
        commit_recurring('update_subscription', options)
      end

      def cancel_recurring(subscription_id)
        post = {}
        post[:subscription_id] = subscription_id
        commit_recurring('delete_subscription', post)
      end



private

      def add_customer_data(post, options)
        post['firstname'] = options[:billing_address][:first_name]
        post['lastname'] = options[:billing_address][:last_name]
      end

      def add_amount(post, money, options, recurring)
        if recurring
          post['plan_amount'] = amount(money)
        else
          post['amount'] = amount(money)
        end
      end

      def add_address(post, creditcard, options)
        post['address1'] = options[:billing_address][:address1]
        post['city'] = options[:billing_address][:city]
        post['state'] = options[:billing_address][:state]
        post['zip'] = options[:billing_address][:zip]
        post['country'] = options[:billing_address][:country]
      end

      def add_creditcard(post, creditcard)
        post['cvv'] = creditcard.verification_value if creditcard.verification_value
        post['ccnumber'] = creditcard.number
        post['ccexp'] =  "#{sprintf("%02d", creditcard.month)}#{"#{creditcard.year}"[-2, 2]}"
      end
      def add_frequency(post, options={})
        if options[:interval]
          if options[:interval][:unit] == :days
            post['day_frequency'] = options[:interval][:length]
          elsif options[:interval][:unit] == :months
            post['month_frequency'] = options[:interval][:length]
            post['day_of_month'] = options[:interval][:day_of_month] if options[:interval][:day_of_month]
            post['day_of_month'] ||= '1'
          end
        end
        post['start_date'] = options[:start_date] if options[:start_date]
      end

      def commit(action, money, parameters={})
        parameters['username'] = @options[:username]
        parameters['password'] = @options[:password]
        parse(ssl_post(BASE_URL,post_data(action, parameters)))
      end

      def commit_recurring(action, money, parameters={})
        parameters['recurring'] = action
        commit('', money, parameters)
      end

      def post_data(action, parameters = {})
        parameters.merge!({:type => action})
        ret = ""
        for key in parameters.keys
          ret += "#{key}=#{CGI.escape(parameters[key].to_s)}"
          if key != parameters.keys.last
            ret += "&"
          end
        end
        ret.to_s
      end

      def parse(data)
        responses =  CGI.parse(data).inject({}){|h,(k, v)| h[k] = v.first; h}
        Response.new(
          (responses["response"].to_i == 1),
          responses["responsetext"],
          responses,
          :test => test?,
          :authorization => responses["transactionid"]
        )
      end
    end
  end
end

