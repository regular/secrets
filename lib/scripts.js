const {spawn} = require('child_process')
const bl = require('bl')
const {join} = require('path')

const BIN_DEPS = 'shell op cat'

module.exports = function(env) {
  return {
    getFromOnePassword,
    getFromSecretsService
  }

  async function getFromSecretsService(vault, item, fields) {
    return Promise.all(fields.map(f=>{
      const extraArgs = [vault, item, f]
      const quiet = false
      const q = quiet ? 'ignore' : 'inherit'
      const script = join(__dirname, 'get-from-secrets-service.sh')
      return new Promise( (resolve, reject) => {
        const p = spawn(env.shell || '/bin/sh', ['-euo', 'pipefail', script].concat(extraArgs), {
          env,
          stdio: [q, 'pipe', q] 
        })
        return p.stdout.pipe(bl( (err, data)=>{
          if (err) return reject(err)
          if (data.toString().trim() == '') return reject(new Error('empty response'))
          resolve(data)
        })) 
      })
    }))
  }
  async function getFromOnePassword(vault, item, fields) {
    fields = fields.map(name=>`label=${name}`).join(',')
    const extraArgs = [vault, item, fields]
    const quiet = false
    const q = quiet ? 'ignore' : 'inherit'
    const script = join(__dirname, 'get-from-1password.sh')
    return new Promise( (resolve, reject) => {
      const p = spawn(env.shell || '/bin/sh', ['-euo', 'pipefail', script].concat(extraArgs), {
        env,
        stdio: [q, 'pipe', q] 
      })
      return p.stdout.pipe(bl( (err, data)=>{
        if (err) return reject(err)
        const fields = JSON.parse(data)
        const values = fields.map( ({value})=>value)
        resolve(values)
      })) 
    })
  }
}
module.exports.deps = BIN_DEPS.split(' ')
