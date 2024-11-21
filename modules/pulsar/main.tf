provider "kubernetes" {
  host                   = aws_eks_cluster.pulsar_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.pulsar_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.pulsar_cluster.token

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      aws_eks_cluster.pulsar_cluster.name
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.pulsar_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.pulsar_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.pulsar_cluster.token

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        aws_eks_cluster.pulsar_cluster.name
      ]
    }
  }
}

data "aws_eks_cluster_auth" "pulsar_cluster" {
  name = aws_eks_cluster.pulsar_cluster.name

}

resource "aws_eks_cluster" "pulsar_cluster" {
  name     = "pulsar-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids              = aws_subnet.private_subnets[*].id
    security_group_ids      = [aws_security_group.pulsar_sg.id]
    endpoint_private_access = true
    endpoint_public_access  = false
  }


  access_config {
    authentication_mode                         = "CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  bootstrap_self_managed_addons = false
}

resource "aws_eks_node_group" "pulsar_node_group" {
  cluster_name    = aws_eks_cluster.pulsar_cluster.name
  node_group_name = "pulsar-node-group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = aws_subnet.private_subnets[*].id

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }

  remote_access {
    ec2_ssh_key = aws_key_pair.pulsar_key_pair.key_name
  }

  instance_types = ["t2.micro"]

  tags = {
    Environment = var.environment
  }

  depends_on = [
    aws_eks_cluster.pulsar_cluster
  ]
}

resource "helm_release" "pulsar" {
  name             = "pulsar"
  chart            = "pulsar"
  repository       = "https://pulsar.apache.org/charts"
  namespace        = "pulsar"
  create_namespace = true
  version          = "3.7.0"

  values = [
    templatefile("${path.module}/apache-pulsar.yaml", {
      s3_bucket      = aws_s3_bucket.pulsar_offload.id
      s3_region      = aws_s3_bucket.pulsar_offload.region
      environment    = var.environment
      proxy_tls_cert = tls_self_signed_cert.mqtt_cert.cert_pem
      proxy_tls_key  = tls_private_key.mqtt_key.private_key_pem
    })
  ]
}

resource "kubernetes_service_account" "pulsar_service_account" {
  metadata {
    name      = "pulsar-sa"
    namespace = "pulsar"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.eks_node_group_role.arn
    }
  }
}
