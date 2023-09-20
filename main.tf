
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
  user_data            = data.template_file.master.rendered
  tags = {
    Name = "${local.name}-kube-master"
  }
}
connection {
        master_user = "ubuntu"
        master_host = aws_instance.master.public_ip
        user = "ec2-user"
        host = self.private_ip
        timeout = "60s"
      }
 provisioner "file" {
    source      = "master.sh"
    destination = "/tmp/master.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/master.sh",
      "/tmp/master.sh args",
    ]
}
  resource "aws_instance" "worker" {
  ami                  = var.ami_name
  instance_type        = var.instance_type
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2connectprofile.name
  security_groups      = ["${local.name}-k8s-master-sec-gr"]
  user_data            = data.template_file.worker.rendered
  tags = {
    Name = "${local.name}-kube-worker"
  }
  depends_on = [aws_instance.master]
}
connection {
        worker_user = "ubuntu"
        worker_host = aws_instance.worker.public_ip
        user = "ec2-user"
        host = self.private_ip
        timeout = "60s"
      }
 provisioner "file" {
    source      = "worker.sh"
    destination = "/tmp/worker.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/worker.sh",
      "/tmp/worker.sh args",
    ]
  }
resource "aws_iam_instance_profile" "ec2connectprofile" {
  name = "ec2connectprofile-88-${local.name}"
  role = aws_iam_role.ec2connectcli.name
}

resource "aws_iam_role" "ec2connectcli" {
  name = "ec2connectcli-Profile12-${local.name}"
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
