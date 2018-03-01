data "aws_iam_policy_document" "dc-lambda-sns" {
	statement {
		effect = "Allow"
		
		actions = [
			"logs:CreateLogGroup",
			"logs:CreateLogStream",
			"logs:PutLogEvents",
		]

		resources = [
			"*",
		]
	}

	statement {
		effect = "Allow"

		actions = [
			"lambda:Invoke*",
			"lambda:List*",
			"lambda:Get*"
		]

		resources = [
			"*",
		]
	}
}

resource "aws_iam_policy" "iam_for_slack_policy" {
	name = "iam_for_slack_policy"
	path = "/service-role/"
	policy = "${data.aws_iam_policy_document.dc-lambda-sns.json}"
}

data "aws_iam_policy_document" "slack-lambda-assume-role-policy" {
        statement {
                actions = ["sts:AssumeRole"]

                principals {
                        type = "Service"
                        identifiers = ["lambda.amazonaws.com"]
                }
        }
}

resource "aws_iam_role" "iam_for_slack_lambda" {
	name = "iam_for_slack_lambda"
	assume_role_policy = "${data.aws_iam_policy_document.slack-lambda-assume-role-policy.json}"
	path = "/service-role/"
}

resource "aws_iam_role_policy_attachment" "iam-slack-lambda-attach" {
	role	= "${aws_iam_role.iam_for_slack_lambda.name}"
	policy_arn	= "${aws_iam_policy.iam_for_slack_policy.arn}"
}

resource "archive_file" "slack_lambda_archive" {
	source-dir	= "31dc-python"
	output_path	= "31dc-python.zip"
	type		= "zip"
}

resource "aws_lambda_function" "dc_slack_api" {
        function_name   = "dc_slack_api"
        role            = "${aws_iam_role.iam_for_slack_lambda.arn}"
        handler         = "slack.lambda_handler"
        runtime         = "python2.7"
        description     = "Receive a Slack message and do something with it."
        timeout         = "90"
	filename	= "31dc-python.zip"
	source_code_hash = "${archive_file.slack_lambda_archive.output_base64sha256}"
        environment {
                variables = {
                        SnsArn 		= "${var.snsName}"
                        slackChannel 	= "${var.slackChannel}"
			slackToken 	= "${var.slackToken}"
			psqlConn	= "${var.psqlConn}"
                }
        }
	tags = {
		Name		= "dc_slack"
		Environment 	= "Production"
		Purpose		= "31 Day Challenge ChatOps"
	}
}
