const AWS = require('aws-sdk')
const athena = new AWS.Athena({ athena: '2017-05-18' })


function getQuery (database, events, startDate, endDate) {
  return `SELECT * FROM "${database}"."${events}"`
}

module.exports.handler = async (event, context) => {
  const { startDate, endDate } = event
 
  const query = getQuery(process.env.ATHENA_DATABASE, process.env.EVENTS_TABLE, startDate, endDate)
  const params = {
    QueryString: query,
    ResultConfiguration: {
      OutputLocation: `s3://${process.env.S3_QUERY_OUTPUT}/`
    }
  }

  return await athena.startQueryExecution(params).promise()
}
