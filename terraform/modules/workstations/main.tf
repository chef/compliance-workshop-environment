variable "suit" {}

variable "count" {
  default = "13"
}

variable "color" {
  default = ""
}

variable "automate_fqdn" {}
variable "contact_tag" {}
variable "aws_sshkey" {}
variable "workshop_prefix" {}
variable "workstation_ami" {}
variable "workstation_login_password" {}
variable "workstation_security_group" {}

variable "playing_cards" {
  type = "map"

  default = {
    "0"  = "02"
    "1"  = "03"
    "2"  = "04"
    "3"  = "05"
    "4"  = "06"
    "5"  = "07"
    "6"  = "08"
    "7"  = "09"
    "8"  = "10"
    "9"  = "jack"
    "10" = "queen"
    "11" = "king"
    "12" = "ace"
  }
}

resource "aws_instance" "workstation" {
  count                  = "${var.count}"
  ami                    = "${var.workstation_ami}"
  key_name               = "${var.aws_sshkey}"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${var.workstation_security_group}"]

  root_block_device {
    delete_on_termination = true
  }

  connection {
    type = "ssh"
    user = "centos"
    timeout = "2m"
    agent = true
  }

  tags {
    X-Dept    = "Sales"
    X-Contact = "${var.contact_tag}"
    Name = "${var.workshop_prefix}-workshop-station-${var.color}-${var.suit}-${lookup(var.playing_cards, count.index)}"
  }

  provisioner "file" {
    destination = "/tmp/config.rb"

    content = <<EOL
node_name "${var.color}-${var.suit}-${lookup(var.playing_cards, count.index)}"
data_collector.server_url "https://${var.automate_fqdn}/data-collector/v0/"
data_collector.token "93a49a4f2482c64126f7b6015e6b0f30284287ee4054ff8807fb63d9cbd1c506"
ssl_verify_mode :verify_none
verify_api_cert false
EOL
  }

  provisioner "remote-exec" {
    inline = [
      "sudo usermod --password '${var.workstation_login_password}' chef",
      "sudo mkdir -p /home/chef/.chef",
      "sudo cp /tmp/config.rb /home/chef/.chef/config.rb",
      "sudo chown -R chef:chef /home/chef",
      "sudo -i -u chef chef-client -z",
      "sudo sed -i.bak 's/^PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config",
      "sudo systemctl restart sshd"
    ]
  }
}