const aiService = require('../../services/ai');

module.exports = {
  exits: {
    badRequest: {
      responseType: 'unprocessableEntity',
    },
  },

  async fn(inputs, exits) {
    const payload = _.isPlainObject(this.req.body) ? this.req.body : inputs || {};
    const text = _.isString(payload.text) ? payload.text.trim() : String(payload.text || '').trim();

    if (!text) {
      return exits.badRequest({
        message: 'Text is required',
      });
    }

    if (!aiService.elevenlabs.isConfigured()) {
      return exits.badRequest({
        message: 'ElevenLabs TTS is unavailable because server credentials are not configured.',
      });
    }

    let audioBuffer;
    try {
      audioBuffer = await aiService.elevenlabs.synthesizeSpeech(text);
    } catch (error) {
      sails.log.error('AI TTS synthesis failed', error);
      return exits.badRequest({
        message: error.message || 'Failed to synthesize speech',
      });
    }

    this.res.set('Content-Type', 'audio/mpeg');
    this.res.set('Cache-Control', 'no-store');

    return this.res.send(audioBuffer);
  },
};
