const fs = require('fs')
const {join} = require('path')
const crypto = require('crypto')
const bl = require('bl')
const debug = require('debug')('config-server')

const Scripts = require('./lib/scripts')

const config = require('rc')('secrets', {
  delimiter: '\0'
})

debug('config: %O', config)

//if (!config.patPath) bail(new Error('--patPath missing'))

for(const d of Scripts.deps) {
  if (!config.bin || !config.bin[d]) bail(new Error(`--bin.${d} missing`))
}

/*
const OP_SESSION = Object.keys(process.env).find(name=>name.startsWith('OP_SESSION_'))
if (!OP_SESSION) bail(new Error('no environment variable starting with OP_SESSION found.'))

const {getFromOnePassword} = require('./lib/scripts')(Object.assign({
  [OP_SESSION]: process.env[OP_SESSION],
  XDG_CONFIG_DIRS: process.env.XDG_CONFIG_DIRS,
  HOME: process.env.HOME
}, config.bin))
*/

const {getFromSecretsService} = require('./lib/scripts')(Object.assign({
  PATH: process.env.PATH,
  SSH_AUTH_SOCK: process.env.SSH_AUTH_SOCK  // for sudo via agent
}, config.bin))

async function main(conf) {
  if (conf._.length < 4) {
    bail(new Error('Usage: VERB VAULT ITEM FUELD1 .. FIELDn [--delimiter STRING'))
  }
  const [verb, vault, item, ...fields] = conf._
  if (verb == 'get') {
    try {
      const result = await getFromSecretsService(vault, item, fields)
      process.stdout.write(result.join(conf.delimiter))
    } catch (err) {
      console.error(err.message)
      process.exit(1)
    }
  }
}

main(config)

function bail(err) {
  if (!err) return
  console.error(err.message)
  process.exit(1)
}
