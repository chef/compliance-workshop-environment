# Workshop Environment

This repo contains the bits necessary for a successful Chef Essentials + InSpec workshop.

## Environment Setup

### Creating the Environment

1. Ensure Terraform 0.10 or later is installed. Run `terraform version` to validate.
1. If your AWS key is different than your default key (`~/.ssh/id_rsa`, for example), add it to your ssh-agent (`ssh-add ~/.ssh/my-aws-key`).
   * SSH agent is the preferred auth method in order to accommodate password-protected SSH keys which are not supported by Terraform.
1. Put a valid `delivery.license` file in the `terraform` directory in this repository.
1. Run: `bundle install`
1. Run: `bundle exec carpenter build NAME`
   * The `NAME` will be used in the FQDN of the Automate Hostname, and it also provides the ability to run multiple workshop environments simultaneously.
1. Answer carpenter's questions, say `yes`, and then Terraform will do its thing!

For Markdown output of all the workstation IP addresses, run: `bundle exec carpenter markdown NAME`

For the IP address of the Automate server, run: `bundle exec carpenter automate_ip NAME`

### Re-Running Terraform

Should there be a problem during the Terraform run, a re-run will usually fix the infrastructure that didn't get set up properly.

To re-run Terraform, run: `bundle exec carpenter rerun NAME`

### Destroying

When the environment is no longer necessary, run: `bundle exec carpenter destroy NAME`

## Building a Workstation Image

The CentOS workstation is built with packer, a single recipe, and a bunch of resources from other open-source cookbooks. To build a new workstation image:

1. Ensure you have valid AWS credentials in the normal place (i.e. `~/.aws/credentials`)
1. `cd packer`
1. Edit the `workshop-workstation-centos.json` and update the `ami_name` (i.e. increment the version)
1. Vendor the dependent cookbooks: `berks vendor --berksfile=cookbooks/workstations/Berksfile vendored_cookbooks`
1. Run Packer: `packer build ./workshop-workstation-centos.json`
1. Submit a PR back to this repo with the new version number in the JSON.
