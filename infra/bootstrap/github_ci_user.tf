# Deploy user for GitHub Actions.
# The account's organization policy blocks OpenID Connect (OIDC) providers,
# so the pipeline uses a dedicated IAM user whose access keys are stored as
# encrypted GitHub secrets. The access key itself is created outside Terraform
# so that the secret never ends up in the Terraform state.
resource "aws_iam_user" "github_actions" {
  name = "attendance-github-actions"
}

# Least privilege: the pipeline can push images, upload playbooks and
# trigger the Ansible deployment. It cannot create or delete infrastructure.
data "aws_iam_policy_document" "github_permissions" {
  statement {
    sid       = "EcrLogin"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "EcrPush"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [aws_ecr_repository.app.arn]
  }

  statement {
    sid       = "UploadPlaybooks"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.artifacts.arn}/ansible/*"]
  }

  statement {
    sid       = "ListPlaybookBucket"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.artifacts.arn]
  }

  statement {
    sid     = "RunAnsibleThroughSsm"
    actions = ["ssm:SendCommand"]
    resources = [
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:document/attendance-apply-ansible",
      "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/*",
    ]
  }

  statement {
    sid = "ReadDeploymentStatus"
    actions = [
      "ssm:ListCommandInvocations",
      "ssm:GetCommandInvocation",
      "ssm:ListCommands",
      "elasticloadbalancing:DescribeLoadBalancers",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "github_actions" {
  name   = "attendance-github-actions-policy"
  user   = aws_iam_user.github_actions.name
  policy = data.aws_iam_policy_document.github_permissions.json
}
