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
    board: {
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
    // Cascade archive: Archive all cards in this list before archiving the list
    const cards = await sails.helpers.lists.getCards(inputs.record.id);
    const cardIds = sails.helpers.utils.mapRecords(cards);

    for (const cardId of cardIds) {
      await Card.archiveOne(cardId);
    }

    const list = await List.archiveOne(inputs.record.id);

    if (list) {
      sails.sockets.broadcast(
        `board:${list.boardId}`,
        'listDelete',
        {
          item: list,
        },
        inputs.request,
      );

      sails.helpers.utils.sendWebhooks.with({
        event: 'listDelete',
        data: {
          item: list,
          included: {
            projects: [inputs.project],
            boards: [inputs.board],
          },
        },
        user: inputs.actorUser,
      });
    }

    return list;
  },
};
