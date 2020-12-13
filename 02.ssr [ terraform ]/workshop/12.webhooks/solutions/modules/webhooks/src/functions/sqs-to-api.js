const axios = require('axios')

module.exports.handler = async (event, context) => {
  for (const item of event.Records) {
    // WRITE CUSTTOM LOGIC WHICH SAVE DATA TO DB
  }
}
