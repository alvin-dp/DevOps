variable "path_to_key" {
  type = string
}
variable "path_to_ngix_repo" {
  type = string
}
variable "path_to_jenkins_repo" {
  type = string
}
variable "path_to_nginx_conf" {
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

  ingress {
    from_port   = 80
    to_port     = 80
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

output "ip" {
  value = "${aws_instance.web.public_ip}"
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

  provisioner "file" {
    source      = var.path_to_nginx_conf
    destination = "/tmp/nginx_default.conf"

    connection {
    type     = "ssh"
    user     = "centos"
    private_key = file(var.path_to_key)
    host     = "${self.public_ip}"
    } 
  }

  provisioner "remote-exec" {
    inline = [
      "sudo setenforce 0",
      "echo '${file(var.path_to_ngix_repo)}' > /tmp/nginx.repo",
      "sudo cp /tmp/nginx.repo /etc/yum.repos.d/nginx.repo",
      "echo '${file(var.path_to_jenkins_repo)}' >/tmp/jenkins.repo",
      "sudo cp /tmp/jenkins.repo /etc/yum.repos.d/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key",
      "sudo yum -y install nginx",      
      "sudo yum -y install java-1.8.0-openjdk",
      "sudo yum -y install jenkins",
      "sudo cp /tmp/nginx_default.conf /etc/nginx/conf.d/default.conf",
      "sudo service jenkins start",
      "sudo systemctl start nginx",
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
