/**
 * AiPlan.js
 *
 * @description :: Stored proposed action bundles awaiting confirmation/execution.
 */

const Statuses = {
  PENDING: 'pending',
  CONSUMED: 'consumed',
};

module.exports = {
  tableName: 'ai_plan',

  Statuses,

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
    message: {
      type: 'string',
      allowNull: true,
    },
    actions: {
      type: 'json',
      required: true,
    },
    context: {
      type: 'json',
    },
    status: {
      type: 'string',
      isIn: Object.values(Statuses),
      defaultsTo: Statuses.PENDING,
    },
    executionResults: {
      type: 'json',
      columnName: 'execution_results',
    },

    aiSessionId: {
      model: 'AiSession',
      required: true,
      columnName: 'ai_session_id',
    },
    userId: {
      model: 'User',
      required: true,
      columnName: 'user_id',
    },
  },
};
