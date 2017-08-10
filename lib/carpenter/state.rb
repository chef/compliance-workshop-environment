require 'json'

module Carpenter
  module State
    def self.load(env_name)
      return {} unless File.exist?(state_file(env_name))
      JSON.parse(File.read(state_file(env_name)))
    end

    def self.save(env_name, config)
      create_state_dir
      File.write(state_file(env_name), config.to_json)
    end

    def self.delete(env_name)
      File.unlink(state_file(env_name)) if File.exist?(state_file(env_name))
      delete_terraform_state_files(env_name)
    end

    private

    def self.create_state_dir
      Dir.mkdir(state_dir) unless Dir.exist?(state_dir)
    end

    def self.state_dir
      File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'state'))
    end

    def self.state_file(env_name)
      File.join(state_dir, "#{env_name}.json")
    end

    def self.delete_terraform_state_files(env_name)
      [
        File.join(state_dir, "#{env_name}.tfstate"),
        File.join(state_dir, "#{env_name}.tfstate.backup"),
      ].each do |file|
        File.unlink(file) if File.exist?(file)
      end
    end
  end
end
