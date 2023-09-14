
provider "aws" {
  region  = var.region
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  name = "bronze"   # change here, optional
}

resource "aws_instance" "master" {
  ami                  = var.ami_name
  instance_type        = var.instance_type
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2connectprofile.name
  security_groups      = ["${local.name}-k8s-master-sec-gr"]
  user_data              = <<-EOF
  #!/bin/bash
  sudo apt update -y
  sudo apt install docker.io -y
  sudo systemctl enable docker.service
  sudo usermod -aG docker ubuntu
  sudo apt install -y apt-transport-https curl
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add
  sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
  sudo apt update -y
  sudo apt install -y kubelet kubeadm kubectl
  sudo sysctl -w net.ipv4.ip_forward=1
  sudo sed -i 's/net.ipv4.ip_forward=0/net.ipv4.ip_forward=1/Ig' /etc/sysctl.conf
  # Ignore preflight in order to have master running on t2.micro, otherwise remove it 
  sudo kubeadm init --token ${local.token} \
  --pod-network-cidr=10.244.0.0/16 \
  --service-cidr=10.96.0.0/12 \
  --ignore-preflight-errors=all
  sleep 30
  sudo mkdir -p /home/ubuntu/.kube ~/.kube
  sudo cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
  sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config
  sudo export KUBECONFIG=/etc/kubernetes/admin.conf
  sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
  # while [[ $(kubectl -n kube-system get pods -l k8s-app=kube-dns -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do sleep 5; done
  EOF

  tags = {
    Name = "${local.name}-kube-master"
  }
}

resource "aws_instance" "worker" {
  ami                  = var.ami_name
  instance_type        = var.instance_type
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2connectprofile.name
  security_groups      = ["${local.name}-k8s-master-sec-gr"]
  #!/bin/bash
  sudo apt update -y
  sudo apt install docker.io -y
  sudo systemctl enable docker.service
  sudo usermod -aG docker ubuntu
  sudo apt install -y apt-transport-https curl
  sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add
  sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
  sudo apt update -y
  sudo apt install -y kubelet kubeadm kubectl
  sudo sysctl -w net.ipv4.ip_forward=1
  sudo sed -i 's/net.ipv4.ip_forward=0/net.ipv4.ip_forward=1/Ig' /etc/sysctl.conf
  sudo kubeadm join ${aws_instance.Master-Node.private_ip}:6443 \
  --token ${local.token} \
  --discovery-token-unsafe-skip-ca-verification
  EOF
  tags = {
    Name = "${local.name}-kube-worker"
  }
  

resource "aws_iam_instance_profile" "ec2connectprofile" {
  name = "ec2connectprofile-pro-${local.name}"
  role = aws_iam_role.ec2connectcli.name
}

resource "aws_iam_role" "ec2connectcli" {
  name = "ec2connectcli-${local.name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "my_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          "Effect" : "Allow",
          "Action" : "ec2-instance-connect:SendSSHPublicKey",
          "Resource" : "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*",
          "Condition" : {
            "StringEquals" : {
              "ec2:osuser" : "ubuntu"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : "ec2:DescribeInstances",
          "Resource" : "*"
        }
      ]
    })
  }
}

data "template_file" "worker" {
  template = file("worker.sh")
  vars = {
    region = data.aws_region.current.name
    master-id = aws_instance.master.id
    master-private = aws_instance.master.private_ip
  }

}

data "template_file" "master" {
  template = file("master.sh")
}

resource "aws_security_group" "tf-k8s-master-sec-gr" {
  name = "${local.name}-k8s-master-sec-gr"
  tags = {
    Name = "${local.name}-k8s-master-sec-gr"
  }

  ingress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    self = true
  }

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
    ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
