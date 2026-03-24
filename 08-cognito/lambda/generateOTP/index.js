exports.handler = async (event) => {
  const otp = event.clientMetadata?.defaultOtp ||
    Math.floor(100000 + Math.random() * 900000).toString();

  console.log('=== OTP CODE ===', otp, 'for phone:', event.request.userAttributes.phone_number);

  event.response.publicChallengeParameters = {
    email: event.request.userAttributes.email || ''
  };

  event.response.privateChallengeParameters = { answer: otp };
  event.response.challengeMetadata = 'OTP_CHALLENGE';

  return event;
};
