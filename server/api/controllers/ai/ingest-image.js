const fs = require('fs/promises');

const aiService = require('../../services/ai');

const IMAGE_MIME_PATTERN = /^image\//;

const cleanupTempFile = async (filePath) => {
  if (!filePath) {
    return;
  }

  try {
    await fs.unlink(filePath);
  } catch (error) {} // eslint-disable-line no-empty
};

module.exports = {
  inputs: {
    sessionId: {
      type: 'string',
    },
    channel: {
      type: 'string',
      isIn: ['text', 'voice'],
      defaultsTo: 'text',
    },
    prompt: {
      type: 'string',
    },
    context: {
      type: 'ref',
    },
  },

  exits: {
    noFile: {
      responseType: 'unprocessableEntity',
    },
    badRequest: {
      responseType: 'unprocessableEntity',
    },
  },

  async fn(inputs, exits) {
    const { currentUser } = this.req;
    let context = inputs.context || {};
    if (_.isString(context)) {
      try {
        context = JSON.parse(context);
      } catch (error) {
        context = {};
      }
    }
    const channel = inputs.channel || 'text';
    const sessionId = inputs.sessionId || aiService.storage.createSessionId();

    let files;
    try {
      files = await sails.helpers.utils.receiveFile('file', this.req);
    } catch (error) {
      return exits.badRequest({
        message: error.message || 'Failed to receive image file',
      });
    }

    if (files.length === 0) {
      return exits.noFile({
        message: 'No image file was uploaded',
      });
    }

    const file = _.last(files);

    if (!IMAGE_MIME_PATTERN.test(file.type || '')) {
      await cleanupTempFile(file.fd);
      return exits.badRequest({
        message: 'Uploaded file must be an image',
      });
    }

    const history = await aiService.storage.getHistory({
      userId: currentUser.id,
      channel,
      sessionId,
    });

    let scope;
    try {
      scope = await aiService.scope.getAuthorizedScope(currentUser.id, context);
    } catch (error) {
      await cleanupTempFile(file.fd);
      return exits.badRequest({
        message: `Failed to resolve authorized scope: ${error.message || String(error)}`,
      });
    }

    let plan;
    try {
      const fileContent = await fs.readFile(file.fd);
      const imageDataUri = `data:${file.type};base64,${fileContent.toString('base64')}`;

      plan = await aiService.planner.planFromImage({
        prompt: inputs.prompt,
        history,
        scope,
        imageDataUri,
      });
    } catch (error) {
      await cleanupTempFile(file.fd);
      return exits.badRequest({
        message: error.message || 'Failed to process image input',
      });
    }

    await cleanupTempFile(file.fd);

    const promptText = inputs.prompt || 'Analyze uploaded image';
    await aiService.storage.addHistoryTurn({
      userId: currentUser.id,
      channel,
      sessionId,
      role: 'user',
      content: `${promptText} [image]`,
      context,
    });

    const planId = plan.actions.length
      ? await aiService.storage.storePlan({
          userId: currentUser.id,
          channel,
          sessionId,
          message: promptText,
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
