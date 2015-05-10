req = {}

req.setHeader = (key, value) ->
  this[key] = value

module.exports = req