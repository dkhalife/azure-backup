# 🐋 Docker Image Documentation

This repository contains a Docker image designed to automate the process of backing up files to Azure storage via Virtual Machines in a cost-effective manner. The image is intended for users who need to have a secure way of copying files without encuring a large cost.

## 🔃 Backup process

The Docker image provides a script that:
1. Boots an Azure VM with the specified configuration.
2. Retrieves the public IP address of the VM.
3. Waits for the VM to become fully operational.
4. Uses `rsync` to securely back up files to the VM.
5. Deallocates the VM after the backup process is completed to minimize costs.

## ⚙️ Environment Variables

The following environment variables are required to use this Docker image:

| Environment Variable      | Description                                                                 |
|---------------------------|-----------------------------------------------------------------------------|
| `AZURE_TENANT_ID`         | The Azure tenant ID where the resources are located                         |
| `AZURE_SUBSCRIPTION_ID`   | The Azure subscription ID for the resources.                                |
| `AZURE_RESOURCE_GROUP`    | The Azure resource group containing the resources.                          |
| `AZURE_APP_ID`            | The Azure application ID for the service principal.                         |
| `AZURE_SPN_CERT_PATH`     | The file path to the service principal certificate.                         |
| `AZURE_IP_ADDRESS_NAME`   | The name of the public IP address resource in Azure.                        |
| `AZURE_VM_NAME`           | The name of the virtual machine in Azure.                                   |
| `SSH_USER`                | The SSH username for connecting to the virtual machine.                     |
| `SSH_KEY`                 | The file path to the private SSH key used for authentication.               |

## 🖥️ Setting Up an Azure VM

To use this Docker image, you need to set up an Azure VM with the necessary configuration. Follow these steps:

1. **Create an Azure Resource Group**:
   ```bash
   az group create --name <RESOURCE_GROUP> --location <LOCATION>
   ```

2. **Create a VM**:
   ```bash
   az vm create \
     --resource-group <RESOURCE_GROUP> \
     --name <VM_NAME> \
     --image <VM_IMAGE> \
     --size <VM_SIZE> \
     --admin-username <USERNAME> \
     --generate-ssh-keys
   ```

3. **Attach a Disk (Recommended)**:
   ```bash
   az vm disk attach \
     --resource-group <RESOURCE_GROUP> \
     --vm-name <VM_NAME> \
     --size-gb <DISK_SIZE_GB>
   ```

4. **Run the Script**:
   Use the Docker image to execute your script on the VM.

## 📝 Notes

- Ensure that the Azure Service Principal used for authentication has sufficient permissions to create and manage resources.
