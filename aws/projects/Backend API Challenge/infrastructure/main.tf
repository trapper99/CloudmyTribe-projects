resource "aws_dynamodb_table" "resume_table" {
    name = var.dynamodb_table_name
    hash_key = "id"
    billing_mode = "PROVISIONED"

    attribute {
        name = "id"
        type = "S"
    }
}

# Read data.json content and create DynamoDB item content
locals {
  #TODO: Add file path to data.json file in the arguments
  data_content = file("")
}

# Add items to DynamoDB table using item id from local block.
resource "aws_dynamodb_table_item" "resume_json" {
    table_name = aws_dynamodb_table.resume_table.name
    hash_key = "id"

    item = local.data_content

    depends_on = [ aws_dynamodb_table.resume_table ]
}

# Create s3 bucket
resource "aws_s3_bucket" "cloud_resume_bucket" {
    bucket = var.s3_bucket_name

}

#Create Lambda function with python runtime
resource "aws_lambda_function" "resume_lambda" {
    function_name = var.lambda_function_name
    runtime = "python3.9"
    handler = "lambda_function.lambda_handler"
    #TODO: Add role to lambda function in arguments
    role = ""
    filename = ""
    depends_on = [ aws_dynamodb_table.resume_table ]
}

# Create IAM role for lambda 
resource "aws_iam_role" "resume_lambda_role" {
    name = var.lambda_role_name.value

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Sid    = ""
                Principal = {
                    Service = "lambda.amazonaws.com"
                },
        
            },
              
        ]
    })
}

# Attaching a lambda policy to the lambda IAM role
resource "aws_iam_role_policy" "resume_lambda_policy" {
    name = "resumeLambdaPolicy"
    role = aws_iam_role.resume_lambda_role.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
                Effect = "Allow"
                Resource = "*"
            },
            {
                Action = ["dynamodb:GetItem", "dynamodb:Scan"]
                Effect = "Allow"
                Resource = "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/${var.dynamodb_table_name}"
            }
        ]
    })
}

# Create api gateway of REST API type
resource "aws_api_gateway_rest_api" "resume_api" {
    name = var.api_gateway_name
    description = "API to get resume content from DynamoDB table"
}

# Create a resource method for the API gateway
resource "aws_api_gateway_resource" "resume_resource" {
    rest_api_id = aws_api_gateway_rest_api.resume_api.id
    parent_id = aws_api_gateway_rest_api.resume_api.root_resource_id
    path_part = "resume"
}

# Create a GET method for the API gateway
resource "aws_api_gateway_method" "resume_get" {
    rest_api_id = aws_api_gateway_rest_api.resume_api.id
    resource_id = aws_api_gateway_resource.resume_resource.id
    http_method = "GET"
    authorization = "NONE"
}

# Create integration between API gateway and Lambda
resource "aws_api_gateway_integration" "api_lambda_integration" {
    rest_api_id = aws_api_gateway_rest_api.resume_api.id
    resource_id = aws_api_gateway_resource.resume_resource.id
    http_method = aws_api_gateway_method.resume_get.http_method
    type = "AWS_PROXY"
    integration_http_method = "POST"
    uri = aws_lambda_function.resume_lambda.invoke_arn
}

# Explicitly allowing API gateway to invoke Lambda
resource "aws_lambda_permission" "resume_lambda_permission" {
    statement_id = "AllowExecutionFromAPIGateway"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.resume_lambda.function_name
    principal = "apigateway.amazonaws.com"
    source_arn = "${aws_api_gateway_rest_api.resume_api.arn}/*/*"
}