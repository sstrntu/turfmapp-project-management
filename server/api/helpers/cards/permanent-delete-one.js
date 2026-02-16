/* eslint-disable no-restricted-syntax, no-await-in-loop */

module.exports = {
  inputs: {
    archiveId: {
      type: 'string',
      required: true,
    },
    actorUser: {
      type: 'ref',
      required: true,
    },
  },

  async fn(inputs) {
    // Find and delete the archived card
    const archive = await Archive.findOne({
      id: inputs.archiveId,
      fromModel: 'card',
    });

    if (!archive) {
      throw new Error('Archived card not found');
    }

    const cardId = archive.originalRecordId;

    // Delete all related archives (tasks, attachments, labels, memberships, etc.)
    // Get task archives and delete those that belong to this card
    const taskArchives = await Archive.find({
      fromModel: 'task',
    });

    for (const taskArchive of taskArchives) {
      if (taskArchive.originalRecord.cardId === cardId) {
        await Archive.destroy({ id: taskArchive.id });
      }
    }

    // Get attachment archives and delete those that belong to this card
    const attachmentArchives = await Archive.find({
      fromModel: 'attachment',
    });

    for (const attachmentArchive of attachmentArchives) {
      if (attachmentArchive.originalRecord.cardId === cardId) {
        await Archive.destroy({ id: attachmentArchive.id });
      }
    }

    // Delete the card archive itself
    await Archive.destroy({ id: inputs.archiveId });

    return {
      success: true,
      message: 'Card permanently deleted',
    };
  },
};
