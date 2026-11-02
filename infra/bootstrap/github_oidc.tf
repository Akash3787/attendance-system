# Lets GitHub Actions log in to AWS without any stored access keys (OIDC).
# GitHub proves who it is with a short-lived token, and AWS hands back
# temporary credentials only to workflows running on the main branch of our repo.
# Lives in bootstrap so it survives `terraform destroy` of the main stack.

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "github_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "attendance-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_assume.json
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

resource "aws_iam_role_policy" "github_actions" {
  name   = "attendance-github-actions-policy"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_permissions.json
}
