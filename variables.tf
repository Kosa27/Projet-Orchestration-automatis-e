variable "aws_region" {
  default = "us-east-1"
}

variable "account_id" {
  type = string
}

variable "app_name" {
  default = "web-ipssi"
}

variable "app_image_ecr" {
  type = string
}

variable "app_image_k8s" {
  default = "nginxdemos/hello:plain-text"
}

variable "kubeconfig_path" {
  default = "~/.kube/config"
}

variable "kube_context" {
  default = "minikube"
}
