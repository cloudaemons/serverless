const AWS = require('aws-sdk')
const moment = require('moment')
const stepfunctions = new AWS.StepFunctions()
const format = 'YYYY-MM-DD HH:mm:ss'

module.exports.handler = async (event, context) => {
  try {
   
    const today = moment()
    const startDate = moment(today).subtract(1,'months').startOf('month').format(format)
    const endDate = moment(today).subtract(1,'months').endOf('month').format(format)

    const params = {
      stateMachineArn: process.env.STATE_MACHINE_ARN,
      input: JSON.stringify({
        startDate,
        endDate
      }),
      name: context.awsRequestId
    }

    await stepfunctions.startExecution(params).promise()
  } catch (err) {
    throw err
  }
}
