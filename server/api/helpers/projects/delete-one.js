module.exports = {
  inputs: {
    record: {
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
    // Cascade archive: Archive all boards, lists, and cards before archiving the project
    const boards = await sails.helpers.projects.getBoards(inputs.record.id);
    const boardIds = sails.helpers.utils.mapRecords(boards);

    // Archive all cards in all lists of all boards
    for (const boardId of boardIds) {
      const lists = await sails.helpers.boards.getLists(boardId);
      const listIds = sails.helpers.utils.mapRecords(lists);

      for (const listId of listIds) {
        const cards = await sails.helpers.lists.getCards(listId);
        const cardIds = sails.helpers.utils.mapRecords(cards);

        for (const cardId of cardIds) {
          await Card.archiveOne(cardId);
        }
      }
    }

    // Archive all lists in all boards
    for (const boardId of boardIds) {
      const lists = await sails.helpers.boards.getLists(boardId);
      const listIds = sails.helpers.utils.mapRecords(lists);

      for (const listId of listIds) {
        await List.archiveOne(listId);
      }
    }

    // Archive all labels in all boards
    const labels = await Label.find({ boardId: boardIds });
    for (const label of labels) {
      await Label.archiveOne(label.id);
    }

    // Archive all boards
    for (const boardId of boardIds) {
      const boardMemberships = await BoardMembership.destroy({ boardId }).fetch();
      await Board.archiveOne(boardId);
    }

    // Finally, destroy ProjectManagers and archive the project
    const projectManagers = await ProjectManager.destroy({
      projectId: inputs.record.id,
    }).fetch();

    const project = await Project.archiveOne(inputs.record.id);

    if (project) {
      const projectManagerUserIds = sails.helpers.utils.mapRecords(projectManagers, 'userId');

      const boardRooms = boardIds.map((boardId) => `board:${boardId}`);

      const boardMemberUserIds = await sails.helpers.boards.getMemberUserIds(boardIds);
      const projectRelatedUserIds = _.union(projectManagerUserIds, boardMemberUserIds);

      projectRelatedUserIds.forEach((userId) => {
        sails.sockets.removeRoomMembersFromRooms(`@user:${userId}`, boardRooms);

        sails.sockets.broadcast(
          `user:${userId}`,
          'projectDelete',
          {
            item: project,
          },
          inputs.request,
        );
      });

      sails.helpers.utils.sendWebhooks.with({
        event: 'projectDelete',
        data: {
          item: project,
        },
        user: inputs.actorUser,
      });
    }

    return project;
  },
};
