resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus"
  namespace        = "monitoring"
  create_namespace = true
  version          = "25.16.0"

  values = [
    templatefile("${path.module}/prometheus.yaml", {
      environment = var.environment
    })
  ]
}

resource "helm_release" "grafana" {
  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  namespace        = "monitoring"
  create_namespace = true
  version          = "7.0.3"

  values = [
    templatefile("${path.module}/grafana.yaml", {
      admin_password = var.grafana_admin_password
      environment    = var.environment
    })
  ]
}