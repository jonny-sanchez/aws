resource "aws_lambda_function" "manage_resources" {
  function_name    = "${local.config.environment}-scheduler-lambda"
  filename         = data.archive_file.scheduler_lambda_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.scheduler_lambda_zip.output_path)
  handler          = "scheduler.lambda_handler"
  runtime          = "python3.13"
  timeout          = 900
  role             = aws_iam_role.lambda_exec_role.arn
}

resource "aws_lambda_permission" "allow_eventbridge_rds_on" {
  statement_id  = "AllowExecutionFromEventBridgeRdsOn"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.manage_resources.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scheduler_rds_on_rule.arn
}

resource "aws_lambda_permission" "allow_eventbridge_ec2_on" {
  statement_id  = "AllowExecutionFromEventBridgeEc2On"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.manage_resources.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scheduler_ec2_on_rule.arn
}

resource "aws_lambda_permission" "allow_eventbridge_off" {
  statement_id  = "AllowExecutionFromEventBridgeOff"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.manage_resources.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scheduler_off_rule.arn
}
