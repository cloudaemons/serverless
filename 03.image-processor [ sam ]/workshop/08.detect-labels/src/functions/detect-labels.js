const AWS = require('aws-sdk')
const rekognition = new AWS.Rekognition()

module.exports.handler = async (event) => {
  try {
    console.info(`Received event: ${JSON.stringify(event)}`)
    const { bucketName, fileName } = event
    const params = {
      Image: {
        S3Object: {
          Bucket: bucketName,
          Name: fileName
        }
      },
      MaxLabels: 10,
      MinConfidence: 60
    }
    const labels = await rekognition.detectLabels(params).promise()
    console.info(`Labels: ${JSON.stringify(labels)}`)
    return labels
  } catch (err) {
    console.error(`The execution of the service failed`)
    throw err
  }
}
