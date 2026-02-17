module.exports = {
  async fn() {
    const { currentUser } = this.req;

    if (!currentUser) {
      return {
        error: 'Not authenticated',
        projects: [],
        boards: [],
        lists: [],
        cards: [],
        cardMemberships: [],
        users: [],
      };
    }

    // Same authorization pattern as projects/index.js
    const managerProjectIds = await sails.helpers.users.getManagerProjectIds(currentUser.id);
    const managerProjects = await sails.helpers.projects.getMany(managerProjectIds);

    const boardMemberships = await sails.helpers.users.getBoardMemberships(currentUser.id);
    const membershipBoardIds = sails.helpers.utils.mapRecords(boardMemberships, 'boardId');

    const membershipBoardsResult = boardMemberships.length > 0
      ? await sails.helpers.boards.getMany({
        id: membershipBoardIds,
        projectId: {
          '!=': managerProjectIds,
        },
      })
      : [];

    const membershipProjectIdsTmp = sails.helpers.utils.mapRecords(membershipBoardsResult, 'projectId', true);
    const membershipProjects = await sails.helpers.projects.getMany(membershipProjectIdsTmp);

    const membershipProjectIds = sails.helpers.utils.mapRecords(membershipProjects);

    const projects = [...managerProjects, ...membershipProjects];

    const managerBoards = await sails.helpers.projects.getBoards(managerProjectIds);

    const membershipBoards = membershipBoardsResult.filter((membershipBoard) =>
      membershipProjectIds.includes(membershipBoard.projectId),
    );

    const boards = [...managerBoards, ...membershipBoards];
    const boardIds = sails.helpers.utils.mapRecords(boards);

    // Fetch lists, cards, and memberships for all accessible boards
    const lists = await sails.helpers.boards.getLists(boardIds);
    const cards = await sails.helpers.boards.getCards(boardIds);
    const cardIds = sails.helpers.utils.mapRecords(cards);
    const cardMembershipsResult = cardIds.length > 0
      ? await sails.helpers.cards.getCardMemberships(cardIds)
      : [];

    // Collect unique user IDs from card memberships
    const memberUserIds = sails.helpers.utils.mapRecords(cardMembershipsResult, 'userId', true);
    const users = memberUserIds.length > 0
      ? await sails.helpers.users.getMany(memberUserIds)
      : [];

    return {
      projects: projects.map((p) => ({ id: p.id, name: p.name })),
      boards: boards.map((b) => ({ id: b.id, name: b.name, projectId: b.projectId })),
      lists: lists.map((l) => ({ id: l.id, name: l.name, boardId: l.boardId })),
      cards: cards.map((c) => ({
        id: c.id,
        name: c.name,
        listId: c.listId,
        boardId: c.boardId,
        dueDate: c.dueDate,
      })),
      cardMemberships: cardMembershipsResult.map((cm) => ({
        cardId: cm.cardId,
        userId: cm.userId,
      })),
      users: users.map((u) => ({ id: u.id, name: u.name, username: u.username })),
    };
  },
};
