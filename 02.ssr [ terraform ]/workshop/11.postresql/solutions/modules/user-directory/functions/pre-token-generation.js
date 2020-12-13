exports.handler = async (event) => {
  event.response = {
    claimsOverrideDetails: {
      claimsToSuppress: ['email']
    }
  }

  return event
}
