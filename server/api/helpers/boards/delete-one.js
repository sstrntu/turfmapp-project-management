module.exports = {
  inputs: {
    record: {
      type: 'ref',
      required: true,
    },
    project: {
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
    // Cascade archive: Archive all lists and cards before archiving the board
    const lists = await sails.helpers.boards.getLists(inputs.record.id);
    const listIds = sails.helpers.utils.mapRecords(lists);

    // Archive all cards in all lists
    for (const listId of listIds) {
      const cards = await sails.helpers.lists.getCards(listId);
      const cardIds = sails.helpers.utils.mapRecords(cards);

      for (const cardId of cardIds) {
        await Card.archiveOne(cardId);
      }
    }

    // Archive all lists
    for (const listId of listIds) {
      await List.archiveOne(listId);
    }

    // Archive all labels on this board
    const labels = await Label.find({ boardId: inputs.record.id });
    for (const label of labels) {
      await Label.archiveOne(label.id);
    }

    // Finally, destroy BoardMemberships and archive the board
    const boardMemberships = await BoardMembership.destroy({
      boardId: inputs.record.id,
    }).fetch();

    const board = await Board.archiveOne(inputs.record.id);

    if (board) {
      sails.sockets.removeRoomMembersFromRooms(`board:${board.id}`, `board:${board.id}`);

      const projectManagerUserIds = await sails.helpers.projects.getManagerUserIds(board.projectId);
      const boardMemberUserIds = sails.helpers.utils.mapRecords(boardMemberships, 'userId');
      const boardRelatedUserIds = _.union(projectManagerUserIds, boardMemberUserIds);

      boardRelatedUserIds.forEach((userId) => {
        sails.sockets.broadcast(
          `user:${userId}`,
          'boardDelete',
          {
            item: board,
          },
          inputs.request,
        );
      });

      sails.helpers.utils.sendWebhooks.with({
        event: 'boardDelete',
        data: {
          item: board,
          included: {
            projects: [inputs.project],
          },
        },
        user: inputs.actorUser,
      });
    }

    return board;
  },
};
