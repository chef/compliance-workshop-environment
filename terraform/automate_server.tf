resource "aws_instance" "automate" {
  ami                    = "${var.automate_ami}"
  key_name               = "${var.aws_sshkey}"
  instance_type          = "m4.4xlarge"
  vpc_security_group_ids = ["${var.security_group}"]

  root_block_device {
    volume_size           = 60
    delete_on_termination = true
  }

  tags {
    X-Dept    = "Sales"
    X-Contact = "${var.contact_tag}"
    Name      = "${var.workshop_prefix}-workshop-automate"
  }

  connection {
    type    = "ssh"
    user    = "centos"
    timeout = "2m"
    agent   = true
  }

  provisioner "file" {
    source      = "data-collector-token.toml"
    destination = "/home/centos/data-collector-token.toml"
  }

  provisioner "file" {
    source      = "update-admin-user.sh"
    destination = "/home/centos/update-admin-user.sh"
  }

  provisioner "file" {
    source      = "automate.license"
    destination = "/home/centos/automate.license"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sysctl -w vm.max_map_count=262144",
      "sudo sysctl -w vm.dirty_expire_centisecs=20000",
      "echo vm.max_map_count=262144 | sudo tee --append /etc/sysctl.conf",
      "echo vm.dirty_expire_centisecs=20000 | sudo tee --append /etc/sysctl.conf",
      "sudo yum install -y epel-release -y",
      "sudo yum install -y jq",
      "curl https://packages.chef.io/files/current/latest/chef-automate-cli/chef-automate_linux_amd64.zip | gunzip - > chef-automate && chmod +x chef-automate",
      "sudo ./chef-automate init-config --fqdn ${var.workshop_prefix}-workshop.${var.domain}",
      "sudo ./chef-automate deploy --accept-terms-and-mlsa config.toml",
      "sudo ./chef-automate config patch data-collector-token.toml",
      "chmod +x update-admin-user.sh",
      "sudo ./update-admin-user.sh",
      "sudo ./chef-automate license apply ./automate.license",
    ]
  }
}
