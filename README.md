# Workshop Environment

This repo contains the bits necessary for a successful Chef Essentials + InSpec workshop.

## Environment Setup

1. If your AWS key is different than your default key (`~/.ssh/id_rsa`, for example), add it to your ssh-agent (`ssh-add ~/.ssh/my-aws-key`).
1. TBD

## Building a Workstation Image

The CentOS workstation is built with packer, a single recipe, and a bunch of resources from other open-source cookbooks. To build a new workstation image:

1. Ensure you have valid AWS credentials in the normal place (i.e. `~/.aws/credentials`)
1. `cd packer`
1. Edit the `workshop-workstation-centos.json` and update the `ami_name` (i.e. increment the version)
1. Vendor the dependent cookbooks: `berks vendor --berksfile=cookbooks/workstations/Berksfile vendored_cookbooks`
1. Run Packer: `packer build ./workshop-workstation-centos.json`
1. Submit a PR back to this repo with the new version number in the JSON.
