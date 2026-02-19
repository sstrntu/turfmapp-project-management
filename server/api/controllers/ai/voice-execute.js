const aiService = require('../../services/ai');
const { ACTION_TYPES } = require('../../services/ai/constants');

const VALID_TYPES = new Set(Object.values(ACTION_TYPES));

module.exports = {
  exits: {
    badRequest: {
      responseType: 'unprocessableEntity',
    },
  },

  async fn(inputs, exits) {
    const { currentUser } = this.req;
    const payload = _.isPlainObject(this.req.body) ? this.req.body : {};

    const actionType = _.isString(payload.type) ? payload.type.trim() : '';
    const args = _.isPlainObject(payload.args) ? payload.args : {};

    let context = payload.context || {};
    if (_.isString(context)) {
      try {
        context = JSON.parse(context);
      } catch (error) {
        context = {};
      }
    }
    if (!_.isPlainObject(context)) {
      context = {};
    }

    if (!actionType) {
      return exits.badRequest({ message: 'Action type is required' });
    }

    if (!VALID_TYPES.has(actionType)) {
      return exits.badRequest({ message: `Unsupported action type: ${actionType}` });
    }

    try {
      const results = await aiService.executor.executeApprovedActions({
        actions: [{ id: 'voice-action', type: actionType, args }],
        currentUser,
        request: this.req,
        context,
      });

      const result = results[0];

      return exits.success({
        success: result.success,
        message: result.message || result.error || 'Action completed',
        item: result.item || null,
      });
    } catch (error) {
      sails.log.error('AI voice-execute failed', error);
      return exits.badRequest({
        message: error.message || 'Failed to execute action',
      });
    }
  },
};
