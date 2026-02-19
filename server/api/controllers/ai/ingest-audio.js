const fs = require('fs/promises');

const aiService = require('../../services/ai');

const AUDIO_MIME_PATTERN = /^audio\//;

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
        message: error.message || 'Failed to receive audio file',
      });
    }

    if (files.length === 0) {
      return exits.noFile({
        message: 'No audio file was uploaded',
      });
    }

    const file = _.last(files);

    if (!AUDIO_MIME_PATTERN.test(file.type || '')) {
      await cleanupTempFile(file.fd);
      return exits.badRequest({
        message: 'Uploaded file must be an audio file',
      });
    }

    let transcript;
    try {
      transcript = await aiService.openai.transcribeAudioFile(file);
    } catch (error) {
      await cleanupTempFile(file.fd);
      return exits.badRequest({
        message: error.message || 'Failed to transcribe audio file',
      });
    }

    const effectiveMessage = inputs.prompt
      ? `${inputs.prompt}\n\nTranscribed voice input:\n${transcript}`
      : transcript;

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
      plan = await aiService.planner.planFromText({
        message: effectiveMessage,
        history,
        scope,
      });
    } catch (error) {
      await cleanupTempFile(file.fd);
      return exits.badRequest({
        message: error.message || 'Failed to plan actions from transcribed audio',
      });
    }

    await cleanupTempFile(file.fd);

    await aiService.storage.addHistoryTurn({
      userId: currentUser.id,
      channel,
      sessionId,
      role: 'user',
      content: transcript,
      metadata: {
        source: 'audio',
      },
      context,
    });

    const planId = plan.actions.length
      ? await aiService.storage.storePlan({
          userId: currentUser.id,
          channel,
          sessionId,
          message: transcript,
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
      transcript,
      assistantMessage: plan.assistantMessage,
      proposedActions: plan.actions,
      requiresConfirmation: plan.actions.length > 0,
      planId,
    });
  },
};
