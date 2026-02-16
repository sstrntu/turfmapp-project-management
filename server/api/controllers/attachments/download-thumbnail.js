const Errors = {
  ATTACHMENT_NOT_FOUND: {
    attachmentNotFound: 'Attachment not found',
  },
};

module.exports = {
  inputs: {
    id: {
      type: 'string',
      regex: /^[0-9]+$/,
      required: true,
    },
  },

  exits: {
    attachmentNotFound: {
      responseType: 'notFound',
    },
  },

  async fn(inputs, exits) {
    sails.log.info(`[THUMB] Downloading thumbnail for attachment: ${inputs.id}`);
    const { currentUser } = this.req;

    sails.log.info(`[THUMB] Current user: ${currentUser ? currentUser.email : 'none'}`);

    const { attachment, card, project } = await sails.helpers.attachments
      .getProjectPath(inputs.id)
      .intercept('pathNotFound', () => Errors.ATTACHMENT_NOT_FOUND);

    sails.log.info(`[THUMB] Found attachment: ${attachment.id}, dirname: ${attachment.dirname}, filename: ${attachment.filename}`);

    const isBoardMember = await sails.helpers.users.isBoardMember(currentUser.id, card.boardId);

    if (!isBoardMember) {
      const isProjectManager = await sails.helpers.users.isProjectManager(
        currentUser.id,
        project.id,
      );

      if (!isProjectManager) {
        throw Errors.ATTACHMENT_NOT_FOUND; // Forbidden
      }
    }

    if (!attachment.image) {
      throw Errors.ATTACHMENT_NOT_FOUND;
    }

    const fileManager = sails.hooks['file-manager'].getInstance();

    let readStream;
    const filePath = `${sails.config.custom.attachmentsPathSegment}/${attachment.dirname}/thumbnails/cover-256.${attachment.image.thumbnailsExtension}`;
    try {
      sails.log.info(`[DEBUG] Reading attachment thumbnail from: ${filePath}`);
      readStream = await fileManager.read(filePath);
      sails.log.info(`[DEBUG] Successfully read thumbnail: ${filePath}`);
    } catch (error) {
      sails.log.error(`[DEBUG] Failed to read thumbnail from ${filePath}: ${error.message}`);
      throw Errors.ATTACHMENT_NOT_FOUND;
    }

    this.res.type('image/jpeg');
    this.res.set('Cache-Control', 'private, max-age=900'); // TODO: move to config

    return exits.success(readStream);
  },
};
