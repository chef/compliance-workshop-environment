require 'hashie/mash'

module Carpenter
  module Terraform
    def self.apply(config)
      env_name = config[:env_name]

      get_cmd = Mixlib::ShellOut.new('terraform init -upgrade=true', cwd: terraform_dir)
      get_cmd.run_command
      get_cmd.error!

      apply_cmd = Mixlib::ShellOut.new(
        "terraform apply -state=#{state_file(env_name)} -auto-approve",
        cwd: terraform_dir,
        env: env_from_config(config),
        timeout: 1800,
      )
      apply_cmd.live_stream = STDOUT
      apply_cmd.run_command
      apply_cmd.error!
    end

    def self.destroy(config)
      env_name = config[:env_name]

      cmd = Mixlib::ShellOut.new(
        "terraform destroy -state=#{state_file(env_name)} -force",
        cwd: terraform_dir,
        env: env_from_config(config),
        timeout: 1800,
      )
      cmd.live_stream = STDOUT
      cmd.run_command
      cmd.error!
    end

    def self.load_state(env_name)
      return unless File.exist?(state_file(env_name))
      Hashie::Mash.new(JSON.load(File.read(state_file(env_name))))
    end

    def self.has_license?
      File.exist?(File.join(terraform_dir, 'automate.license'))
    end

    private

    def self.state_dir
      File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'state'))
    end

    def self.state_file(env_name)
      File.join(state_dir, "#{env_name}.tfstate")
    end

    def self.terraform_dir
      File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'terraform'))
    end

    def self.env_from_config(config)
      {
        "AWS_PROFILE"                       => config[:aws_profile],
        "TF_VAR_total_workstations"         => config[:workstation_count].to_s,
        "TF_VAR_workstation_login_password" => config[:encrypted_workstation_password],
        "TF_VAR_aws_sshkey"                 => config[:aws_key_name],
        "TF_VAR_workshop_prefix"            => config[:env_name],
        "TF_VAR_contact_tag"                => config[:contact_tag],
        "TF_VAR_deck_color_1"               => config[:deck_color_1],
        "TF_VAR_deck_color_2"               => config[:deck_color_2],
        "TF_VAR_workstation_ami"            => config[:workstation_ami_id],
        "TF_VAR_automate_ami"               => config[:automate_ami_id],
        "TF_VAR_security_group"             => config[:security_group_id],
        "TF_VAR_dns_zone"                   => config[:dns_zone],
        "TF_VAR_domain"                     => config[:domain],
      }
    end
  end
end
