/**
 * AiSession.js
 *
 * @description :: AI conversation sessions for persisted channel memory.
 */

module.exports = {
  tableName: 'ai_session',

  attributes: {
    publicId: {
      type: 'string',
      required: true,
      unique: true,
      columnName: 'public_id',
    },
    channel: {
      type: 'string',
      isIn: ['text', 'voice'],
      required: true,
    },
    context: {
      type: 'json',
    },

    userId: {
      model: 'User',
      required: true,
      columnName: 'user_id',
    },

    messages: {
      collection: 'AiMessage',
      via: 'aiSessionId',
    },

    plans: {
      collection: 'AiPlan',
      via: 'aiSessionId',
    },
  },
};
