require 'digest/sha2'
require 'highline'
require 'mixlib/shellout'
require 'thor'

module Carpenter
  class CLI < Thor
    desc 'build ENV_NAME', 'build a workshop environment named ENV_NAME'
    def build(env_name)
      cli = HighLine.new

      unless Carpenter::State.load(env_name).empty?
        cli.say("#{cli.color('ERROR:', :red)} environment #{env_name} already exists.")
        exit 1
      end

      aws_key_name = cli.ask('AWS Key Name: ') do |q|
        q.default = ENV['USER']
        q.validate = /\A\S+\Z/
        q.responses[:not_valid] = "AWS Key Name cannot be empty"
      end

      workstation_password = cli.ask('Login password for workstations: ') do |q|
        q.validate = /\A\S+\Z/
        q.responses[:not_valid] = "Workstation login password cannot be empty"
      end

      workstation_count = cli.ask('Number of workstations: ') do |q|
        q.validate = lambda { |p| p.to_i > 0 && p.to_i < 104 }
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

      contact_tag = cli.ask('Email, without the chef.io (i.e. adamleff)') do |q|
        q.validate = /\A\S+\Z/
        q.responses[:not_valid] = "Email address (without domain) is required for the AWS Contact Tag"
      end

      config = {
        env_name: env_name,
        aws_key_name: aws_key_name,
        workstation_password: workstation_password,
        encrypted_workstation_password: encrypt_password(workstation_password),
        workstation_count: workstation_count,
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
      Carpenter::Terraform.apply(config)
      cli.say(cli.color('Voila!', :green))
    rescue Interrupt, EOFError
      cli.say("\nSee ya!")
    end

    desc 'rerun ENV_NAME', 're-run Terraform for the environment name, helpful to fix tainted infrastructure'
    def rerun(env_name)
      cli = HighLine.new

      config = Carpenter::State.load(env_name)
      if config.empty?
        cli.say("#{cli.color('ERROR:', :red)} No state found for an environment named #{env_name}")
        exit 1
      end

      print_config(cli, config)
      exit unless cli.agree("Are you sure you want to re-run this environment? (yes/no): ")

      Carpenter::Terraform.apply(config)
      cli.say(cli.color('Voila!', :green))
    rescue Interrupt, EOFError
      cli.say("\nSee ya!")
    end

    desc 'destroy ENV_NAME', 'destroy the workshop environment named ENV_NAME'
    def destroy(env_name)
      cli = HighLine.new

      config = Carpenter::State.load(env_name)
      if config.empty?
        cli.say("#{cli.color('ERROR:', :red)} No state found for an environment named #{env_name}")
        exit 1
      end

      print_config(cli, config)
      unless cli.agree("Are you sure you want to destroy this environment? (yes/no): ")
        cli.say("Nothing destroyed... phew!")
        exit
      end

      Carpenter::Terraform.destroy(config)
      Carpenter::State.delete(env_name)
      cli.say(cli.color("All gone!", :green))
    rescue Interrupt, EOFError
      cli.say("\nSee ya!")
    end

    desc 'markdown ENV_NAME', 'display the workstations for environment ENV_NAME in markdown format, useful for creating a gist'
    def markdown(env_name)
    end

    desc 'automate_ip ENV_NAME', 'display the IP address of the Automate server for environment ENV_NAME'
    def automate_ip(env_name)
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
  end
end
