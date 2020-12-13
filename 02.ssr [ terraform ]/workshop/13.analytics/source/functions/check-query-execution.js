const AWS = require('aws-sdk')
const athena = new AWS.Athena({ athena: '2017-05-18' })

module.exports.handler = async (event, context) => {
  const rsp = await athena.getQueryExecution({
    QueryExecutionId: event.QueryExecutionId
  }).promise()

  return { 
    state: rsp.QueryExecution.Status.State,
    csv: rsp.QueryExecution.ResultConfiguration.OutputLocation,
    QueryExecutionId: event.QueryExecutionId
  }
}
