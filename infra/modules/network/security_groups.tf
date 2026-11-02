# Traffic chain: internet -> ALB -> app servers -> database.
# Each layer only accepts traffic from the layer in front of it.

resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Load balancer"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.name}-alb-sg" }
}

resource "aws_security_group" "app" {
  name        = "${var.name}-app-sg"
  description = "Application servers"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.name}-app-sg" }
}

resource "aws_security_group" "db" {
  name        = "${var.name}-db-sg"
  description = "Database"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.name}-db-sg" }
}

# ---- Load balancer ----
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from the internet"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Forward to app servers"
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

# ---- App servers ----
resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "App traffic from the load balancer only"
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

resource "aws_vpc_security_group_egress_rule" "app_https_out" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS out (ECR, SSM, Secrets Manager)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "app_http_out" {
  security_group_id = aws_security_group.app.id
  description       = "HTTP out (OS package repositories)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "app_to_db" {
  security_group_id            = aws_security_group.app.id
  description                  = "PostgreSQL to the database"
  referenced_security_group_id = aws_security_group.db.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

# ---- Database ----
resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  description                  = "PostgreSQL from app servers only"
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

# ---- Monitoring server (Prometheus + Grafana) ----
# No inbound rules at all: dashboards are reached through an SSM port-forward
# session, so no monitoring port is ever exposed to the internet.
resource "aws_security_group" "monitoring" {
  name        = "${var.name}-monitoring-sg"
  description = "Monitoring server"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.name}-monitoring-sg" }
}

resource "aws_vpc_security_group_egress_rule" "monitoring_https_out" {
  security_group_id = aws_security_group.monitoring.id
  description       = "HTTPS out (AWS APIs, container images)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "monitoring_http_out" {
  security_group_id = aws_security_group.monitoring.id
  description       = "HTTP out (OS package repositories)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "monitoring_to_node_exporter" {
  security_group_id            = aws_security_group.monitoring.id
  description                  = "Scrape node_exporter on app servers"
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = 9100
  to_port                      = 9100
}

resource "aws_vpc_security_group_egress_rule" "monitoring_to_app_metrics" {
  security_group_id            = aws_security_group.monitoring.id
  description                  = "Scrape app metrics"
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

resource "aws_vpc_security_group_ingress_rule" "app_node_exporter_from_monitoring" {
  security_group_id            = aws_security_group.app.id
  description                  = "node_exporter from the monitoring server only"
  referenced_security_group_id = aws_security_group.monitoring.id
  ip_protocol                  = "tcp"
  from_port                    = 9100
  to_port                      = 9100
}

resource "aws_vpc_security_group_ingress_rule" "app_metrics_from_monitoring" {
  security_group_id            = aws_security_group.app.id
  description                  = "App metrics from the monitoring server only"
  referenced_security_group_id = aws_security_group.monitoring.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}
