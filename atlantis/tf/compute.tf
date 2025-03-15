# EKSクラスターの作成
resource "aws_eks_cluster" "atlantis_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.eks_version

  vpc_config {
    subnet_ids              = concat(aws_subnet.private[*].id, aws_subnet.public[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

# EKSノードグループの作成
resource "aws_eks_node_group" "atlantis_nodes" {
  cluster_name    = aws_eks_cluster.atlantis_cluster.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = [var.node_instance_type]

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ec2_container_registry_read
  ]
}

# Kubernetes Namespace for Atlantis
resource "kubernetes_namespace" "atlantis" {
  metadata {
    name = "atlantis"
  }

  depends_on = [aws_eks_node_group.atlantis_nodes]
}

# Helm chart for Atlantis
resource "helm_release" "atlantis" {
  name       = "atlantis"
  repository = "https://runatlantis.github.io/helm-charts"
  chart      = "atlantis"
  namespace  = kubernetes_namespace.atlantis.metadata[0].name
  version    = "4.10.3"  # 最新バージョンを確認してください
  values = [
    // repo-config.yamlのすべての内容をHelmのvaluesとして使用
    file("../values.yaml")
  ]
  timeout = 1200

  # set {
  #   name  = "orgAllowlist"
  #   value = tostring(var.atlantis_repo_allowlist)
  # }

  # set {
  #   name  = "github.user"
  #   value = tostring(var.github_user)
  # }

  # set {
  #   name  = "github.token"
  #   value = tostring(var.github_token)
  # }

  # set {
  #   name  = "github.secret"
  #   value = tostring(var.github_webhook_secret)
  # }

  # set {
  #   name  = "service.type"
  #   value = "LoadBalancer"
  # }

  depends_on = [kubernetes_namespace.atlantis]
}
