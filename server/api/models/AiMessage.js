/**
 * AiMessage.js
 *
 * @description :: Persisted user/assistant conversation turns.
 */

module.exports = {
  tableName: 'ai_message',

  attributes: {
    role: {
      type: 'string',
      isIn: ['user', 'assistant', 'system'],
      required: true,
    },
    content: {
      type: 'string',
      required: true,
    },
    metadata: {
      type: 'json',
      defaultsTo: {},
    },

    aiSessionId: {
      model: 'AiSession',
      required: true,
      columnName: 'ai_session_id',
    },
  },
};
