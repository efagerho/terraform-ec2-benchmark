output "first_instance_ips" {
  value = module.first[*].public_ip
}

output "second_instance_ips" {
  value = module.second[*].public_ip
}

output "third_instance_ips" {
  value = module.third[*].public_ip
}
