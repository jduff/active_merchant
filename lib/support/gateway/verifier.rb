module Support
  module Gateway
    class Verifier
      FEATURES = [:purchase, :authorize, :capture, :void, :credit, :recurring, :refund, :store, :unstore, :update]

      attr_accessor :gateway_class

      def initialize(gateway_class)
        @gateway_class = gateway_class
      end

      def defined_features?
        gateway_class.has_features.any?
      end

      def defined_credentials?
        gateway_class.credentials.any?
      end

      def initialize?
        gateway.present?
      end

      def public_methods
        @public_methods ||= gateway_class.public_instance_methods - Object.public_instance_methods - ActiveMerchant::Billing::Gateway.public_instance_methods - credentials
      end

      def unsupported_features
        @unsupported_features ||= gateway_class.has_features - FEATURES.keys
      end

      def extra_methods
        @extra_methods ||= public_methods - (gateway_class.has_features - unsupported_features)
      end

      def missing_implementations
        @missing_implementations ||= (GATEWAY_FEATURES.keys & gateway_class.has_features) - features
      end

      def implemented_features
        @implemented_features ||= GATEWAY_FEATURES.keys & features
      end

      def correct_arity?(feature)
        arguments = feature_arguments(feature)
        gateway.method(feature).arity.abs == arguments.length
      end

      def optional_last_argument?(feature)
        gateway.method(feature).arity < 0
      end

      def feature_callable?(feature)
        arguments = feature_arguments(feature)
        without_commit do
          gateway.send(feature, *arguments) and true rescue false
        end
      end

      private
      def gateway
        @gateway ||= gateway_class.new(gateway_class.credentials.collect(&:to_s), :test => true) rescue nil
      end

      def without_commit
        old_commit = gateway.method(:commit)
        gateway.class_eval(<<-CODE)
          def commit(*args); end
        CODE
        yield
      ensure
        gateway.define_method(
      end

      def feature_arguments(feature)
        case feature
        when :purchase
          [money, creditcard, options]
        when :capture
          [money, "auth", options]
        when :void
          [authorization, options]
        when :refund
          [money, "auth", options]
        when :credit
          [money, creditcard, options]
        when :store
          [creditcard, options]
        when :unstore
          ["customer_id", options],
        when :update
          ["customer_id", creditcard, options]
        when :recurring
          [money, creditcard, options]
        end
      end

      def money
        @money ||= 1200
      end

      def creditcard
        @creditcard ||= ActiveMerchant::Billing::CreditCard.new(
          :number => 4242424242424242,
          :month => 9,
          :year => Time.now.year + 1,
          :first_name => 'Test',
          :last_name => 'User',
          :verification_value => '123',
          :brand => 'visa'
        )
      end

      def options
        @options ||= {
          :order_id =>'1', 
          :description =>'Store Purchase',
          :billing_address => {
            :name     => 'Jim Smith',
            :address1 => '1234 My Street',
            :address2 => 'Apt 1',
            :company  => 'Widgets Inc',
            :city     => 'Ottawa',
            :state    => 'ON',
            :zip      => 'K1C2N6',
            :country  => 'CA',
            :phone    => '(555)555-5555',
            :fax      => '(555)555-6666'
          }
        }
      end
    end
  end
end
