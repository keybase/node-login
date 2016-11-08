read = require 'read'
{login} = require '../'
{make_esc} = require 'iced-error'

parse_email_or_username = (email_or_username) ->
  if email_or_username.indexOf('@') > 0 then { email : email_or_username }
  else { username : email_or_username }

exports.cmd = (cb) ->
  esc = make_esc cb, "main"
  await read { prompt : "email or username> " }, esc defer email_or_username
  {username, email} = parse_email_or_username email_or_username
  await read { prompt : "passphrase> ", silent : true }, esc defer passphrase
  await login { username, email, passphrase }, defer err, res
  cb err, res
