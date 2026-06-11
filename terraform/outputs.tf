output "jenkins_url" {
  value = "http://${aws_eip.jenkins.public_ip}:8080"
}

output "jenkins_webhook_url" {
  value = "http://${aws_eip.jenkins.public_ip}:8080/github-webhook/"
}

# output "ecr_url" {
#   value = aws_ecr_repository.app.repository_url
# }

output "eks_cluster_name" {
  value = module.eks.cluster_name
}