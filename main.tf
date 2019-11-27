variable "path_to_key" {
  type = string
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_all_to_ssh"
  }
}


data "aws_ami" "centos" {
  most_recent = true

  filter {
    name   = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS *"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["679593333241"]
}


resource "aws_instance" "web" {
  ami           = "${data.aws_ami.centos.id}"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.allow_ssh.id}"]
  key_name = "main_key"
  root_block_device {
    delete_on_termination = true
  }
#  user_data = "yum update"
#
# provisioner "file" {
#   source      = "script.sh"
#   destination = "/tmp/script.sh"
# }
#
  provisioner "remote-exec" {
    inline = [
      "sudo yum update >> /tmp/update_log",
      "echo The server's IP address is ${self.private_ip}",
     ]
    connection {
    type     = "ssh"
    user     = "centos"
    private_key = file(var.path_to_key)
    host     = "${self.public_ip}"
    }
  }
  tags = {
    Name = "HelloWorld"
  }
}
