# node-login

A demo login system

## Installing

```
npm install keybase-login
```

## Playing around

```
$ ./node_modules/.bin/keybase-login
email or username> max
password>
{ uid: 'dbb165b7879fe7b1174df73bed0b9500',
  session: 'lg...",
  csrf_token: 'lg...",
  cookies:
   [ 'guest=lg...',
     'session=lg...'
   ]
}
```

## The library

```javascript
var login = require('keybase-login').login;
login({username : "max", passphrase : "eeeejjjejejje"}, function(err, res) {
  console.log(err);
  console.log(res);
});
