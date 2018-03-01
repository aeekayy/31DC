variable "aws_account_id" {
	description	= "The account ID for the AWS account."
}

variable "aws_access_key_id" {
	description	= "The AWS access key to use."
}

variable "aws_secret_access_key" {
	description	= "The AWS secret access key to use."
}

variable "aws_region" {
	description	= "The AWS region to use."
	default		= "us-west-2"
}

variable "snsName" {
	type		= "string"
	description	= "The SNS Name."
	default		= "dc_slack_sns"	
}

variable "slackChannel" {
	type		= "string"
	description	= "The Slack channel for the bot."
	default		= "#dcbot"
}

variable "slackToken" {
	type		= "string"
	description	= "The token for Slack."
}

variable "psqlConn" {
	type		= "string"
	description	= "The PostgreSQL connection string."
}
