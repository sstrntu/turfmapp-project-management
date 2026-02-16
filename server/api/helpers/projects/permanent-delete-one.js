/* eslint-disable no-restricted-syntax, no-await-in-loop, no-continue */

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
    // Find the archived project
    const projectArchive = await Archive.findOne({
      id: inputs.archiveId,
      fromModel: 'project',
    });

    if (!projectArchive) {
      throw new Error('Archived project not found');
    }

    const projectId = projectArchive.originalRecordId;

    // Delete all related archives
    // Delete all board-related archives
    const boardArchives = await Archive.find({
      fromModel: 'board',
    });

    for (const boardArchive of boardArchives) {
      // Only delete boards that belong to this project
      if (boardArchive.originalRecord.projectId !== projectId) {
        continue;
      }

      const boardId = boardArchive.originalRecordId;

      // Delete all lists for this board
      const listArchives = await Archive.find({
        fromModel: 'list',
      });

      for (const listArchive of listArchives) {
        if (listArchive.originalRecord.boardId === boardId) {
          await Archive.destroy({ id: listArchive.id });
        }
      }

      // Delete all cards for this board (and their related data)
      const cardArchives = await Archive.find({
        fromModel: 'card',
      });

      for (const cardArchive of cardArchives) {
        if (cardArchive.originalRecord.boardId !== boardId) {
          continue;
        }

        const cardId = cardArchive.originalRecordId;

        // Delete tasks, attachments for this card
        const taskArchives = await Archive.find({
          fromModel: 'task',
        });

        for (const taskArchive of taskArchives) {
          if (taskArchive.originalRecord.cardId === cardId) {
            await Archive.destroy({ id: taskArchive.id });
          }
        }

        const attachmentArchives = await Archive.find({
          fromModel: 'attachment',
        });

        for (const attachmentArchive of attachmentArchives) {
          if (attachmentArchive.originalRecord.cardId === cardId) {
            await Archive.destroy({ id: attachmentArchive.id });
          }
        }

        // Delete the card archive
        await Archive.destroy({ id: cardArchive.id });
      }

      // Delete labels and board memberships
      const labelArchives = await Archive.find({
        fromModel: 'label',
      });

      for (const labelArchive of labelArchives) {
        if (labelArchive.originalRecord.boardId === boardId) {
          await Archive.destroy({ id: labelArchive.id });
        }
      }

      const membershipArchives = await Archive.find({
        fromModel: 'board-membership',
      });

      for (const membershipArchive of membershipArchives) {
        if (membershipArchive.originalRecord.boardId === boardId) {
          await Archive.destroy({ id: membershipArchive.id });
        }
      }

      // Delete the board archive
      await Archive.destroy({ id: boardArchive.id });
    }

    // Delete the project archive itself
    await Archive.destroy({ id: inputs.archiveId });

    return {
      success: true,
      message: 'Project permanently deleted',
    };
  },
};
