const aiService = require('../../services/ai');

const approvedActionIdsValidator = (value) => _.isArray(value) && value.every(_.isString);

module.exports = {
  inputs: {
    planId: {
      type: 'string',
      required: true,
    },
    approveAll: {
      type: 'boolean',
      defaultsTo: false,
    },
    approvedActionIds: {
      type: 'json',
      custom: approvedActionIdsValidator,
      defaultsTo: [],
    },
  },

  exits: {
    planNotFound: {
      responseType: 'notFound',
    },
    badRequest: {
      responseType: 'unprocessableEntity',
    },
  },

  async fn(inputs, exits) {
    const { currentUser } = this.req;

    const storedPlan = await aiService.storage.getPlan(inputs.planId);

    if (!storedPlan || storedPlan.userId !== currentUser.id) {
      return exits.planNotFound({
        message: 'Plan not found',
      });
    }

    const approvedActionSet = new Set(inputs.approvedActionIds || []);

    const selectedActions = inputs.approveAll
      ? storedPlan.actions
      : storedPlan.actions.filter((action) => approvedActionSet.has(action.id));

    if (selectedActions.length === 0) {
      return exits.badRequest({
        message: 'No approved actions were provided',
      });
    }

    const executionResults = await aiService.executor.executeApprovedActions({
      actions: selectedActions,
      currentUser,
      request: this.req,
      context: storedPlan.context || {},
    });

    await aiService.storage.deletePlan(inputs.planId, {
      status: AiPlan.Statuses.CONSUMED,
      executionResults,
    });

    const successCount = executionResults.filter((item) => item.success).length;
    const failureCount = executionResults.length - successCount;

    const summary =
      failureCount > 0
        ? `Executed ${successCount}/${executionResults.length} actions. ${failureCount} failed.`
        : `Executed ${successCount} actions successfully.`;

    await aiService.storage.addHistoryTurn({
      userId: currentUser.id,
      channel: storedPlan.channel,
      sessionId: storedPlan.sessionId,
      role: 'assistant',
      content: summary,
      metadata: {
        executionResults,
      },
    });

    return exits.success({
      planId: inputs.planId,
      summary,
      executedActions: executionResults,
    });
  },
};
