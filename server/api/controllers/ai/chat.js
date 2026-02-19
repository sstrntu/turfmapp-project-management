const aiService = require('../../services/ai');

module.exports = {
  exits: {
    badRequest: {
      responseType: 'unprocessableEntity',
    },
  },

  async fn(inputs, exits) {
    const { currentUser } = this.req;
    const payload = _.isPlainObject(this.req.body) ? this.req.body : inputs || {};

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

    const channel = payload.channel === 'voice' ? 'voice' : 'text';
    const message = _.isString(payload.message)
      ? payload.message.trim()
      : String(payload.message || '');
    const sessionId =
      _.isString(payload.sessionId) && payload.sessionId.trim()
        ? payload.sessionId.trim()
        : aiService.storage.createSessionId();

    if (!message) {
      return exits.badRequest({
        message: 'Message is required',
      });
    }

    let scope;
    try {
      scope = await aiService.scope.getAuthorizedScope(currentUser.id, context);
    } catch (error) {
      sails.log.error('AI chat scope resolution failed', error);
      return exits.badRequest(
        `Failed to resolve authorized scope: ${error.message || String(error)}`,
      );
    }

    const history = await aiService.storage.getHistory({
      userId: currentUser.id,
      channel,
      sessionId,
    });

    await aiService.storage.addHistoryTurn({
      userId: currentUser.id,
      channel,
      sessionId,
      role: 'user',
      content: message,
      context,
    });

    let plan;
    try {
      plan = await aiService.planner.planFromText({
        message,
        history,
        scope,
      });
    } catch (error) {
      sails.log.error('AI chat planning failed', error);
      return exits.badRequest(error.message || 'Failed to plan AI actions');
    }

    const planId = plan.actions.length
      ? await aiService.storage.storePlan({
          userId: currentUser.id,
          channel,
          sessionId,
          message,
          actions: plan.actions,
          context,
        })
      : null;

    await aiService.storage.addHistoryTurn({
      userId: currentUser.id,
      channel,
      sessionId,
      role: 'assistant',
      content: plan.assistantMessage,
      metadata: {
        planId,
        actionCount: plan.actions.length,
      },
    });

    return exits.success({
      sessionId,
      channel,
      assistantMessage: plan.assistantMessage,
      proposedActions: plan.actions,
      requiresConfirmation: plan.actions.length > 0,
      planId,
    });
  },
};
