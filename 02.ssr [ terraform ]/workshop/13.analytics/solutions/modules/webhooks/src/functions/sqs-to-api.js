const axios = require('axios')

module.exports.handler = async (event, context) => {
  for (const item of event.Records) {
    await axios({
      method: 'POST',
      url: process.env.ENDPOINT,
      data: JSON.parse(item.body)
    })
  }
}
