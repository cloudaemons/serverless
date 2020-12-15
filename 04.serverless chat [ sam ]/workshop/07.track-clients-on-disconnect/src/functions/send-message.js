const AWS = require('aws-sdk')
const db = new AWS.DynamoDB.DocumentClient({ apiVersion: '2012-08-10', region: process.env.AWS_REGION })

exports.handler = async event => {
  let connectionData
  
  try {
    connectionData = await db.scan({ TableName: process.env.TABLE_NAME, ProjectionExpression: 'connectionId' }).promise()
  } catch (e) {
    return { statusCode: 500, body: e.stack }
  }
  
  const apigwManagementApi = new AWS.ApiGatewayManagementApi({
    apiVersion: '2018-11-29',
    endpoint: event.requestContext.domainName + '/' + event.requestContext.stage
  })
  
  const postData = JSON.parse(event.body).data
  
  const postCalls = connectionData.Items.map(async ({ connectionId }) => {
    try {
      await apigwManagementApi.postToConnection({ ConnectionId: connectionId, Data: postData }).promise()
    } catch (e) {
      if (e.statusCode === 410) {
        console.log(`Found stale connection, deleting ${connectionId}`)
        await db.delete({ TableName: process.env.TABLE_NAME, Key: { connectionId } }).promise()
      } else {
        throw e
      }
    }
  })
  
  try {
    await Promise.all(postCalls)
  } catch (e) {
    return { statusCode: 500, body: e.stack }
  }

  return { statusCode: 200, body: 'Data sent.' }
}
