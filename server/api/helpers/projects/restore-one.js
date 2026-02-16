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
    request: {
      type: 'ref',
    },
  },

  async fn(inputs) {
    // Find the archived project record
    const projectArchive = await Archive.findOne({
      id: inputs.archiveId,
      fromModel: 'project',
    });

    if (!projectArchive) {
      throw new Error('Archived project not found');
    }

    // Recreate the project
    const projectData = projectArchive.originalRecord;
    const project = await Project.create({
      ...projectData,
    }).fetch();

    // Restore all boards for this project
    const boardArchives = await Archive.find({
      fromModel: 'board',
    });

    const boardIdMap = {}; // Map old board IDs to new board IDs

    for (const boardArchive of boardArchives) {
      // Only restore boards that belong to this project
      if (boardArchive.originalRecord.projectId !== projectArchive.originalRecordId) {
        continue;
      }

      const boardData = boardArchive.originalRecord;
      const board = await Board.create({
        ...boardData,
        projectId: project.id,
      }).fetch();

      boardIdMap[boardArchive.originalRecordId] = board.id;

      // Restore all lists for this board
      const listArchives = await Archive.find({
        fromModel: 'list',
      });

      const listIdMap = {}; // Map old list IDs to new list IDs

      for (const listArchive of listArchives) {
        // Only restore lists that belong to this board
        if (listArchive.originalRecord.boardId !== boardArchive.originalRecordId) {
          continue;
        }

        const listData = listArchive.originalRecord;
        const list = await List.create({
          ...listData,
          boardId: board.id,
        }).fetch();

        listIdMap[listArchive.originalRecordId] = list.id;

        // Restore all cards for this list
        const cardArchives = await Archive.find({
          fromModel: 'card',
        });

        for (const cardArchive of cardArchives) {
          // Only restore cards that belong to this list
          if (cardArchive.originalRecord.listId !== listArchive.originalRecordId) {
            continue;
          }

          const cardData = cardArchive.originalRecord;
          const card = await Card.create({
            ...cardData,
            boardId: board.id,
            listId: list.id,
          }).fetch();

          // Restore tasks for this card
          const taskArchives = await Archive.find({
            fromModel: 'task',
          });

          for (const taskArchive of taskArchives) {
            // Only restore tasks that belong to this card
            if (taskArchive.originalRecord.cardId !== cardArchive.originalRecordId) {
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

          // Restore attachments for this card
          const attachmentArchives = await Archive.find({
            fromModel: 'attachment',
          });

          for (const attachmentArchive of attachmentArchives) {
            // Only restore attachments that belong to this card
            if (attachmentArchive.originalRecord.cardId !== cardArchive.originalRecordId) {
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

          // Delete the card archive
          await Archive.destroy({ id: cardArchive.id });
        }

        // Delete the list archive
        await Archive.destroy({ id: listArchive.id });
      }

      // Restore board memberships
      const boardMembershipArchives = await Archive.find({
        fromModel: 'board-membership',
      });

      for (const membershipArchive of boardMembershipArchives) {
        // Only restore memberships that belong to this board
        if (membershipArchive.originalRecord.boardId !== boardArchive.originalRecordId) {
          continue;
        }

        const membershipData = membershipArchive.originalRecord;
        await BoardMembership.create({
          ...membershipData,
          boardId: board.id,
        }).fetch();

        // Delete from archive
        await Archive.destroy({ id: membershipArchive.id });
      }

      // Restore labels
      const labelArchives = await Archive.find({
        fromModel: 'label',
      });

      for (const labelArchive of labelArchives) {
        // Only restore labels that belong to this board
        if (labelArchive.originalRecord.boardId !== boardArchive.originalRecordId) {
          continue;
        }

        const labelData = labelArchive.originalRecord;
        await Label.create({
          ...labelData,
          boardId: board.id,
        }).fetch();

        // Delete from archive
        await Archive.destroy({ id: labelArchive.id });
      }

      // Delete the board archive
      await Archive.destroy({ id: boardArchive.id });
    }

    // Delete the project archive
    await Archive.destroy({ id: projectArchive.id });

    // Broadcast socket event to user
    sails.sockets.broadcast(
      `user:${inputs.actorUser.id}`,
      'projectCreate',
      {
        item: project,
      },
      inputs.request,
    );

    sails.helpers.utils.sendWebhooks.with({
      event: 'projectCreate',
      data: {
        item: project,
      },
      user: inputs.actorUser,
    });

    return project;
  },
};
