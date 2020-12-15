exports.handler = async (event, context) => {
    return {
        statusCode: 200,
        headers: {},
        body: JSON.stringify({"hello": "world"})
    }
}
