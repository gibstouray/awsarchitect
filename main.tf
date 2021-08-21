provider "aws"{ 
    region = var.aws_region
}

output "current_region"{
    value = var.aws_region
}

output "vpcidr"{
    value = var.vpcidr
}

output "publicsubnet"{
    value = var.public_subnet
}