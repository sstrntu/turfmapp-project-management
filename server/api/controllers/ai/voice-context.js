const aiService = require('../../services/ai');

module.exports = {
  exits: {
    badRequest: {
      responseType: 'unprocessableEntity',
    },
  },

  async fn(inputs, exits) {
    const { currentUser } = this.req;
    const query = this.req.query || {};

    const context = {};
    if (query.projectId) {
      context.projectId = query.projectId;
    }
    if (query.boardId) {
      context.boardId = query.boardId;
    }

    let scope;
    try {
      scope = await aiService.scope.getAuthorizedScope(currentUser.id, context);
    } catch (error) {
      sails.log.error('AI voice-context scope resolution failed', error);
      return exits.badRequest({
        message: `Failed to resolve scope: ${error.message || String(error)}`,
      });
    }

    const workspace = aiService.scope.buildPromptSummary(scope);

    const systemPrompt = `You are a voice assistant for the TurfMapp project management app.
You have access to the user's workspace through client tools.
When the user asks you to create, update, move, or delete cards or lists, use the appropriate client tool.
When the user asks about their board, cards, or lists, use the get_board_context tool to retrieve current data.
Be concise in voice responses. Confirm actions after executing them.
Do not ask for confirmation on non-destructive actions (create, update, move).
For destructive actions (delete, archive), briefly confirm before executing.

Current workspace context:
${JSON.stringify(workspace)}`;

    return exits.success({
      systemPrompt,
      workspace,
      context,
    });
  },
};
