exports.handler = async (event) => {
  const expected = event.request.privateChallengeParameters.answer;
  const provided = event.request.challengeAnswer;

  console.log('Expected:', expected, 'Provided:', provided);
  event.response.answerCorrect = (provided === expected);
  return event;
};