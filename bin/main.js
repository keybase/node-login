#!/usr/bin/env node

var cmd = require('../').cmd;
cmd(function(err, res) {
  rc = 0;
  if (err) {
    rc = -2;
    console.error(err);
  } else {
    console.log(res);
  }
  process.exit(rc);
});
