req =
  setHeader: (key, value) -> @headers[key] = value

module.exports = req