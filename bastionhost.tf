data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [var.bastion_ami_name]
  }
}

resource "aws_instance" "bastion-host" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.bastion_instance_type
  subnet_id     = aws_subnet.public-subnet-A.id
  associate_public_ip_address = true



  vpc_security_group_ids = [aws_security_group.allow_ssh_bastion.id]

 
  key_name = "eks-pairs"

  user_data = <<EOF
#!/bin/bash
curl -LO https://dl.k8s.io/release/v1.23.6/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
apt update && apt install awscli -y 
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash -s -- --version v3.8.2
EOF

  tags = {
    Name = "bastion-host"
  }
}






resource "aws_security_group" "allow_ssh_bastion" {
  name        = "allow_ssh_bastion"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.eks-vpc.id

  ingress {
    description      = "ALLOW SSH FROM ANYWHERE"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  
    cidr_blocks = ["0.0.0.0/0"]
  }




  tags = {
    Name = "allow_ssh_bastion"
  }
}





