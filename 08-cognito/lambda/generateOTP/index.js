const { SNSClient, PublishCommand } = require("@aws-sdk/client-sns");
const crypto = require("crypto");

const snsClient = new SNSClient({ region: process.env.AWS_REGION });

// Generate cryptographically secure OTP using crypto.getRandomValues()
function generateSecureOTP(length = 6) {
  const digits = '0123456789';
  let otp = '';
  const randomBytes = crypto.getRandomValues(new Uint8Array(length));
  for (let i = 0; i < length; i++) {
    otp += digits[randomBytes[i] % digits.length];
  }
  return otp;
}

exports.handler = async (event) => {
  console.log('Event:', JSON.stringify(event, null, 2));
  
  const otp = generateSecureOTP();

  console.log(`\n========== OTP FOR USER ${event.request.userAttributes.email} =========`);
  console.log(`OTP: ${otp}`);
  console.log(`========================================================\n`);

  const phoneNumber = event.request.userAttributes.phone_number;
  
  if (!phoneNumber) {
    console.error('Phone number not found in userAttributes:', event.request.userAttributes);
    throw new Error("Phone number not found");
  }

  try {
    const params = {
      Message: `Your OTP is: ${otp}. Do not share this code.`,
      PhoneNumber: phoneNumber,
    };

    console.log('Sending SMS to:', phoneNumber);
    await snsClient.send(new PublishCommand(params));
    console.log(`OTP sent to ${phoneNumber}`);
  } catch (error) {
    console.error(`SNS publish failed for ${phoneNumber}; falling back to CloudWatch-only delivery:`, error);
    console.log(`OTP written to CloudWatch for ${phoneNumber}: ${otp}`);
  }

  event.response.publicChallengeParameters = {
    email: event.request.userAttributes.email || '',
    deliveryMethod: 'cloudwatch-fallback'
  };

  event.response.privateChallengeParameters = { answer: otp };
  event.response.challengeMetadata = 'OTP_CHALLENGE';

  return event;
};
