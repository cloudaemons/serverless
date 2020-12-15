function ImageIdentifyError (message) {
    this.name = "ImageIdentifyError"
    this.message = message
}

ImageIdentifyError.prototype = new Error()

module.exports = {
  ImageIdentifyError
}
