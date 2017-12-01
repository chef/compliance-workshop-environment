# Workshop Environment

This repo contains the bits necessary for a successful Chef Essentials + InSpec workshop.

## Environment Setup

**NOTE:** Carpenter currently supports the `chef-aws`, `chef-engineering`, and `chef-sa-group` accounts. If you would like Carpenter to support additional AWS accounts, see the "Adding Additional Account Support" section below.

### Creating the Environment

1. Ensure Terraform 0.10 or later is installed. Run `terraform version` to validate.
1. If your AWS key is different than your default key (`~/.ssh/id_rsa`, for example), add it to your ssh-agent (`ssh-add ~/.ssh/my-aws-key`).
   * SSH agent is the preferred auth method in order to accommodate password-protected SSH keys which are not supported by Terraform.
1. Put a valid `delivery.license` file in the `terraform` directory in this repository.
1. Ensure your `~/.aws/credentials` file has a section for the account you choose when you run `carpenter build` below. The account names must match.
   * If you are using an account tied to Okta, such as `chef-engineering`, ensure that the `okta_aws` tool is running so your `credentials` file has a fresh set of keys.
1. Run: `bundle install`
1. Run: `bundle exec carpenter build NAME`
   * The `NAME` will be used in the FQDN of the Automate Hostname, and it also provides the ability to run multiple workshop environments simultaneously.
1. Answer carpenter's questions, say `yes`, and then Terraform will do its thing!

For Markdown output of all the workstation IP addresses, run: `bundle exec carpenter markdown NAME`

For the IP address of the Automate server, run: `bundle exec carpenter automate_ip NAME`

For the URL of the Automate server, run: `bundle exec carpenter automate_url NAME`

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

## Adding Additional Account Support

Adding support for an additional account requires some EC2, Route 53, and Carpenter changes. But it's not that hard, I promise!

### EC2

1. Get the AWS account number of the new account.
1. Modify the latest EC2 Workstation AMI permissions, and share it with the new account.
1. Create a new security group in the new account. It will need to allow SSH, HTTP, and HTTPS traffic inbound from everyone.

### Route 53

1. Create a new hosted zone in the new account. Follow the `<DEPARTMENT>.chefdemo.net` naming convention. For example, for the Solutions Architect account, a good zone name may be `sa.chefdemo.net`
1. Grab the `NS` records from the new account.
1. In the `chef-aws` account, create a new `NS` record set. The name should be the name of the zone you created in step 1, and the contents should be the `NS` records from the zone created in step 1.

### Packer Config

Modify `packer/workshop-workstation-centos.json` in this repo, and add the new account number to the `ami_users` value.

### Carpenter Config

Create a new section in the `carpenter.toml` file at the root of this repository. Include the following information:

* **name**: the name of the account. This should match the section header in `~/.aws/credentials` which may be created automatically by the `okta_aws` tool.
* **workstation AMI ID**: this will likely be the same ID as the other existing sections if it was shared as instructed in this README.
* **automate AMI ID**: copy from an existing section - this is just a base CentOS image with no customizations.
* **security group ID**: the `sg-xxxxxxxxx` ID of the security group created above.
* **DNS zone**: the name of the DNS zone created above. **Be sure to include the trailing `.`**

### Publish your changes!

Don't forget to open a PR back to this repo that contains all your awesome changes to support a new AWS account!
