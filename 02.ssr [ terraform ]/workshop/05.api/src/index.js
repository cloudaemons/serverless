const { parse } = require('url')
const next = require('next')
const serverless = require('serverless-http')

const app = next({
  dev: false
})

const requestHandler = app.getRequestHandler()

exports.handler = serverless(async (req, res) => {
  const parsedUrl = parse(req.url, true)
  await requestHandler(req, res, parsedUrl)
})
