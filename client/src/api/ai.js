import { fetch } from 'whatwg-fetch';

import Config from '../constants/Config';

const getAccessToken = () =>
  document.cookie
    .split('; ')
    .find((row) => row.startsWith(`${Config.ACCESS_TOKEN_KEY}=`))
    ?.split('=')[1];

const parseResponse = async (response) => {
  const contentType = response.headers.get('content-type') || '';
  let body = {};

  if (contentType.includes('application/json')) {
    try {
      body = await response.json();
    } catch (error) {
      body = {
        message: 'Failed to parse JSON response from server',
      };
    }
  } else {
    const responseText = await response.text();
    body = responseText
      ? {
          message: responseText,
        }
      : {};
  }

  return {
    body,
    isError: !response.ok,
  };
};

const handleResponse = ({ body, isError }) => {
  if (isError) {
    throw body;
  }

  return body;
};

const buildAuthHeaders = (extra = {}) => {
  const accessToken = getAccessToken();

  if (!accessToken) {
    throw new Error('Access token not found');
  }

  return {
    Authorization: `Bearer ${accessToken}`,
    ...extra,
  };
};

const postJson = (path, payload) =>
  fetch(`${Config.SERVER_BASE_URL}/api${path}`, {
    method: 'POST',
    headers: buildAuthHeaders({
      'Content-Type': 'application/json',
    }),
    credentials: 'include',
    body: JSON.stringify(payload),
  })
    .then(parseResponse)
    .then(handleResponse);

const postMultipart = (path, formData) =>
  fetch(`${Config.SERVER_BASE_URL}/api${path}`, {
    method: 'POST',
    headers: buildAuthHeaders(),
    credentials: 'include',
    body: formData,
  })
    .then(parseResponse)
    .then(handleResponse);

const postBinary = async (path, payload) => {
  const response = await fetch(`${Config.SERVER_BASE_URL}/api${path}`, {
    method: 'POST',
    headers: buildAuthHeaders({
      'Content-Type': 'application/json',
    }),
    credentials: 'include',
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const { body } = await parseResponse(response);
    throw body;
  }

  return response.blob();
};

const getJson = (path) =>
  fetch(`${Config.SERVER_BASE_URL}/api${path}`, {
    method: 'GET',
    headers: buildAuthHeaders(),
    credentials: 'include',
  })
    .then(parseResponse)
    .then(handleResponse);

const chat = ({ sessionId, channel, message, context }) =>
  postJson('/ai/chat', {
    ...(sessionId && {
      sessionId,
    }),
    ...(channel && {
      channel,
    }),
    message,
    ...(context && {
      context,
    }),
  });

const ingestImage = ({ sessionId, channel, prompt, context, file }) => {
  const formData = new FormData();
  formData.append('file', file);

  if (sessionId) {
    formData.append('sessionId', sessionId);
  }

  if (channel) {
    formData.append('channel', channel);
  }

  if (prompt) {
    formData.append('prompt', prompt);
  }

  if (context) {
    formData.append('context', JSON.stringify(context));
  }

  return postMultipart('/ai/ingest/image', formData);
};

const ingestAudio = ({ sessionId, channel, prompt, context, file }) => {
  const formData = new FormData();
  formData.append('file', file);

  if (sessionId) {
    formData.append('sessionId', sessionId);
  }

  if (channel) {
    formData.append('channel', channel);
  }

  if (prompt) {
    formData.append('prompt', prompt);
  }

  if (context) {
    formData.append('context', JSON.stringify(context));
  }

  return postMultipart('/ai/ingest/audio', formData);
};

const confirmPlan = ({ planId, approvedActionIds, approveAll }) =>
  postJson('/ai/confirm', {
    planId,
    approvedActionIds,
    approveAll,
  });

const getHistory = ({ sessionId, channel }) =>
  getJson(`/ai/sessions/${sessionId}/history?channel=${channel}`);

const synthesizeSpeech = ({ text }) =>
  postBinary('/ai/tts', {
    text,
  });

const getVoiceContext = ({ projectId, boardId } = {}) => {
  const params = new URLSearchParams();
  if (projectId) params.set('projectId', projectId);
  if (boardId) params.set('boardId', boardId);
  const qs = params.toString();
  return getJson(`/ai/voice-context${qs ? `?${qs}` : ''}`);
};

const voiceExecute = ({ type, args, context }) =>
  postJson('/ai/voice-execute', { type, args, context });

export default {
  chat,
  ingestImage,
  ingestAudio,
  synthesizeSpeech,
  confirmPlan,
  getHistory,
  getVoiceContext,
  voiceExecute,
};
