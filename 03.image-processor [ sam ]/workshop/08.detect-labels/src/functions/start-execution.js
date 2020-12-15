const AWS = require('aws-sdk')
const utils = require('./../helpers/utils')

const stepfunctions = new AWS.StepFunctions()

module.exports.handler = async (event, context) => {
  try {
    console.info(`Received event: ${JSON.stringify(event)}`)
    const requestId = context.awsRequestId

    const fileName = utils.getFileName(event)
    const bucketName = utils.getBucketName(event)

    const params = {
      stateMachineArn: process.env.STATE_MACHINE_ARN,
      input: JSON.stringify({
        fileName,
        bucketName,
        requestId
      }),
      name: requestId
    }

    await stepfunctions.startExecution(params).promise()
  } catch (err) {
    console.error(`The execution of the service failed`)
    throw err
  }
}
