terraform {
  required_version = "1.14.9"

  cloud {
    
    organization = "suvham"

    workspaces {
      name = "ssh-key-manager"
    }
  }
}

variable "ssh_user" {
  default = "azureuser"
}

variable "ssh_private_key_path" {
  default = "~/.ssh/id_ed25519"
}

variable "public_keys_file" {
  description = "Path to file containing public keys, one per line"
  default     = "keys.txt"
}

locals {
  node_ips = ["10.0.0.7", "10.0.0.8"]
}

resource "terraform_data" "copy_ssh_keys" {
  for_each = toset(local.node_ips)
  
  triggers_replace = {
    file_hash = filemd5("keys.txt")
  }
  
  connection {
    type        = "ssh"
    host        = each.value
    user        = var.ssh_user
    private_key = file(var.ssh_private_key_path)
  }

  provisioner "file" {
    source      = var.public_keys_file
    destination = "/tmp/new_keys.txt"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p ~/.ssh",
      "chmod 700 ~/.ssh",
      "cat /tmp/new_keys.txt > ~/.ssh/authorized_keys",
      "sort -u ~/.ssh/authorized_keys -o ~/.ssh/authorized_keys",
      "chmod 600 ~/.ssh/authorized_keys"
    ]
  }
}