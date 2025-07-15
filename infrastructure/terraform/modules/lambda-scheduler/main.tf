# Lambda function for EC2 start/stop
resource "aws_lambda_function" "ec2_scheduler" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-${var.environment}-ec2-scheduler"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "python3.9"
  timeout         = 60

  environment {
    variables = {
      INSTANCE_ID = var.instance_id
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-scheduler"
  }
}

# Create the Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "/tmp/lambda_function.zip"
  source {
    content = templatefile("${path.module}/lambda_function.py", {
      instance_id = var.instance_id
    })
    filename = "index.py"
  }
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-${var.environment}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Events for scheduling
resource "aws_cloudwatch_event_rule" "start_schedule" {
  name                = "${var.project_name}-${var.environment}-start-schedule"
  description         = "Start EC2 instance"
  schedule_expression = var.start_schedule

  tags = {
    Name = "${var.project_name}-${var.environment}-start-schedule"
  }
}

resource "aws_cloudwatch_event_rule" "stop_schedule" {
  name                = "${var.project_name}-${var.environment}-stop-schedule"
  description         = "Stop EC2 instance"
  schedule_expression = var.stop_schedule

  tags = {
    Name = "${var.project_name}-${var.environment}-stop-schedule"
  }
}

# CloudWatch Event targets
resource "aws_cloudwatch_event_target" "start_target" {
  rule      = aws_cloudwatch_event_rule.start_schedule.name
  target_id = "StartInstanceTarget"
  arn       = aws_lambda_function.ec2_scheduler.arn

  input = jsonencode({
    action = "start"
  })
}

resource "aws_cloudwatch_event_target" "stop_target" {
  rule      = aws_cloudwatch_event_rule.stop_schedule.name
  target_id = "StopInstanceTarget"
  arn       = aws_lambda_function.ec2_scheduler.arn

  input = jsonencode({
    action = "stop"
  })
}

# Lambda permissions for CloudWatch Events
resource "aws_lambda_permission" "allow_start_event" {
  statement_id  = "AllowExecutionFromCloudWatchStart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_schedule.arn
}

resource "aws_lambda_permission" "allow_stop_event" {
  statement_id  = "AllowExecutionFromCloudWatchStop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_schedule.arn
}