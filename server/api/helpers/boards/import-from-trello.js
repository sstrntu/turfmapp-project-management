const POSITION_GAP = 65535; // TODO: move to config

module.exports = {
  inputs: {
    board: {
      type: 'ref',
      required: true,
    },
    trelloBoard: {
      type: 'json',
      required: true,
    },
    actorUser: {
      type: 'ref',
      required: true,
    },
  },

  async fn(inputs) {
    const trelloToLocalLabels = {};

    const getTrelloLists = () => inputs.trelloBoard.lists.filter((list) => !list.closed);

    const getUsedTrelloLabels = () => {
      const result = {};
      inputs.trelloBoard.cards
        .map((card) => card.labels)
        .flat()
        .forEach((label) => {
          result[label.id] = label;
        });

      return Object.values(result);
    };

    const getTrelloCardsOfList = (listId) =>
      inputs.trelloBoard.cards.filter((card) => card.idList === listId && !card.closed);

    const getAllTrelloCheckItemsOfCard = (cardId) =>
      inputs.trelloBoard.checklists
        .filter((checklist) => checklist.idCard === cardId)
        .map((checklist) => checklist.checkItems)
        .flat();

    const getTrelloCommentsOfCard = (cardId) =>
      inputs.trelloBoard.actions.filter(
        (action) =>
          action.type === 'commentCard' &&
          action.data &&
          action.data.card &&
          action.data.card.id === cardId,
      );

    const getLabelColor = (trelloLabelColor) =>
      Label.COLORS.find((color) => color.indexOf(trelloLabelColor) !== -1) || 'desert-sand';

    const importCardLabels = async (localCard, trelloCard) => {
      return Promise.all(
        trelloCard.labels.map(async (trelloLabel) => {
          return CardLabel.create({
            cardId: localCard.id,
            labelId: trelloToLocalLabels[trelloLabel.id].id,
          });
        }),
      );
    };

    const importTasks = async (localCard, trelloCard) => {
      // TODO find workaround for tasks/checklist mismapping
      return Promise.all(
        getAllTrelloCheckItemsOfCard(trelloCard.id).map(async (trelloCheckItem) => {
          return Task.create({
            cardId: localCard.id,
            position: trelloCheckItem.pos,
            name: trelloCheckItem.name,
            isCompleted: trelloCheckItem.state === 'complete',
          }).fetch();
        }),
      );
    };

    const importComments = async (localCard, trelloCard) => {
      const trelloComments = getTrelloCommentsOfCard(trelloCard.id);
      trelloComments.sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());

      return Promise.all(
        trelloComments.map(async (trelloComment) => {
          return Action.create({
            cardId: localCard.id,
            userId: inputs.actorUser.id,
            type: 'commentCard',
            data: {
              text:
                `${trelloComment.data.text}\n\n---\n*Note: imported comment, originally posted by ` +
                `\n${trelloComment.memberCreator.fullName} (${trelloComment.memberCreator.username}) on ${trelloComment.date}*`,
            },
          }).fetch();
        }),
      );
    };

    const importCards = async (localList, trelloList) => {
      return Promise.all(
        getTrelloCardsOfList(trelloList.id).map(async (trelloCard) => {
          const localCard = await Card.create({
            boardId: inputs.board.id,
            listId: localList.id,
            creatorUserId: inputs.actorUser.id,
            position: trelloCard.pos,
            name: trelloCard.name,
            description: trelloCard.desc || null,
            dueDate: trelloCard.due,
          }).fetch();

          await importCardLabels(localCard, trelloCard);
          await importTasks(localCard, trelloCard);
          await importComments(localCard, trelloCard);

          return localCard;
        }),
      );
    };

    const importLabels = async () => {
      return Promise.all(
        getUsedTrelloLabels().map(async (trelloLabel, index) => {
          const localLabel = await Label.create({
            boardId: inputs.board.id,
            position: POSITION_GAP * (index + 1),
            name: trelloLabel.name || null,
            color: getLabelColor(trelloLabel.color),
          }).fetch();

          trelloToLocalLabels[trelloLabel.id] = localLabel;
        }),
      );
    };

    const importLists = async () => {
      return Promise.all(
        getTrelloLists().map(async (trelloList) => {
          const localList = await List.create({
            boardId: inputs.board.id,
            name: trelloList.name,
            position: trelloList.pos,
          }).fetch();

          return importCards(localList, trelloList);
        }),
      );
    };

    await importLabels();
    await importLists();
  },
};
