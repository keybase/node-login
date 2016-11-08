kbpgp = require 'kbpgp'
triplesec = require 'triplesec'
request = require 'request'
{make_esc} = require 'iced-error'
{Auth} = require 'keybase-proofs'

json_endpoint = (w) -> "https://keybase.io/_/api/1.0/#{w}.json"

do_post = ({endpoint, form}, cb) ->
  esc = make_esc cb, "do_post"
  await request.post {
    uri : json_endpoint(endpoint),
    form : form
    json : true
  }, esc defer response, body
  err = null
  if body.status.code isnt 0
    err = new Error "from #{endpoint}: non-0 status #{JSON.stringify body.status}"
  cb err, body, response

get_salt = ({username, email}, cb) ->
  esc = make_esc cb, "get_salt"
  await do_post {
    endpoint : "getsalt"
    form :
      email_or_username : (email or username)
      pdpka_login : true
    json : true
  }, esc defer body
  ret =
    salt : new Buffer body.salt, 'hex'
    session : body.login_session
  cb null, ret

strech_passphrase = ({salt, passphrase}, cb) ->
  esc = make_esc cb, "make_keys"
  encryptor = new triplesec.Encryptor {key : (new Buffer passphrase, "utf8") }
  await encryptor.resalt { salt, extra_keymaterial : 64 }, esc defer {extra}
  cb null, { key4 : extra[0...32], key5 : extra[32...64] }

make_sig = ({key, email, username, session}, cb) ->
  esc = make_esc cb, "make_sig"
  await kbpgp.rand.SRF().random_bytes 16, defer nonce
  await kbpgp.kb.KeyManager.generate { seed : key }, esc defer signer
  auth = new Auth {
    sig_eng : signer.make_sig_eng()
    host : "keybase.io"
    user :
      local :
        email : email
        username : username
    session : session
    nonce : nonce
  }
  await auth.generate esc defer sig
  cb null, sig.armored

post_login = ({username, email, pdpka4, pdpka5}, cb) ->
  esc = make_esc cb, "post_login"
  await do_post {
    endpoint : "login"
    form :
      pdpka4 : pdpka4
      pdpka5 : pdpka5
      email_or_username : (email or username)
  }, esc defer body, response
  res =
    uid : body.uid
    session : body.session
    csrf_token : body.csrf_token
    cookies : response.headers["set-cookie"]
  cb null, res

exports.login = login = ({username, email, passphrase}, cb) ->
  esc = make_esc cb, "login"
  await get_salt { username, email }, esc defer { salt, session }
  await strech_passphrase { salt, passphrase }, esc defer { key4, key5 }
  await make_sig { key : key4, email, username, session }, esc defer pdpka4
  await make_sig { key : key5, email, username, session }, esc defer pdpka5
  await post_login { username, email, pdpka4, pdpka5 }, esc defer res
  cb null, res

