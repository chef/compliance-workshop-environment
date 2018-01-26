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


### Azure directions

Follow the steps below to set up a Chef BJC demo environment on Microsoft Azure.

1. Get yourself access to the Chef Solutions Architecture account on Azure.  The friendly folks at Chef helpdesk can assist with this part.

2. Visit https://portal.azure.com and verify that your login credentials work.



3. Once you’re logged in click on the little gear icon in the upper right corner:


4. In another browser tab open up the BJC artifact repo and download the version you want to run. Make sure you grab the *Azure* version and not the AWS version of the demo.

https://s3.console.aws.amazon.com/s3/buckets/bjcpublic/cloudformation/?region=us-west-2&tab=overview

5.  Once you’ve downloaded the JSON onto your laptop go back into the Azure portal and click on “Resource Groups” on the left side menu.  Click on the +Add button at the top of the page.  

6.  You’ll have the option to pin your resource group into a widget on your Azure portal.  

7.  BJC demo is launched using a “Template Deployment”. Click New (Left side on the page), and search for Template Deployment until you can select it from the options.

Select Create.

8.  Click on “Build your own template in the editor”
9.  Click on “Load file” at the top.
10.  Browse to your bjc-demo-azure-x.x.x.json file and select it.
11.  Click ‘save’.  Under resource group select the resource group you created earlier.  You can optionally create a new user group here as well.
12.  All the other fields are optional.  The TTL field does not yet do anything on Azure, because there is no reaper in Azure (yet).  You’ll need to manually clean up your demo when you’re done.
13.  Agree to the terms and hit the “Purchase” button at the bottom.
14.  Wait around ten minutes for your demo to become available.  You can monitor the progress if you wish by clicking on the little bell alert icon at the top of the Azure portal controls.
15.  Once your demo is up and running connect via RDP as usual.  The IP address can be found by browsing into your Resource Group and then selecting the Output called Workstation-1-PublicIPAddres

OPTIONAL:
If you’re doing a custom demo or want to use the BJC environment for playing around with Test Kitchen, you can follow these steps to configure command line tools on the workstation.  These instructions will get you a working ‘kitchen create’ command as well as ‘knife azurerm’ commands:
https://chefio.slack.com/files/U07K7QLQ7/F6VHFC79N/create_azure_rm_service_principal.md
16.  When your demo is done, simply go back into the Azure portal and delete your resource group.  Azure will ask you to confirm before you wipe the demo.

