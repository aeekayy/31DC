# Specify the provider and access details
resource "aws_api_gateway_rest_api" "slackWebhook" {
	name = "dcSlackWebhook"
	description = "Webhook for Slack ChatOps."
}

resource "aws_api_gateway_resource" "dc_slack_api_res" {
	rest_api_id = "${aws_api_gateway_rest_api.slackWebhook.id}"
	parent_id   = "${aws_api_gateway_rest_api.slackWebhook.root_resource_id}"
	path_part   = "webhook"
}

resource "aws_api_gateway_method" "method" {
	rest_api_id   = "${aws_api_gateway_rest_api.slackWebhook.id}"
	resource_id   = "${aws_api_gateway_rest_api.slackWebhook.root_resource_id}"
	http_method   = "POST"
	authorization = "NONE"
}

resource "aws_api_gateway_method" "webhook_method" {
        rest_api_id   = "${aws_api_gateway_rest_api.slackWebhook.id}"
        resource_id   = "${aws_api_gateway_resource.dc_slack_api_res.id}"
        http_method   = "POST"
        authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
	rest_api_id             = "${aws_api_gateway_rest_api.slackWebhook.id}"
	resource_id             = "${aws_api_gateway_rest_api.slackWebhook.root_resource_id}"
	http_method             = "${aws_api_gateway_method.method.http_method}"
	integration_http_method = "POST"
	type                    = "AWS"
	passthrough_behavior	= "WHEN_NO_MATCH"

 	uri                     = "${aws_lambda_function.dc_slack_api.invoke_arn}"
	request_templates	= { "application/json" = <<EOF
{
    "stage" : "$context.stage",
    "request_id" : "$context.requestId",
    "api_id" : "$context.apiId",
    "resource_path" : "$context.resourcePath",
    "resource_id" : "$context.resourceId",
    "http_method" : "$context.httpMethod",
    "source_ip" : "$context.identity.sourceIp",
    "user-agent" : "$context.identity.userAgent",
    "account_id" : "$context.identity.accountId",
    "caller" : "$context.identity.caller",
    "user" : "$context.identity.user",
    "user_arn" : "$context.identity.userArn",
    "body": $input.json('$')
}
EOF
	}
}

resource "aws_api_gateway_integration" "webhook_integration" {
	rest_api_id             = "${aws_api_gateway_rest_api.slackWebhook.id}"
        resource_id             = "${aws_api_gateway_resource.dc_slack_api_res.id}"
        http_method             = "${aws_api_gateway_method.webhook_method.http_method}"
        integration_http_method = "POST"
        type                    = "AWS"
        passthrough_behavior    = "WHEN_NO_MATCH"

        uri                     = "${aws_lambda_function.dc_slack_api.invoke_arn}"
        request_templates       = { "application/json" = "#set($inputRoot = $input.path('$')){}" }
}

#resource "aws_api_gateway_integration_response" "WebhookResourceMethodIntegration200" {
#        rest_api_id             = "${aws_api_gateway_rest_api.slackWebhook.id}"
#        resource_id             = "${aws_api_gateway_resource.dc_slack_api_res.id}"
#        http_method             = "${aws_api_gateway_method.webhook_method.http_method}"
#	status_code		= "${aws_api_gateway_method_response.WebhookResourceMethod200.status_code}"
#	response_parameters	= {
#		"method.response.header.Access-Control-Allow-Origin" = "'*'"
#	}
#	response_templates	= { "application/json" = "#set($inputRoot = $input.path('$')){}" }
#}

#resource "aws_api_gateway_integration_response" "WebhookResourceMethodIntegration400" {
#        rest_api_id             = "${aws_api_gateway_rest_api.slackWebhook.id}"
#        resource_id             = "${aws_api_gateway_resource.dc_slack_api_res.id}"
#        http_method             = "${aws_api_gateway_method.webhook_method.http_method}"
#        status_code             = "${aws_api_gateway_method_response.WebhookResourceMethod400.status_code}"
#        response_parameters     = {
#                "method.response.header.Access-Control-Allow-Origin" = "'*'"
#        }
#        response_templates      = { "application/json" = "#set($inputRoot = $input.path('$')){}" }
#}

#resource "aws_api_gateway_method_response" "WebhookResourceMethod200" {
#	rest_api_id             = "${aws_api_gateway_rest_api.slackWebhook.id}"
#       resource_id             = "${aws_api_gateway_resource.dc_slack_api_res.id}"
#       http_method             = "${aws_api_gateway_method.webhook_method.http_method}"
#	status_code		= "200"
#	response_models		= { "application/json" = "Empty" }
#	response_parameters	= { "method.response.header.Access-Control-Allow-Origin" = true }
#}

#resource "aws_api_gateway_method_response" "WebhookResourceMethod400" {
#        rest_api_id             = "${aws_api_gateway_rest_api.slackWebhook.id}"
#        resource_id             = "${aws_api_gateway_resource.dc_slack_api_res.id}"
#        http_method             = "${aws_api_gateway_method.webhook_method.http_method}"
#        status_code             = "400"
#        response_models         = { "application/json" = "Empty" }
#        response_parameters     = { "method.response.header.Access-Control-Allow-Origin" = true }
# }

resource "aws_lambda_permission" "allow_api_gateway" {
	function_name = "dc_slack_api"
	statement_id  = "AllowExecutionFromApiGateway"
	action        = "lambda:InvokeFunction"
	principal     = "apigateway.amazonaws.com"
	source_arn    = "arn:aws:execute-api:${var.aws_region}:${var.aws_account_id}:${aws_api_gateway_rest_api.slackWebhook.id}/*/POST${aws_api_gateway_resource.dc_slack_api_res.path}"
}

resource "aws_api_gateway_deployment" "dc_slack_api_deployment" {
	rest_api_id = "${aws_api_gateway_rest_api.slackWebhook.id}"
	stage_name  = "production"
	description = "Deploy methods: POST"
}
