require 'aws-sdk-ec2'
require 'aws-sdk-route53'

module Carpenter
  class AWS
    attr_reader :config, :key_name

    def initialize(config, key_name)
      @config = config
      @key_name = key_name
    end

    def validate!
      puts ''

      print 'Checking for valid AWS credentials... '
      begin
        validate_credentials
      rescue
        puts 'ERROR'
        raise
      end
      puts 'OK'

      print 'Checking for your SSH key pair... '
      begin
        validate_key_pair
      rescue
        puts 'ERROR'
        raise
      end
      puts 'OK'

      print 'Checking for workstation AMI... '
      begin
        validate_ami_id(config[:workstation_ami_id])
      rescue
        puts 'ERROR'
        raise
      end
      puts 'OK'

      print 'Checking for Automate server AMI... '
      begin
        validate_ami_id(config[:automate_ami_id])
      rescue
        puts 'ERROR'
        raise
      end
      puts 'OK'

      print 'Checking for security group... '
      begin
        validate_security_group(config[:security_group_id])
      rescue
        puts 'ERROR'
        raise
      end
      puts 'OK'

      print 'Checking for DNS zone... '
      begin
        validate_dns_zone(config[:dns_zone])
      rescue
        puts 'ERROR'
        raise
      end
      puts 'OK'

      puts ''
    end

    private

    def ec2
      @ec2 ||= Aws::EC2::Resource.new(region: 'us-west-2', profile: config[:name])
    end

    def route53
      @route53 ||= Aws::Route53::Client.new(region: 'us-west-2', profile: config[:name])
    end

    def validate_credentials
      ec2.vpcs.first
    rescue Aws::Errors::MissingCredentialsError
      raise "Unable to find credentials for account #{config[:name]} - check your AWS credentials file, or ensure you're running okta_aws if your account requires it"
    rescue Aws::EC2::Errors::RequestExpired
      raise "Your AWS credentials have expired. Are you running okta_aws if your account requires it?"
    end

    def validate_key_pair
      # will raise Aws::EC2::Errors::InvalidKeyPairNotFound if the key doesn't exist
      ec2.key_pair(key_name).key_fingerprint
    end

    def validate_ami_id(ami_id)
      unless ec2.image(ami_id).exists?
        raise "AMI ID #{ami_id} is not found"
      end
    end

    def validate_security_group(sg_id)
      # will raise Aws::EC2::Errors::InvalidGroupNotFound if it's not found with a human-readable exception message
      ec2.security_group(sg_id).group_name
    end

    def validate_dns_zone(dns_zone)
      if route53.list_hosted_zones.hosted_zones.find { |x| x.name == dns_zone }.nil?
        raise "DNS zone #{dns_zone} does not exist"
      end
    end
  end
end
