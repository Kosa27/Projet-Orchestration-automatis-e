module "ecs" {
  source     = "./modules/ecs"
  app_name   = var.app_name
  account_id = var.account_id
  image      = var.app_image_ecr
}

module "k8s" {
  source     = "./modules/k8s"
  app_name   = var.app_name
  image      = var.app_image_k8s
  namespace  = "projet"
  replicas   = 2
}
