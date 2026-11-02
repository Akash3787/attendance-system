output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "security_group_ids" {
  value = {
    alb = module.network.alb_sg_id
    app = module.network.app_sg_id
    db  = module.network.db_sg_id
  }
}
