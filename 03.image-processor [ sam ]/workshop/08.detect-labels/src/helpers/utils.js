function getFileName (event) {
  let key = event['Records'][0]['s3']['object']['key']

  if (!key) {
    throw new Error('Unable to get name from the event')
  }

  return decodeURIComponent(key.replace(/\+/g, ' '))
}

function getBucketName (event) {
  let bucketName = event['Records'][0]['s3']['bucket']['name']

  if (!bucketName) {
    throw new Error('Unable to get bucket from the event')
  }

  return bucketName
}

module.exports = {
  getBucketName,
  getFileName
}
