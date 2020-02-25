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
variable "path_to_rundeck_service" {
  type = string
}
variable "path_to_jenkins_conf" {
  type = string
}
variable "rundeck_version" {
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
output "ssh" {
  value = "centos@${aws_instance.web.public_ip}"
}
output "link_to_jenkins" {
  value = "http://${aws_instance.web.public_dns}/jenkins"
}
output "link_to_rundeck" {
  value = "http://${aws_instance.web.public_dns}/rundeck"
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

  connection {
    type     = "ssh"
    user     = "centos"
    private_key = file(var.path_to_key)
    host     = "${self.public_ip}"
    } 
 
  provisioner "file" {
    content = "${templatefile(var.path_to_nginx_conf, {server_name = "${self.public_ip}",internal_dns_name = "${self.private_dns}"})}"
    destination = "/tmp/nginx.conf"
  }
  provisioner "file" {
    content = "${templatefile(var.path_to_rundeck_service, {rundeck_args = "-Dserver.contextPath=/rundeck  -Dgrails.serverURL=${self.private_dns}/rundeck",rundeck_version = var.rundeck_version})}"    
    destination = "/tmp/rundeck.service"
  }  

  provisioner "file" {
    content = "${templatefile(var.path_to_jenkins_conf, {jenkins_args = "--prefix=/jenkins"})}"
    destination = "/tmp/jenkins.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo setenforce 0",
      "sudo yum -y install wget",      
      "echo '${file(var.path_to_ngix_repo)}' > /tmp/nginx.repo",
      "sudo cp /tmp/nginx.repo /etc/yum.repos.d/nginx.repo",
      "echo '${file(var.path_to_jenkins_repo)}' >/tmp/jenkins.repo",
      "sudo cp /tmp/jenkins.repo /etc/yum.repos.d/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key",
      "sudo yum -y install nginx",            
      "sudo yum -y install java-1.8.0-openjdk",
      "sudo yum -y install jenkins",
      "sudo cp /tmp/nginx.conf /etc/nginx/conf.d/default.conf",
      "mkdir ~/rundeck",
      "cd ~/rundeck/",
      "wget https://dl.bintray.com/rundeck/rundeck-maven/rundeck-'${var.rundeck_version}'.war",
      "sudo mkdir /opt/rundeck",
      "sudo cp ~/rundeck/* /opt/rundeck/",
      "rm -r ~/rundeck",
      "sudo cp /tmp/rundeck.service /etc/systemd/system/",
      "sudo systemctl start rundeck",
      "sudo cp /tmp/jenkins.conf /etc/sysconfig/jenkins",
      "sudo systemctl start jenkins",      
      "sudo systemctl start nginx",
     ]
  }
  
 tags = {
    Name = "HelloWorld"
    backend = "s3"
  }
}
