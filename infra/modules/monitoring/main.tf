# Grafana admin password: generated here, stored in Secrets Manager
resource "random_password" "grafana" {
  length  = 20
  special = false
}

resource "aws_secretsmanager_secret" "grafana" {
  name                    = "${var.name}/grafana-admin"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "grafana" {
  secret_id = aws_secretsmanager_secret.grafana.id

  secret_string = jsonencode({
    admin_user     = "admin"
    admin_password = random_password.grafana.result
  })
}

# Non-secret settings for the monitoring playbook
resource "aws_s3_object" "vars" {
  bucket       = var.artifacts_bucket
  key          = "config/monitoring-vars.yml"
  content_type = "text/yaml"

  content = yamlencode({
    region             = var.region
    grafana_secret_arn = aws_secretsmanager_secret.grafana.arn
  })
}

# ---- IAM ----
data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "monitoring" {
  name               = "${var.name}-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "monitoring" {
  # Lets Prometheus find the app servers automatically (read-only)
  statement {
    sid       = "DiscoverServers"
    actions   = ["ec2:DescribeInstances", "ec2:DescribeAvailabilityZones"]
    resources = ["*"]
  }

  statement {
    sid       = "ReadPlaybooks"
    actions   = ["s3:GetObject"]
    resources = ["${var.artifacts_bucket_arn}/*"]
  }

  statement {
    sid       = "ListPlaybooks"
    actions   = ["s3:ListBucket"]
    resources = [var.artifacts_bucket_arn]
  }

  statement {
    sid       = "ReadGrafanaSecret"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.grafana.arn]
  }
}

resource "aws_iam_role_policy" "monitoring" {
  name   = "${var.name}-monitoring-policy"
  role   = aws_iam_role.monitoring.id
  policy = data.aws_iam_policy_document.monitoring.json
}

resource "aws_iam_instance_profile" "monitoring" {
  name = "${var.name}-monitoring-profile"
  role = aws_iam_role.monitoring.name
}

# ---- Server ----
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "monitoring" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.monitoring_sg_id]
  iam_instance_profile        = aws_iam_instance_profile.monitoring.name
  associate_public_ip_address = true # no NAT gateway, so it needs a public IP to pull images

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    region           = var.region
    artifacts_bucket = var.artifacts_bucket
  })
  user_data_replace_on_change = true

  tags = {
    Name = "${var.name}-monitoring"
    Role = "monitoring"
  }

  # The settings file must exist before the server boots
  depends_on = [aws_s3_object.vars, aws_secretsmanager_secret_version.grafana]
}
