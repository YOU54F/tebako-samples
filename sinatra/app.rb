#!/usr/bin/env ruby
# frozen_string_literal: true

# require 'rubygems' # test removing to tebako
# require 'bundler/setup'

# Gem.use_gemdeps
INTERNAL_APP = ARGV[0].to_s
FILENAME = File.basename($PROGRAM_NAME).split.first.chomp(".rb")
# Ocran will allow use to include our own cert file at packaging time
# this points to the CA cert bundle take from traveling-ruby
if (ENV["OCRAN_EXECUTABLE"] || ENV["OCRAN_EXECUTABLE"] != "") && ENV["SSL_CERT_FILE"].nil?
  ENV["SSL_CERT_FILE"] =
    File.join(File.dirname($PROGRAM_NAME),
              "ca-bundle.crt")
end

case ARGV[0]
when "pact"
  ARGV.shift
  require "pact/cli"

  # class Thor
  #   module Base
  #     module ClassMethods
  #       def basename
  #         "#{File.basename($PROGRAM_NAME).split.first.chomp('.rb')} #{INTERNAL_APP}"
  #       end
  #     end
  #   end
  # end

  Pact::CLI.start
when "pactflow"
  ARGV.shift
  require "pactflow/client/cli/pactflow"
  Pactflow::Client::CLI::Pactflow.start
when "stub-service"
  ARGV.shift
  require "pact/stub_service/cli"
  Pact::StubService::CLI.start
when "provider-verifier"
  ARGV.shift
  ENV["PACT_EXECUTING_LANGUAGE"] ||= "unknown"
  require "pact/provider_verifier/cli/verify"
  Pact::ProviderVerifier::CLI::Verify.start
when "mock-service"
  ARGV.shift
  require "pact/mock_service/cli"
  Pact::MockService::CLI.start unless defined?(Ocran)
when "message"
  ARGV.shift
  require "pact/message/cli"
  Pact::Message::CLI.start
when "test"
  ARGV.shift
  # ENV['BUNDLE_GEMFILE'] ||= File.expand_path('./Gemfile', __dir__)
  # require 'bundler/setup'
  # require 'rspec/core/rake_task'
  # require 'rubygems/package'
  # RSpec::Core::RakeTask.new(:spec)
  # task default: :spec
  load Gem.bin_path("rake", "rake")
when "broker"
  ARGV.shift
  if ARGV[0] == "run"
    puts "running pact-broker"
    # This is bin/puma
    ARGV.shift
    ENV["BUNDLE_GEMFILE"] ||= File.expand_path("./Gemfile", __dir__)
    require "bundler/setup"
    ARGV.push("start", "-R", "#{File.dirname(__FILE__)}/config.ru", "-p 9292") if ARGV.empty?
    if ARGV.include?("--with-ssl")
      ARGV.delete("--with-ssl")
      ARGV.push("start", "-R", "#{File.dirname(__FILE__)}/config.ru", "-p 9292")
      crt_file = File.join(Dir.pwd, "server.crt")
      key_file = File.join(Dir.pwd, "server.key")

      unless File.exist?(crt_file) && File.exist?(key_file)
        system("openssl req -x509 -newkey rsa:4096 -nodes -keyout #{key_file} -out #{crt_file} -days 365 -subj '/CN=localhost'")
      end

      ARGV.push("--ssl", "--ssl-cert-file", crt_file, "--ssl-key-file", key_file)
    end
    load Gem.bin_path("thin", "thin")
  else
    require "pact_broker/client/cli/broker"
    if ENV["PACT_BROKER_DISABLE_SSL_VERIFICATION"] == "true" || ENV["PACT_DISABLE_SSL_VERIFICATION"] == "true"
      require "openssl"
      OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
      warn "
      WARN: SSL verification has been disabled by a dodgy hack
      (reassigning the VERIFY_PEER constant to VERIFY_NONE).
      You acknowledge that you do this at your own risk!
      "
    end
    PactBroker::Client::CLI::Broker.start
  end
when "plugin"
  ARGV.shift
  require "open3"
  base_cmd = "#{File.dirname(__FILE__)}/pact-plugin-cli"
  puts(base_cmd)
  command = [base_cmd, *ARGV].join(" ")
  system(command) ? exit(0) : exit(1)
when "verifier"
  ARGV.shift
  require "open3"
  base_cmd = "#{File.dirname(__FILE__)}/pact_verifier_cli"
  command = [base_cmd, *ARGV].join(" ")
  system(command) ? exit(0) : exit(1)
when "mock-server"
  ARGV.shift
  require "open3"
  base_cmd = "#{File.dirname(__FILE__)}/pact_mock_server_cli"
  command = [base_cmd, *ARGV].join(" ")
  system(command) ? exit(0) : exit(1)
when "stub-server"
  ARGV.shift
  require "open3"
  base_cmd = "#{File.dirname(__FILE__)}/pact-stub-server"
  command = [base_cmd, *ARGV].join(" ")
  system(command) ? exit(0) : exit(1)
else
  puts "uh oh, unknown command"
  puts "__________________"
  puts "available commands:"
  puts "__________________"
  puts "#{FILENAME} help"
  puts "#{FILENAME} pact"
  puts "#{FILENAME} stub-service"
  puts "#{FILENAME} provider-verifier"
  puts "#{FILENAME} mock-service"
  puts "#{FILENAME} broker"
  puts "#{FILENAME} broker run"
  puts "__________________"
  puts "pact-rust tool commands:"
  puts "#{FILENAME} stub-service"
  puts "#{FILENAME} verifier"
  puts "#{FILENAME} mock-service"
  puts "#{FILENAME} plugin"
end