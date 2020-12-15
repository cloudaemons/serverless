const AWS = require('aws-sdk')
const sharp = require('sharp')

const { ImageIdentifyError } = require('./../helpers/errors')

const s3 = new AWS.S3()

function getFile (bucketName, fileName) {
  return s3.getObject({
    Bucket: bucketName,
    Key: fileName
  }).promise()
}

module.exports.handler = async (event) => {
  try {
    console.info(`Received event: ${JSON.stringify(event)}`)

    const { bucketName, fileName } = event
    const fileObject = await getFile(bucketName, fileName)
    const metadata = await sharp(fileObject.Body).metadata()
    console.info(`Metadata: ${JSON.stringify(metadata)}`)

    if (metadata.width < 500) throw new ImageIdentifyError('Too small picture')

    return metadata
  } catch (err) {
    console.error(`The execution of the service failed`)
    throw err
  }
}
