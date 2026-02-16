/* eslint-disable no-restricted-syntax, no-await-in-loop, no-continue */

module.exports = {
  inputs: {
    archiveId: {
      type: 'string',
      required: true,
    },
    project: {
      type: 'ref',
      required: true,
    },
    board: {
      type: 'ref',
      required: true,
    },
    list: {
      type: 'ref',
      required: true,
    },
    actorUser: {
      type: 'ref',
      required: true,
    },
    request: {
      type: 'ref',
    },
  },

  async fn(inputs) {
    // Find the archived card record
    const archive = await Archive.findOne({
      id: inputs.archiveId,
      fromModel: 'card',
    });

    if (!archive) {
      throw new Error('Archived card not found');
    }

    // Recreate the card from the archived data
    const archivedData = archive.originalRecord;

    // Create the card
    const card = await Card.create({
      ...archivedData,
      boardId: inputs.board.id,
      listId: inputs.list.id,
    }).fetch();

    // Restore related records from archive
    // Restore tasks
    const taskArchives = await Archive.find({
      fromModel: 'task',
    });

    for (const taskArchive of taskArchives) {
      // Only restore tasks that belong to this card
      if (taskArchive.originalRecord.cardId !== archive.originalRecordId) {
        continue;
      }

      const taskData = taskArchive.originalRecord;
      await Task.create({
        ...taskData,
        cardId: card.id,
      }).fetch();

      // Delete from archive after restore
      await Archive.destroy({ id: taskArchive.id });
    }

    // Restore attachments
    const attachmentArchives = await Archive.find({
      fromModel: 'attachment',
    });

    for (const attachmentArchive of attachmentArchives) {
      // Only restore attachments that belong to this card
      if (attachmentArchive.originalRecord.cardId !== archive.originalRecordId) {
        continue;
      }

      const attachmentData = attachmentArchive.originalRecord;
      await Attachment.create({
        ...attachmentData,
        cardId: card.id,
      }).fetch();

      // Delete from archive after restore
      await Archive.destroy({ id: attachmentArchive.id });
    }

    // Delete the card archive record
    await Archive.destroy({ id: archive.id });

    // Broadcast socket event
    sails.sockets.broadcast(
      `board:${card.boardId}`,
      'cardCreate',
      {
        item: card,
      },
      inputs.request,
    );

    sails.helpers.utils.sendWebhooks.with({
      event: 'cardCreate',
      data: {
        item: card,
        included: {
          projects: [inputs.project],
          boards: [inputs.board],
          lists: [inputs.list],
        },
      },
      user: inputs.actorUser,
    });

    return card;
  },
};
