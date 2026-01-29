data "aws_caller_identity" "current" {}

data "archive_file" "scheduler_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambdas/scheduler.py"
  output_path = "${path.module}/lambdas/scheduler.zip"
}