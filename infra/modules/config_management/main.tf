# Non-secret settings that the Ansible playbook needs. Terraform knows these
# values, so it writes them next to the playbooks; servers download both.
resource "aws_s3_object" "vars" {
  bucket       = var.artifacts_bucket
  key          = "config/vars.yml"
  content_type = "text/yaml"

  content = yamlencode({
    region             = var.region
    ecr_repository_url = var.ecr_repository_url
    db_secret_arn      = var.db_secret_arn
    app_secret_arn     = var.app_secret_arn
    image_tag          = var.image_tag
  })
}

# Systems Manager document: "apply the Ansible configuration to this server".
# Used for deployments (from the pipeline) and by the scheduled association below.
resource "aws_ssm_document" "apply_ansible" {
  name            = "${var.name}-apply-ansible"
  document_type   = "Command"
  document_format = "YAML"

  content = <<-EOT
    schemaVersion: "2.2"
    description: Download the playbooks from S3 and apply them to this server
    parameters:
      BucketName:
        type: String
        description: Bucket that holds the Ansible playbooks
      Region:
        type: String
        description: AWS region
      ImageTag:
        type: String
        description: Docker image tag to deploy
        default: latest
    mainSteps:
      - action: aws:runShellScript
        name: applyAnsible
        inputs:
          timeoutSeconds: "900"
          runCommand:
            - "set -euo pipefail"
            - "export HOME=/root"
            - "command -v ansible-playbook >/dev/null || dnf install -y ansible-core"
            - "mkdir -p /opt/ansible"
            - "aws s3 sync s3://{{ BucketName }}/ansible/ /opt/ansible/ --delete --exclude vars.yml --region {{ Region }}"
            - "aws s3 cp s3://{{ BucketName }}/config/vars.yml /opt/ansible/vars.yml --region {{ Region }}"
            - "cd /opt/ansible && ansible-playbook -i localhost, -c local site.yml -e @vars.yml -e image_tag={{ ImageTag }}"
  EOT
}

# State Manager: re-apply the configuration every hour, which also
# repairs any manual change made on a server (drift correction).
resource "aws_ssm_association" "ansible" {
  association_name = "${var.name}-ansible-config"
  name             = aws_ssm_document.apply_ansible.name

  targets {
    key    = "tag:Role"
    values = ["app"]
  }

  schedule_expression         = "cron(0 0/30 * 1/1 * ? *)"
  apply_only_at_cron_interval = true

  parameters = {
    BucketName = var.artifacts_bucket
    Region     = var.region
    ImageTag   = var.image_tag
  }
}

# Patch Manager: weekly scan that reports missing OS updates in the console
resource "aws_ssm_association" "patch_scan" {
  association_name = "${var.name}-patch-scan"
  name             = "AWS-RunPatchBaseline"

  targets {
    key    = "tag:Role"
    values = ["app"]
  }

  schedule_expression         = "cron(0 3 ? * SUN *)"
  apply_only_at_cron_interval = true

  parameters = {
    Operation = "Scan"
  }
}
