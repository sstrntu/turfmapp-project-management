const { ELEVENLABS_TTS_MODEL, ELEVENLABS_VOICE_ID } = require('./constants');

const ELEVENLABS_TTS_URL = 'https://api.elevenlabs.io/v1/text-to-speech';

const getApiKey = () => process.env.ELEVENLABS_API_KEY;

const isConfigured = () => !!getApiKey() && !!ELEVENLABS_VOICE_ID;

const extractErrorMessage = async (response) => {
  const bodyText = await response.text();

  try {
    const body = JSON.parse(bodyText);
    const detailMessage =
      _.isPlainObject(body.detail) && _.isString(body.detail.message) ? body.detail.message : null;

    if (detailMessage) {
      return detailMessage;
    }

    if (_.isString(body.message)) {
      return body.message;
    }

    return bodyText;
  } catch (error) {
    return bodyText;
  }
};

const synthesizeSpeech = async (text) => {
  if (!isConfigured()) {
    throw new Error('ELEVENLABS_API_KEY and ELEVENLABS_VOICE_ID must be configured');
  }

  const normalizedText = _.isString(text) ? text.trim() : String(text || '').trim();

  if (!normalizedText) {
    throw new Error('Text is required for speech synthesis');
  }

  const response = await fetch(
    `${ELEVENLABS_TTS_URL}/${encodeURIComponent(ELEVENLABS_VOICE_ID)}/stream?output_format=mp3_44100_128`,
    {
      method: 'POST',
      headers: {
        'xi-api-key': getApiKey(),
        'Content-Type': 'application/json',
        Accept: 'audio/mpeg',
      },
      body: JSON.stringify({
        model_id: ELEVENLABS_TTS_MODEL,
        text: normalizedText,
      }),
    },
  );

  if (!response.ok) {
    const errorMessage = await extractErrorMessage(response);
    throw new Error(`ElevenLabs speech request failed: ${errorMessage}`);
  }

  const arrayBuffer = await response.arrayBuffer();

  if (!arrayBuffer.byteLength) {
    throw new Error('ElevenLabs speech request returned empty audio');
  }

  return Buffer.from(arrayBuffer);
};

module.exports = {
  isConfigured,
  synthesizeSpeech,
};
