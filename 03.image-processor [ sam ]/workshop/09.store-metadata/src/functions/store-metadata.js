const AWS = require('aws-sdk')
const documentClient = new AWS.DynamoDB.DocumentClient()

module.exports.handler = async (event) => {
  try {
    console.info(`Received event: ${JSON.stringify(event)}`)
    const id = event.requestId
    const metadata = event.extractedMetadata
    const labels = event.parallelResults[0].Labels
    const faces = event.parallelResults[1].FaceDetails
    
    const item = Object.assign({}, {id}, metadata, {labels}, {faces} )
    const params = {
      TableName: process.env.TABLE_NAME,
      Item: item
    }
    
    await documentClient.put(params).promise()
   
  } catch (err) {
    console.error(`The execution of the service failed`)
    throw err
  }
}