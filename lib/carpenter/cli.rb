require 'digest/sha2'
require 'highline'
require 'mixlib/shellout'
require 'mixlib/versioning'
require 'thor'

module Carpenter
  class CLI < Thor
    desc 'build ENV_NAME', 'build a workshop environment named ENV_NAME'
    def build(env_name)
      cli = HighLine.new

      validate_terraform_install!(cli)
      validate_automate_license!(cli)

      unless Carpenter::State.load(env_name).empty?
        say_error(cli, "environment #{env_name} already exists.")
        exit 1
      end

      config = Carpenter::Config.new

      account_config = nil
      cli.choose do |menu|
        menu.prompt = 'Select an AWS account: '
        config.aws_account_names.each do |account_name|
          menu.choice(account_name) { account_config = config.aws_account(account_name) }
        end
      end

      aws_key_name = cli.ask("AWS Key Name (in us-west-2 on account #{account_config[:name]}): ") do |q|
        q.default = ENV['USER']
        q.validate = /\A\S+\Z/
        q.responses[:not_valid] = "AWS Key Name cannot be empty"
      end

      begin
        Carpenter::AWS.new(account_config, aws_key_name).validate!
      rescue => e
        say_error(cli, "Unable to validate AWS configuration: #{e.message}")
        exit 1
      end

      workstation_password = cli.ask('Login password for workstations: ') do |q|
        q.validate = lambda { |p| !p.empty? && p != 'chef'}
        q.responses[:not_valid] = "Workstation login password cannot be empty or be 'chef'"
      end

      workstation_count = cli.ask('Number of workstations: ') do |q|
        q.validate = lambda { |p| p.to_i > 0 && p.to_i <= 104 }
        q.responses[:not_valid] = "Workstation count must be between 1-104"
      end.to_i

      if workstation_count <= 52
        deck_color_1 = cli.ask('Card deck color: ') do |q|
          q.default = 'blue'
        end
        deck_color_2 = 'unused'
      else
        deck_color_1 = cli.ask('First card deck color: ') do |q|
          q.default = 'blue'
        end
        deck_color_2 = cli.ask('Second card deck color: ') do |q|
          q.default = 'red'
        end
      end

      contact_tag = cli.ask('Email, without the chef.io (i.e. adamleff): ') do |q|
        q.default = ENV['USER']
        q.validate = /\A\S+\Z/
        q.responses[:not_valid] = "Email address (without domain) is required for the AWS Contact Tag"
      end

      config = {
        env_name: env_name,
        aws_profile: account_config[:name],
        aws_key_name: aws_key_name,
        workstation_ami_id: account_config[:workstation_ami_id],
        workstation_password: workstation_password,
        encrypted_workstation_password: encrypt_password(workstation_password),
        workstation_count: workstation_count,
        automate_ami_id: account_config[:automate_ami_id],
        dns_zone: account_config[:dns_zone],
        domain: account_config[:domain],
        security_group_id: account_config[:security_group_id],
        deck_color_1: deck_color_1,
        deck_color_2: deck_color_2,
        contact_tag: contact_tag,
      }

      cli.say("\nThe following configuration will be used:")
      print_config(cli, config)

      unless cli.agree('Look good? (yes/no): ')
        cli.say("awww...")
        exit
      end

      cli.say("Let's do this!")
      Carpenter::State.save(env_name, config)

      begin
        Carpenter::Terraform.apply(config)
      rescue
        say_error(cli, "Terraform apply failed. Fix any issues detailed above and run `carpenter rerun #{env_name}`. " \
          "If you need to change any environment settings, first run `carpenter destroy #{env_name}` and then " \
          "run `carpenter build #{env_name}` again.")
        exit 1
      end

      say_success(cli, 'Environment created!')
    rescue Interrupt, EOFError
      cli.say("\nSee ya!")
    end

    desc 'rerun ENV_NAME', 're-run Terraform for the environment name, helpful to fix tainted infrastructure'
    def rerun(env_name)
      cli = HighLine.new

      validate_terraform_install!(cli)

      config = Carpenter::State.load(env_name)
      if config.empty?
        say_error(cli, "No state found for an environment named #{env_name}")
        exit 1
      end

      print_config(cli, config)
      exit unless cli.agree("Are you sure you want to re-run this environment? (yes/no): ")

      Carpenter::Terraform.apply(config)
      say_success(cli, 'Re-run complete!')
    rescue Interrupt, EOFError
      cli.say("\nSee ya!")
    end

    desc 'destroy ENV_NAME', 'destroy the workshop environment named ENV_NAME'
    def destroy(env_name)
      cli = HighLine.new

      validate_terraform_install!(cli)

      config = Carpenter::State.load(env_name)
      if config.empty?
        say_error(cli, "No state found for an environment named #{env_name}")
        exit 1
      end

      print_config(cli, config)
      unless cli.agree("Are you sure you want to destroy this environment? (yes/no): ")
        cli.say("Nothing destroyed... phew!")
        exit
      end

      Carpenter::Terraform.destroy(config)
      Carpenter::State.delete(env_name)
      say_success(cli, 'All gone!')
    rescue Interrupt, EOFError
      cli.say("\nSee ya!")
    end

    desc 'markdown ENV_NAME', 'display the workstations for environment ENV_NAME in markdown format, useful for creating a gist'
    def markdown(env_name)
      state = Carpenter::State.load(env_name)
      if state.empty?
        say_error(cli, "No state found for an environment named #{env_name}")
        exit 1
      end

      tfstate = Carpenter::Terraform.load_state(env_name)
      if tfstate.empty?
        say_error(cli, "No Terraform state found for an environment named #{env_name}")
        exit 1
      end

      Carpenter::Markdown.print(tfstate)
    end

    desc 'automate_ip ENV_NAME', 'display the IP address of the Automate server for environment ENV_NAME'
    def automate_ip(env_name)
      state = Carpenter::State.load(env_name)
      if state.empty?
        say_error(cli, "No state found for an environment named #{env_name}")
        exit 1
      end

      tfstate = Carpenter::Terraform.load_state(env_name)
      if tfstate.empty?
        say_error(cli, "No Terraform state found for an environment named #{env_name}")
        exit 1
      end

      tfstate['modules'].each do |mod|
        next unless mod['resources'].key?('aws_instance.automate')
        puts mod['resources']['aws_instance.automate']['primary']['attributes']['public_ip']
        exit 0
      end
    end

    desc 'automate_url ENV_NAME', 'display the URL for the Chef Automate service for environment name ENV_NAME'
    def automate_url(env_name)
      cli = HighLine.new

      state = Carpenter::State.load(env_name)
      if state.empty?
        say_error(cli, "No state found for an environment named #{env_name}")
        exit 1
      end

      cli.say "\n"
      cli.say "https://#{env_name}-workshop.#{state[:dns_zone]}"
      cli.say "\n"
    end

    private

    def encrypt_password(password)
      cmd = Mixlib::ShellOut.new("openssl passwd -1 -stdin", input: password)
      cmd.run_command
      cmd.error!

      cmd.stdout.chomp
    end

    def print_config(cli, config)
      config.sort_by { |k, v| k }.each do |k, v|
        cli.say("#{cli.color("#{k}:", :bold)} #{v}")
      end
      cli.say("\n")
    end

    def say_error(cli, message)
      cli.say("#{cli.color('ERROR:', :red)} #{message}")
    end

    def say_success(cli, message)
      cli.say("#{cli.color('SUCCESS:', :green)} #{message}")
    end

    def validate_terraform_install!(cli)
      cmd = Mixlib::ShellOut.new("terraform version")
      cmd.run_command
      if cmd.error?
        say_error(cli, "Terraform not installed - please visit terraform.io first!")
        exit 1
      end

      version_line = cmd.stdout.lines.first.strip
      version_str = version_line.match(/Terraform v(\d+\.\d+\.\d+)/)[1]
      if version_str.nil?
        say_error(cli, "Unable to determine Terraform version - please install Terraform 0.10 or later")
        exit 1
      end

      installed_version = Mixlib::Versioning.parse(version_str)
      required_version = Mixlib::Versioning.parse("0.11.0")

      if installed_version < required_version
        say_error(cli, "Installed Terraform version #{installed_version.to_s} older than " \
          "required version #{required_version.to_s}. Visit terraform.io to download a newer version.")
        exit 1
      end
    rescue Errno::ENOENT
      say_error(cli, "Terraform not installed - please visit terraform.io first!")
      exit 1
    end

    def validate_automate_license!(cli)
      unless Carpenter::Terraform.has_license?
        say_error(cli, "No automate license file found. " \
          "Please copy a valid automate.license to the terraform/ directory.") unless Carpenter::Terraform.has_license?
        exit 1
      end
    end
  end
end
