const DEFAULT_MAX_ACTIONS_PER_REQUEST = 50;

const ACTION_TYPES = Object.freeze({
  CREATE_CARD: 'create_card',
  UPDATE_CARD: 'update_card',
  MOVE_CARD: 'move_card',
  ARCHIVE_CARD: 'archive_card',
  DELETE_CARD: 'delete_card',
  CREATE_LIST: 'create_list',
  UPDATE_LIST: 'update_list',
  DELETE_LIST: 'delete_list',
});

const DESTRUCTIVE_ACTION_TYPES = new Set([
  ACTION_TYPES.ARCHIVE_CARD,
  ACTION_TYPES.DELETE_CARD,
  ACTION_TYPES.DELETE_LIST,
]);

module.exports = {
  ACTION_TYPES,
  DESTRUCTIVE_ACTION_TYPES,
  MAX_ACTIONS_PER_REQUEST:
    Number.parseInt(process.env.AI_MAX_ACTIONS_PER_REQUEST, 10) || DEFAULT_MAX_ACTIONS_PER_REQUEST,
  OPENAI_CHAT_MODEL: process.env.OPENAI_CHAT_MODEL || 'gpt-4o-mini',
  OPENAI_TRANSCRIBE_MODEL: process.env.OPENAI_TRANSCRIBE_MODEL || 'gpt-4o-mini-transcribe',
  ELEVENLABS_TTS_MODEL: process.env.ELEVENLABS_TTS_MODEL || 'eleven_multilingual_v2',
  ELEVENLABS_VOICE_ID: process.env.ELEVENLABS_VOICE_ID || '',
};
