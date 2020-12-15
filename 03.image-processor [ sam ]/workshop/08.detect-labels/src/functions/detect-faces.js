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
      }
    }
    const faces = await rekognition.detectFaces(params).promise()
    console.info(`Faces: ${JSON.stringify(faces)}`)
    return faces
  } catch (err) {
    console.error(`The execution of the service failed`)
    throw err
  }
}
