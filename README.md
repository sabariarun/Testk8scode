# Kubernetes Cluster Setup with Terraform and AWS EC2
This Terraform project automates the creation of a Kubernetes cluster on AWS EC2 instances. It includes a master node and a worker node.

## Prerequisites
1. Terraform installed.
1. An AWS account with the necessary access keys.
1. Visual Studio Code installed with the Remote - SSH extension.
1. SSH key pair created and configured on AWS.

## Configuration
1. Clone this repository and navigate to the project directory.

1. Update the **variables.tf** file with your desired configuration, such as region, instance type, and key pair name.

1. In the `master.sh` and `worker.sh` files, replace the version numbers of kubelet, kubeadm, and kubectl with the desired versions.

> Note: You should save your key-pair at `C:\Users\Admin\.ssh\`

## Usage
1. `init`ialize and `apply` the Terraform commands

1. Get the master-node public DNS address information from `outputs` and paste/change it into below `SSH Configuration file`'s `HostName`

1. Update the SSH configuration in Visual Studio Code:
    - Open VS Code and select the remote window icon in the lower-left corner.
    - Choose Open `SSH Configuration file...` and select the config file located in your `.ssh` directory.
    - Paste the following content, replacing the `HostName` value with the master_public_dns output from Terraform:

    ```
    Host MasterEC2
        HostName ec2-44-204-163-213.compute-1.amazonaws.com
        IdentityFile C:\Users\Admin\.ssh\<your-key-pair-name>.pem # Change here! and check your 'key-pair' name on main.tf
        User ubuntu
    Host *
        TCPKeepAlive yes
        ServerAliveInterval 120
    ```

    > **IMPORTANT**: Make sure the instance's state is ready!

1. Connect to the master node:

    - Open the remote window in VS Code (click the >< green icon).
    - Select Connect to Host.
    - Choose `MasterEC2`.

    > **Note**: Make sure the instance's state is ready!


1. When you're finished, do not forget to `destroy` the infrastructure.

#### Notes
The project assumes you have the necessary AWS access keys set up in your environment.
The Terraform state file is stored locally; for production use, consider using remote state storage.
