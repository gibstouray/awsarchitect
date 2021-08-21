data "aws_region" "current" {}

variable "aws_region"{
    default = "eu-central-1"
}

variable "vpcidr"{
    default = "10.0.0.0/16"
}

variable "public_subnet"{
    
    default     = "10.0.1.0/24"
}

variable "private_subnet"{
    
    default     = "10.0.2.0/24"
}

# define your availability zones
variable "azs"{
    type = list
    default = ["eu-central-1a","eu-central-1b","eu-central-1c"]

}

# define the variable to hold the key pair

variable "keypair"{
    default     = "my_keys.pem"
}