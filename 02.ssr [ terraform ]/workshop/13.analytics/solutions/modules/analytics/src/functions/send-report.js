const AWS = require('aws-sdk')
const sns = new AWS.SNS({apiVersion: '2010-03-31'})
const s3 = new AWS.S3()

module.exports.handler = async (event, context) => {
  const file = event.csv

  const nameArr =file.split('/')
  const bucket = nameArr[2]
  const key = nameArr[3]
  const signedUrlExpireSeconds = 60 * 24 * 30 

  const url = await s3.getSignedUrl('getObject', {
      Bucket: bucket,
      Key: key,
      Expires: signedUrlExpireSeconds
  })

  const params = {
    Message: `Video analytics: ${url} `,
    TopicArn: process.env.SNS_TOPIC
  }

  const rsp = await sns.publish(params).promise()  
  return true
}
