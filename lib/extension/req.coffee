req = {}

req.setHeader = (key, value) ->
  this.headers[key] = value

module.exports = req