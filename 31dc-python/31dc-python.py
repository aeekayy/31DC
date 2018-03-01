"""
31 Day Challenge Slack Chat-bot Lambda handler.
"""

import os
import logging
import urllib

# Grab the bot's OAuth token from the environment 
BOT_TOKEN = os.environ["slackToken"]

# Define the URL for targeting the Slack API 
SLACK_URL = "https://slack.com/api/chat.postMessage"

def lambda_handler(data, context):
	"""
	Handle an incoming HTTP request from a Slack chat-bot.
	"""

	# Grab the Slack event data.
	slack_event = data['event']

	# Look for challenge. Return immediately if challenge is found
	if "challenge" in data:
		return data["challenge"]

	if "bot_id" in slack_event:
		logging.warn("Ignore bot event")

	else:
		text = slack_event["text"]
		reversed_text = text[::-1]

		# Get the ID of the channel where the message was posted.
		channel_id = slack_event["channel"]

		data = urllib.parse.urlencode(
			(
				("token", BOT_TOKEN),
				("channel", channel_id),
				("text", reversed_text)
			)
		)

		data = data.encode("ascii")

		# Construct the HTTP request that will be sent back to Slack API
		request = urllib.request.Request(
			SLACK_URL,
			data=data,
			method="POST"
		)

		# Adding request headers. This is a URL-encoded request.
		request.add_header(
			"Content-Type",
			"application/x-www-form-urlencoded"
		)

		# Send the request
		urllib.request.urlopen(request).read()

	# Response code
	return "200 OK"
