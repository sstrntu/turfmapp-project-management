const fs = require('fs/promises');

const { OPENAI_CHAT_MODEL, OPENAI_TRANSCRIBE_MODEL } = require('./constants');

const OPENAI_CHAT_URL = 'https://api.openai.com/v1/chat/completions';
const OPENAI_TRANSCRIBE_URL = 'https://api.openai.com/v1/audio/transcriptions';

const getApiKey = () => process.env.OPENAI_API_KEY;

const isConfigured = () => !!getApiKey();

const parseJsonObject = (content) => {
  if (!content || typeof content !== 'string') {
    return null;
  }

  try {
    return JSON.parse(content);
  } catch (error) {
    const fencedMatch = content.match(/```json\s*([\s\S]*?)\s*```/i);

    if (!fencedMatch) {
      return null;
    }

    try {
      return JSON.parse(fencedMatch[1]);
    } catch (innerError) {
      return null;
    }
  }
};

const extractErrorMessage = async (response) => {
  const bodyText = await response.text();

  try {
    const body = JSON.parse(bodyText);
    return (body.error && body.error.message) || bodyText;
  } catch (error) {
    return bodyText;
  }
};

const requestJsonPlan = async ({ messages }) => {
  if (!isConfigured()) {
    throw new Error('OPENAI_API_KEY is not configured');
  }

  const response = await fetch(OPENAI_CHAT_URL, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${getApiKey()}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: OPENAI_CHAT_MODEL,
      messages,
      response_format: {
        type: 'json_object',
      },
    }),
  });

  if (!response.ok) {
    const errorMessage = await extractErrorMessage(response);
    throw new Error(`OpenAI chat request failed: ${errorMessage}`);
  }

  const body = await response.json();
  const content =
    body.choices && body.choices[0] && body.choices[0].message
      ? body.choices[0].message.content || ''
      : '';
  const parsed = parseJsonObject(content);

  if (!parsed) {
    throw new Error('OpenAI response did not contain valid JSON');
  }

  return parsed;
};

const transcribeAudioFile = async (file) => {
  if (!isConfigured()) {
    throw new Error('OPENAI_API_KEY is not configured');
  }

  const content = await fs.readFile(file.fd);
  const blob = new Blob([content], {
    type: file.type || 'application/octet-stream',
  });

  const formData = new FormData();
  formData.append('model', OPENAI_TRANSCRIBE_MODEL);
  formData.append('file', blob, file.filename || 'recording.wav');

  const response = await fetch(OPENAI_TRANSCRIBE_URL, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${getApiKey()}`,
    },
    body: formData,
  });

  if (!response.ok) {
    const errorMessage = await extractErrorMessage(response);
    throw new Error(`OpenAI transcription request failed: ${errorMessage}`);
  }

  const body = await response.json();
  const text = body.text ? String(body.text).trim() : '';

  if (!text) {
    throw new Error('OpenAI transcription returned empty text');
  }

  return text;
};

module.exports = {
  isConfigured,
  requestJsonPlan,
  transcribeAudioFile,
};
