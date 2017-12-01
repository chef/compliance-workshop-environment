require 'tomlrb'

module Carpenter
  class Config
    CONFIG_FILE = File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'carpenter.toml')

    attr_reader :config

    def initialize
      @config = load_config
    end

    def load_config
      Tomlrb.load_file(CONFIG_FILE, symbolize_keys: true)
    end

    def aws_account_names
      config[:aws_accounts].map { |x| x[:name] }.sort
    end

    def aws_account(account_name)
      config[:aws_accounts].find { |x| x[:name] == account_name }
    end
  end
end
