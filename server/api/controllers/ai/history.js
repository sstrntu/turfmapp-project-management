const aiService = require('../../services/ai');

module.exports = {
  inputs: {
    sessionId: {
      type: 'string',
      required: true,
    },
    channel: {
      type: 'string',
      isIn: ['text', 'voice'],
      defaultsTo: 'text',
    },
  },

  async fn(inputs) {
    const { currentUser } = this.req;

    const history = await aiService.storage.getHistory({
      userId: currentUser.id,
      channel: inputs.channel,
      sessionId: inputs.sessionId,
    });

    return {
      sessionId: inputs.sessionId,
      channel: inputs.channel,
      items: history,
    };
  },
};
