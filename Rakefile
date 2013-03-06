$:.unshift File.expand_path('../lib', __FILE__)

begin
  require 'bundler'
  Bundler.setup
rescue LoadError => e
  puts "Error loading bundler (#{e.message}): \"gem install bundler\" for bundler support."
  require 'rubygems'
end

require 'rake'
require 'rake/testtask'
require 'rubygems/package_task'
require 'support/gateway_support'
require 'support/ssl_verify' 
require 'support/outbound_hosts'

desc "Run the unit test suite"
task :default => 'test:units'

task :test => 'test:units'

namespace :test do

  Rake::TestTask.new(:units) do |t|
    t.pattern = 'test/unit/**/*_test.rb'
    t.ruby_opts << '-rubygems'
    t.libs << 'test'
    t.verbose = true
  end

  Rake::TestTask.new(:remote) do |t|
    t.pattern = 'test/remote/**/*_test.rb'
    t.ruby_opts << '-rubygems'
    t.libs << 'test'
    t.verbose = true
  end

end

desc "Delete tar.gz / zip"
task :cleanup => [ :clobber_package ]

spec = eval(File.read('activemerchant.gemspec'))

Gem::PackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

desc "Release the gems and docs to RubyForge"
task :release => [ 'gemcutter:publish' ]

namespace :gemcutter do
  desc "Publish to gemcutter"
  task :publish => :package do
    sh "gem push pkg/activemerchant-#{ActiveMerchant::VERSION}.gem"
  end
end

namespace :gateways do
  desc 'Print the currently supported gateways'
  task :print do
    support = GatewaySupport.new
    support.to_s
  end
  
  namespace :print do
    desc 'Print the currently supported gateways in RDoc format'
    task :rdoc do
      support = GatewaySupport.new
      support.to_rdoc
    end
  
    desc 'Print the currently supported gateways in Textile format'
    task :textile do
      support = GatewaySupport.new
      support.to_textile
    end
    
    desc 'Print the gateway functionality supported by each gateway'
    task :features do
      support = GatewaySupport.new
      support.features
    end
  end
  
  desc 'Print the list of destination hosts with port'
  task :hosts do
    OutboundHosts.list
  end
 
  desc 'Test that gateways allow SSL verify_peer'
  task :ssl_verify do
    SSLVerify.new.test_gateways
  end

  desc 'Verify gateway interface'
  task :verify do
    require 'mocha/api'
    include Mocha::API

    gateway_class = ActiveMerchant::Billing::StripeGateway
    gateway_instance = nil
    credentials = gateway_class.credentials

    # Test initialize
    begin
      gateway_instance = gateway_class.new(credentials.collect(&:to_s), :test => true)
      puts "Initialized gateway"
      gateway_initialized = true
    rescue => ex
      puts "Failed to initialize gateway"
    end

    money = 1200
    defaults = {
      :number => 4242424242424242,
      :month => 9,
      :year => Time.now.year + 1,
      :first_name => 'Longbob',
      :last_name => 'Longsen',
      :verification_value => '123',
      :brand => 'visa'
    }

    creditcard = ActiveMerchant::Billing::CreditCard.new(defaults)
    address = {
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

    options = {:order_id =>'1', :billing_address => address, :description =>'Store Purchase'}

    customer = "magic"
    authorization = "auth"

    GATEWAY_FEATURES = {
      :purchase => [money, creditcard, options],
      :void => [authorization, options],
      :refund => [money, authorization, options],
      :store => [creditcard, options],
      :unstore => [customer, options],
      :update => [customer, creditcard, options]
    }

    # Test features
    features = gateway_class.public_instance_methods - Object.public_instance_methods - ActiveMerchant::Billing::Gateway.public_instance_methods - credentials

    puts "No features? Are you sure?" if features.empty?

    unsupported_features = gateway_class.has_features - GATEWAY_FEATURES.keys

    puts "Unsupported features: #{unsupported_features}" unless unsupported_features.empty?

    extra_methods = features - (gateway_class.has_features - unsupported_features)

    puts "Unnecessary public methods: #{extra_methods}" unless extra_methods.empty?

    missing_implementations = (GATEWAY_FEATURES.keys & gateway_class.has_features) - features

    puts "Missing feature implementations: #{missing_implementations}" unless missing_implementations.empty?

    implemented_features = GATEWAY_FEATURES.keys & features

    gateway_instance.class.class_eval(<<-CODE)
      def commit(*args); end
    CODE
    implemented_features.each do |feature|
      arguments = GATEWAY_FEATURES[feature]
      arg_length = gateway_instance.method(feature).arity
      if arg_length > 0
        puts "Feature '#{feature}' last argument should be optional options hash."
      end

      if arg_length.abs != arguments.length
        puts "Feature '#{feature}' does not take the correct number of arguments. Expected #{arguments.length} was #{arg_length.abs}"
        next
      end

      begin
        gateway_instance.send(feature, *arguments)
        puts "Feature '#{feature}' was sucessful."
      rescue => ex
        puts "Feature '#{feature}' failed. #{ex.message} #{ex.backtrace.join('\n\n')}"
      end
    end
  end
end
