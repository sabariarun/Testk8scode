variable "region" {
  default = "us-east-1"
}
variable "ami_name" {
  default = "ami-0557a15b87f6559cf"
}
variable "instance_type" {
  default = "t3a.medium"
}
variable "key_name" {
  description = "The key pair name for the EC2 instances"
  default = "mat-ec2-key"   # change here and also change the configuration file while connecting remote
}
