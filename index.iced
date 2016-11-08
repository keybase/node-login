
kbpgp = require 'kbpgp'
triplesec = require 'triplesec'
request = require 'request'
{make_esc} = require 'iced-error'

json_endpoint = (w) -> "https://keybase.io/_/api/1.0/#{w}.json"

get_salt = ({username, email}, cb) ->
  esc = make_esc cb, "get_salt"
  await request.post {
    uri : json_endpoint("getsalt")
    form :
      email_or_username : (username or email)
    json : true
  }, esc defer _, body
  ret = {}
  err = null
  if body.status.code isnt 0
    err = new Error "non-0 status"
  else
    ret.salt = new Buffer body.salt, 'hex'
    ret.session = body.login_session
  cb err, ret

strech_passphrase = ({salt, passphrase}, cb) ->
  esc = make_esc cb, "make_keys"
  encryptor = new triplesec.Encryptor {key : (new Buffer passphrase, "utf8") }
  await encryptor.resalt { salt, extra_keymaterial : 64 }, esc defer {extra}
  cb null, { key4 : extra[0...32], key5 : extra[32...64] }

make_sig = ({key, email, username, session}, cb) ->
  await kbpgp.kb.KeyManager.generate { seed : }

exports.login = login = ({username, email, passphrase}, cb) ->
  esc = make_esc cb, "login"
  await get_salt { username, email }, esc defer { salt, session }
  await strech_passphrase { salt, passphrase }, esc defer { key4, key5 }
  await make_sig { key : key4, email, username, session }, esc defer { pdpka4 }
  await make_sig { key : key5, email, username, session }, esc defer { pdpka5 }
  await post_login { username, email, pdpka4, pdpka5 }, esc defer { uid, cookie }
  cb null, { uid, cookie }

await login { username : "max", passphrase : "foobere" }, defer err