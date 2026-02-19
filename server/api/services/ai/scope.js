const MAX_CARDS_IN_PROMPT = 350;

const normalizeName = (value) =>
  String(value || '')
    .trim()
    .toLowerCase();

const getRecordName = (record, defaultValue = '') => {
  if (!record || !record.name) {
    return defaultValue;
  }

  return record.name;
};

const buildPromptSummary = (scope) => {
  const boardById = _.keyBy(scope.boards, 'id');
  const listById = _.keyBy(scope.lists, 'id');

  const cardsForPrompt = scope.cards.slice(0, MAX_CARDS_IN_PROMPT);
  const boardsSummary = scope.boards.map((board) => ({
    id: board.id,
    name: board.name,
    projectId: board.projectId,
    projectName: getRecordName(scope.projectById[board.projectId], null),
  }));

  const listsSummary = scope.lists.map((list) => ({
    id: list.id,
    name: list.name,
    boardId: list.boardId,
    boardName: getRecordName(boardById[list.boardId], null),
  }));

  const cardsSummary = cardsForPrompt.map((card) => ({
    id: card.id,
    name: card.name,
    description: card.description || null,
    dueDate: card.dueDate || null,
    listId: card.listId,
    listName: getRecordName(listById[card.listId], null),
    boardId: card.boardId,
    boardName: getRecordName(boardById[card.boardId], null),
  }));

  const workloadByUserId = _.isPlainObject(scope.workloadByUserId) ? scope.workloadByUserId : {};
  const usersSummary = (scope.users || []).map((user) => ({
    id: user.id,
    name: user.name,
    email: user.email || null,
    username: user.username || null,
    skills: _.isArray(user.skills) ? user.skills : [],
    activeCards: Number(workloadByUserId[user.id] || 0),
  }));

  return {
    projects: scope.projects.map((project) => ({
      id: project.id,
      name: project.name,
    })),
    users: usersSummary,
    boards: boardsSummary,
    lists: listsSummary,
    cards: cardsSummary,
    cardsTruncated: scope.cards.length > cardsForPrompt.length,
  };
};

const getAuthorizedScope = async (userId, context = {}) => {
  const managerProjectIds = await sails.helpers.users.getManagerProjectIds(userId);
  const managerProjects =
    managerProjectIds.length > 0 ? await sails.helpers.projects.getMany(managerProjectIds) : [];

  const boardMemberships = await sails.helpers.users.getBoardMemberships(userId);
  const membershipBoardIds = sails.helpers.utils.mapRecords(boardMemberships, 'boardId');

  const membershipBoardsCriteria = {
    id: membershipBoardIds,
  };
  if (managerProjectIds.length > 0) {
    membershipBoardsCriteria.projectId = {
      nin: managerProjectIds,
    };
  }

  const membershipBoardsResult =
    membershipBoardIds.length > 0
      ? await sails.helpers.boards.getMany(membershipBoardsCriteria)
      : [];

  const membershipProjectIdsTmp = sails.helpers.utils.mapRecords(
    membershipBoardsResult,
    'projectId',
    true,
  );
  const membershipProjects =
    membershipProjectIdsTmp.length > 0
      ? await sails.helpers.projects.getMany(membershipProjectIdsTmp)
      : [];
  const membershipProjectIds = sails.helpers.utils.mapRecords(membershipProjects);

  const projects = _.uniqBy([...managerProjects, ...membershipProjects], 'id');

  const managerBoards =
    managerProjectIds.length > 0 ? await sails.helpers.projects.getBoards(managerProjectIds) : [];

  const membershipBoards = membershipBoardsResult.filter((membershipBoard) =>
    membershipProjectIds.includes(membershipBoard.projectId),
  );

  let boards = _.uniqBy([...managerBoards, ...membershipBoards], 'id');

  if (context.projectId) {
    boards = boards.filter((board) => board.projectId === context.projectId);
  }

  if (context.boardId) {
    boards = boards.filter((board) => board.id === context.boardId);
  }

  const boardIds = sails.helpers.utils.mapRecords(boards);
  const lists = boardIds.length > 0 ? await sails.helpers.boards.getLists(boardIds) : [];
  const cards = boardIds.length > 0 ? await sails.helpers.boards.getCards(boardIds) : [];
  const cardIds = sails.helpers.utils.mapRecords(cards);
  const cardMemberships =
    cardIds.length > 0 ? await sails.helpers.cards.getCardMemberships(cardIds) : [];
  const boardMembershipsInScope =
    boardIds.length > 0 ? await sails.helpers.boards.getBoardMemberships(boardIds) : [];
  const boardMemberUserIds = _.uniq(
    boardMembershipsInScope.map((boardMembership) => boardMembership.userId),
  );
  const usersInScope =
    boardMemberUserIds.length > 0 ? await sails.helpers.users.getMany(boardMemberUserIds) : [];

  const filteredProjectIds = _.uniq(boards.map((board) => board.projectId));
  const scopedProjects =
    filteredProjectIds.length > 0
      ? projects.filter((project) => filteredProjectIds.includes(project.id))
      : projects;

  const listById = _.keyBy(lists, 'id');
  const boardById = _.keyBy(boards, 'id');
  const projectById = _.keyBy(scopedProjects, 'id');
  const userById = _.keyBy(usersInScope, 'id');
  const workloadByUserId = cardMemberships.reduce((result, membership) => {
    const { userId: membershipUserId } = membership;

    if (!userById[membershipUserId]) {
      return result;
    }

    return {
      ...result,
      [membershipUserId]: (result[membershipUserId] || 0) + 1,
    };
  }, {});

  return {
    projects: scopedProjects,
    users: usersInScope,
    boards,
    lists,
    cards,
    cardMemberships,
    projectById,
    boardById,
    listById,
    userById,
    workloadByUserId,
  };
};

const createSearchIndex = (scope) => {
  const cardIndex = scope.cards.map((card) => {
    const list = scope.listById[card.listId];
    const board = scope.boardById[card.boardId];
    const project = board ? scope.projectById[board.projectId] : null;

    return {
      ...card,
      normalizedName: normalizeName(card.name),
      normalizedDescription: normalizeName(card.description || ''),
      listName: getRecordName(list),
      normalizedListName: normalizeName(getRecordName(list)),
      boardName: getRecordName(board),
      normalizedBoardName: normalizeName(getRecordName(board)),
      projectName: getRecordName(project),
      normalizedProjectName: normalizeName(getRecordName(project)),
    };
  });

  const listIndex = scope.lists.map((list) => {
    const board = scope.boardById[list.boardId];
    const project = board ? scope.projectById[board.projectId] : null;

    return {
      ...list,
      normalizedName: normalizeName(list.name),
      boardName: getRecordName(board),
      normalizedBoardName: normalizeName(getRecordName(board)),
      projectName: getRecordName(project),
      normalizedProjectName: normalizeName(getRecordName(project)),
    };
  });

  const boardIndex = scope.boards.map((board) => {
    const project = scope.projectById[board.projectId];

    return {
      ...board,
      normalizedName: normalizeName(board.name),
      projectName: getRecordName(project),
      normalizedProjectName: normalizeName(getRecordName(project)),
    };
  });

  return {
    cards: cardIndex,
    lists: listIndex,
    boards: boardIndex,
  };
};

module.exports = {
  getAuthorizedScope,
  buildPromptSummary,
  createSearchIndex,
};
