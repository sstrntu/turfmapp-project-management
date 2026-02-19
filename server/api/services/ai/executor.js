const scopeService = require('./scope');
const { ACTION_TYPES } = require('./constants');

const POSITION_GAP = 65535;
const DEFAULT_LABEL_COLOR = 'lagoon-blue';
const ALLOWED_CARD_CHANGE_FIELDS = new Set([
  'name',
  'description',
  'dueDate',
  'color',
  'isDueDateCompleted',
]);

const normalize = (value) =>
  String(value || '')
    .trim()
    .toLowerCase();

const scoreName = (name, query) => {
  if (!query) {
    return 0;
  }

  const normalizedName = normalize(name);
  const normalizedQuery = normalize(query);

  if (!normalizedName || !normalizedQuery) {
    return 0;
  }

  if (normalizedName === normalizedQuery) {
    return 3;
  }

  if (normalizedName.startsWith(normalizedQuery)) {
    return 2;
  }

  if (normalizedName.includes(normalizedQuery)) {
    return 1;
  }

  return 0;
};

const toUniqueStringArray = (...values) => {
  const unique = new Set();

  const items = values.reduce((result, value) => {
    if (_.isArray(value)) {
      return result.concat(value);
    }

    if (_.isPlainObject(value)) {
      return result.concat(value.name || value.username || value.email || value.id);
    }

    if (!_.isNil(value)) {
      return result.concat(value);
    }

    return result;
  }, []);

  return items.reduce((result, value) => {
    const raw = String(value || '').trim();

    if (!raw) {
      return result;
    }

    const parts = raw.split(',').map((part) => part.trim());

    parts.forEach((part) => {
      if (!part) {
        return;
      }

      const key = part.toLowerCase();

      if (unique.has(key)) {
        return;
      }

      unique.add(key);
      result.push(part);
    });

    return result;
  }, []);
};

const collectLabelNames = (args = {}, changes = {}) =>
  toUniqueStringArray(
    args.label,
    args.labels,
    args.labelNames,
    args.addLabels,
    changes.label,
    changes.labels,
    changes.labelNames,
    changes.addLabels,
  );

const collectAssigneeQueries = (args = {}, changes = {}) =>
  toUniqueStringArray(
    args.assignee,
    args.assignees,
    args.assigneeName,
    args.assigneeNames,
    args.assignTo,
    args.assign,
    args.user,
    args.users,
    args.userName,
    args.userNames,
    args.member,
    args.members,
    args.skills,
    changes.assignee,
    changes.assignees,
    changes.assigneeName,
    changes.assigneeNames,
    changes.assignTo,
    changes.assign,
    changes.user,
    changes.users,
    changes.userName,
    changes.userNames,
    changes.member,
    changes.members,
    changes.skills,
  );

const pickAllowedCardChanges = (changes = {}) =>
  Object.keys(changes).reduce(
    (result, key) =>
      ALLOWED_CARD_CHANGE_FIELDS.has(key)
        ? {
            ...result,
            [key]: changes[key],
          }
        : result,
    {},
  );

const selectUniqueMatch = (items, label, query) => {
  if (!items || items.length === 0) {
    return {
      item: null,
      error: `Could not find ${label} "${query}".`,
    };
  }

  if (items.length > 1) {
    const options = items
      .slice(0, 5)
      .map((item) => `"${item.name}"`)
      .join(', ');
    return {
      item: null,
      error: `Ambiguous ${label} "${query}". Matches: ${options}.`,
    };
  }

  return {
    item: items[0],
    error: null,
  };
};

const filterByOptionalScope = (item, args) => {
  if (args.projectName && scoreName(item.projectName, args.projectName) === 0) {
    return false;
  }

  if (args.boardName && scoreName(item.boardName, args.boardName) === 0) {
    return false;
  }

  if (args.listName && scoreName(item.listName, args.listName) === 0) {
    return false;
  }

  return true;
};

const resolveBoard = (index, args = {}) => {
  const requestedName = args.boardName || args.board || args.name;

  if (!requestedName && index.boards.length === 1) {
    return {
      item: index.boards[0],
      error: null,
    };
  }

  const matches = index.boards
    .filter((board) => !args.projectName || scoreName(board.projectName, args.projectName) > 0)
    .map((board) => ({
      ...board,
      score: scoreName(board.name, requestedName),
    }))
    .filter((board) => board.score > 0)
    .sort((a, b) => b.score - a.score);

  return selectUniqueMatch(matches, 'board', requestedName);
};

const resolveList = (index, args = {}) => {
  const requestedName = args.listName || args.targetListName || args.name;

  if (!requestedName && index.lists.length === 1) {
    return {
      item: index.lists[0],
      error: null,
    };
  }

  const matches = index.lists
    .filter((list) =>
      filterByOptionalScope(
        {
          ...list,
          listName: list.name,
        },
        args,
      ),
    )
    .map((list) => ({
      ...list,
      score: scoreName(list.name, requestedName),
    }))
    .filter((list) => list.score > 0)
    .sort((a, b) => b.score - a.score);

  return selectUniqueMatch(matches, 'list', requestedName);
};

const resolveCard = (index, args = {}) => {
  const requestedName = args.cardName || args.name;

  const matches = index.cards
    .filter((card) => filterByOptionalScope(card, args))
    .map((card) => ({
      ...card,
      score: scoreName(card.name, requestedName),
    }))
    .filter((card) => card.score > 0)
    .sort((a, b) => b.score - a.score);

  return selectUniqueMatch(matches, 'card', requestedName);
};

const resolveUser = (scope, query) => {
  const requestedValue = String(query || '').trim();

  if (!requestedValue) {
    return {
      item: null,
      error: 'Could not resolve user from an empty assignee value.',
    };
  }

  const users = scope && _.isArray(scope.users) ? scope.users : [];
  const workloadByUserId =
    scope && _.isPlainObject(scope.workloadByUserId) ? scope.workloadByUserId : {};

  if (users.length === 1) {
    return {
      item: users[0],
      error: null,
    };
  }

  const exactIdMatch = users.find((user) => String(user.id) === requestedValue);

  if (exactIdMatch) {
    return {
      item: exactIdMatch,
      error: null,
    };
  }

  const matches = users
    .map((user) => {
      const nameScore = scoreName(user.name, requestedValue);
      const usernameScore = scoreName(user.username || '', requestedValue);
      const emailScore = scoreName(user.email || '', requestedValue);

      const skillScore = (_.isArray(user.skills) ? user.skills : []).reduce(
        (bestScore, skill) => Math.max(bestScore, scoreName(skill, requestedValue)),
        0,
      );

      const score = Math.max(nameScore, usernameScore, emailScore, skillScore);

      if (score === 0) {
        return null;
      }

      return {
        ...user,
        score,
      };
    })
    .filter(Boolean)
    .sort((a, b) => {
      if (b.score !== a.score) {
        return b.score - a.score;
      }

      const aWorkload = Number(workloadByUserId[a.id] || 0);
      const bWorkload = Number(workloadByUserId[b.id] || 0);
      if (aWorkload !== bWorkload) {
        return aWorkload - bWorkload;
      }

      return String(a.name || '').localeCompare(String(b.name || ''));
    });

  if (!matches.length) {
    return {
      item: null,
      error: `Could not find user "${requestedValue}".`,
    };
  }

  const bestScore = matches[0].score;
  const topMatches = matches.filter((match) => match.score === bestScore);

  return {
    item: topMatches[0],
    error: null,
  };
};

const resolveBoardLabel = (labels, query) => {
  const requestedName = String(query || '').trim();

  if (!requestedName) {
    return {
      item: null,
      error: 'Could not resolve label from an empty value.',
    };
  }

  const matches = labels
    .map((label) => ({
      ...label,
      score: scoreName(label.name, requestedName),
    }))
    .filter((label) => label.score > 0)
    .sort((a, b) => b.score - a.score);

  return selectUniqueMatch(matches, 'label', requestedName);
};

const getNextPosition = async (listId) => {
  const cards = await sails.helpers.lists.getCards(listId);
  const lastCard = cards[cards.length - 1];

  return (lastCard ? lastCard.position : 0) + POSITION_GAP;
};

const getNextListPosition = async (boardId) => {
  const lists = await sails.helpers.boards.getLists(boardId);
  const lastList = lists[lists.length - 1];

  return (lastList ? lastList.position : 0) + POSITION_GAP;
};

const getNextLabelPosition = async (boardId) => {
  const labels = await sails.helpers.boards.getLabels(boardId);
  const lastLabel = labels[labels.length - 1];

  return (lastLabel ? lastLabel.position : 0) + POSITION_GAP;
};

const ensureEditorMembership = async (boardId, userId) => {
  const boardMembership = await BoardMembership.findOne({
    boardId,
    userId,
  });

  if (!boardMembership) {
    throw new Error('Not enough rights');
  }

  if (boardMembership.role !== BoardMembership.Roles.EDITOR) {
    throw new Error('Not enough rights');
  }
};

const applyCardLabels = async ({ labelNames, card, path, currentUser, request }) => {
  if (!labelNames.length) {
    return [];
  }

  const cardLabels = await sails.helpers.cards.getCardLabels(card.id);
  const existingLabelIds = new Set(cardLabels.map((cardLabel) => cardLabel.labelId));
  let labels = await sails.helpers.boards.getLabels(path.board.id);
  const addedLabelNames = [];

  await labelNames.reduce(
    (chain, labelName) =>
      chain.then(async () => {
        const { item: matchedLabel } = resolveBoardLabel(labels, labelName);

        let label = matchedLabel;

        if (!label) {
          label = await sails.helpers.labels.createOne.with({
            project: path.project,
            values: {
              board: path.board,
              position: await getNextLabelPosition(path.board.id),
              name: labelName,
              color: DEFAULT_LABEL_COLOR,
            },
            actorUser: currentUser,
            request,
          });

          labels = [...labels, label];
        }

        if (existingLabelIds.has(label.id)) {
          return;
        }

        await sails.helpers.cardLabels.createOne.with({
          project: path.project,
          board: path.board,
          list: path.list,
          values: {
            card,
            label,
          },
          actorUser: currentUser,
          request,
        });

        existingLabelIds.add(label.id);
        addedLabelNames.push(label.name);
      }),
    Promise.resolve(),
  );

  return addedLabelNames;
};

const applyCardAssignees = async ({ assigneeQueries, card, path, scope, currentUser, request }) => {
  if (!assigneeQueries.length) {
    return [];
  }

  const workloadByUserId =
    scope && _.isPlainObject(scope.workloadByUserId) ? { ...scope.workloadByUserId } : {};
  const cardMemberships = await sails.helpers.cards.getCardMemberships(card.id);
  const existingUserIds = new Set(cardMemberships.map((membership) => String(membership.userId)));
  const addedAssigneeNames = [];

  await assigneeQueries.reduce(
    (chain, query) =>
      chain.then(async () => {
        const { item: user, error } = resolveUser(
          {
            ...scope,
            workloadByUserId,
          },
          query,
        );

        if (!user) {
          throw new Error(error);
        }

        if (existingUserIds.has(String(user.id))) {
          return;
        }

        const boardMembership = await BoardMembership.findOne({
          boardId: path.board.id,
          userId: user.id,
        });

        if (!boardMembership) {
          throw new Error(`User "${user.name}" is not a member of board "${path.board.name}".`);
        }

        await sails.helpers.cardMemberships.createOne.with({
          project: path.project,
          board: path.board,
          list: path.list,
          values: {
            card,
            user,
          },
          actorUser: currentUser,
          request,
        });

        existingUserIds.add(String(user.id));
        addedAssigneeNames.push(user.name);
        workloadByUserId[user.id] = Number(workloadByUserId[user.id] || 0) + 1;
      }),
    Promise.resolve(),
  );

  return addedAssigneeNames;
};

const executeCreateCard = async ({ action, currentUser, request, index }) => {
  const args = action.args || {};
  const cardName = args.cardName || args.name;

  if (!cardName) {
    throw new Error('create_card requires cardName');
  }

  const { item: list, error } = resolveList(index, {
    ...args,
    listName: args.listName,
  });
  if (!list) {
    throw new Error(error);
  }

  const {
    list: listRecord,
    board,
    project,
  } = await sails.helpers.lists
    .getProjectPath({
      id: list.id,
    })
    .intercept('pathNotFound', () => {
      throw new Error(`Could not find list "${list.name}".`);
    });

  await ensureEditorMembership(board.id, currentUser.id);

  const position = await getNextPosition(listRecord.id);

  const card = await sails.helpers.cards.createOne.with({
    project,
    board,
    values: {
      list: listRecord,
      creatorUser: currentUser,
      position,
      name: cardName,
      description: args.description || null,
      ...(args.dueDate && {
        dueDate: args.dueDate,
      }),
      ...(args.color && {
        color: args.color,
      }),
    },
    request,
  });

  return {
    message: `Created card "${card.name}" in "${listRecord.name}".`,
    item: {
      id: card.id,
      name: card.name,
    },
  };
};

const executeUpdateCard = async ({ action, currentUser, request, index, scope }) => {
  const args = action.args || {};
  const { item: cardCandidate, error } = resolveCard(index, args);

  if (!cardCandidate) {
    throw new Error(error);
  }

  const path = await sails.helpers.cards
    .getProjectPath({
      id: cardCandidate.id,
    })
    .intercept('pathNotFound', () => {
      throw new Error(`Could not find card "${args.cardName}".`);
    });

  await ensureEditorMembership(path.board.id, currentUser.id);

  const rawChanges = _.isPlainObject(args.changes) ? { ...args.changes } : {};
  const labelNames = collectLabelNames(args, rawChanges);
  const assigneeQueries = collectAssigneeQueries(args, rawChanges);
  const changes = pickAllowedCardChanges(rawChanges);

  if (args.newName && !changes.name) {
    changes.name = args.newName;
  }

  if (args.description && _.isUndefined(changes.description)) {
    changes.description = args.description;
  }

  if (args.dueDate && _.isUndefined(changes.dueDate)) {
    changes.dueDate = args.dueDate;
  }

  if (args.color && _.isUndefined(changes.color)) {
    changes.color = args.color;
  }

  const targetListName = args.targetListName || rawChanges.targetListName || rawChanges.moveToList;
  let nextPath = null;
  if (targetListName) {
    const { item: targetList, error: listError } = resolveList(index, {
      ...args,
      listName: targetListName,
    });

    if (!targetList) {
      throw new Error(listError);
    }

    nextPath = await sails.helpers.lists
      .getProjectPath({
        id: targetList.id,
      })
      .intercept('pathNotFound', () => {
        throw new Error(`Could not find list "${targetListName}".`);
      });

    await ensureEditorMembership(nextPath.board.id, currentUser.id);

    changes.position = await getNextPosition(nextPath.list.id);
    changes.list = nextPath.list;
    changes.board = nextPath.board;
    changes.project = nextPath.project;
  }

  const hasCardFieldChanges = !_.isEmpty(changes);
  const hasLabelChanges = labelNames.length > 0;
  const hasAssigneeChanges = assigneeQueries.length > 0;

  if (!hasCardFieldChanges && !hasLabelChanges && !hasAssigneeChanges) {
    return {
      message: `No changes applied to "${path.card.name}".`,
      item: {
        id: path.card.id,
        name: path.card.name,
      },
    };
  }

  const effectivePath = nextPath || path;
  let { card } = path;

  if (hasCardFieldChanges) {
    card = await sails.helpers.cards.updateOne.with({
      project: path.project,
      board: path.board,
      list: path.list,
      record: path.card,
      values: changes,
      actorUser: currentUser,
      request,
    });
  }

  const addedLabelNames = await applyCardLabels({
    labelNames,
    card,
    path: effectivePath,
    currentUser,
    request,
  });
  const addedAssigneeNames = await applyCardAssignees({
    assigneeQueries,
    card,
    path: effectivePath,
    scope,
    currentUser,
    request,
  });

  const summaryParts = [];
  if (hasCardFieldChanges) {
    summaryParts.push('updated fields');
  }
  if (addedLabelNames.length > 0) {
    summaryParts.push(`labels: ${addedLabelNames.join(', ')}`);
  }
  if (addedAssigneeNames.length > 0) {
    summaryParts.push(`assignees: ${addedAssigneeNames.join(', ')}`);
  }

  return {
    message:
      summaryParts.length > 0
        ? `Updated card "${card.name}" (${summaryParts.join('; ')}).`
        : `Updated card "${card.name}".`,
    item: {
      id: card.id,
      name: card.name,
    },
  };
};

const executeMoveCard = async ({ action, currentUser, request, index }) => {
  const args = action.args || {};
  const { item: cardCandidate, error } = resolveCard(index, args);
  if (!cardCandidate) {
    throw new Error(error);
  }

  const { item: targetList, error: listError } = resolveList(index, {
    ...args,
    listName: args.targetListName,
  });
  if (!targetList) {
    throw new Error(listError);
  }

  const cardPath = await sails.helpers.cards.getProjectPath({
    id: cardCandidate.id,
  });
  const targetPath = await sails.helpers.lists.getProjectPath({
    id: targetList.id,
  });

  await ensureEditorMembership(cardPath.board.id, currentUser.id);
  await ensureEditorMembership(targetPath.board.id, currentUser.id);

  const card = await sails.helpers.cards.updateOne.with({
    project: cardPath.project,
    board: cardPath.board,
    list: cardPath.list,
    record: cardPath.card,
    values: {
      project: targetPath.project,
      board: targetPath.board,
      list: targetPath.list,
      position: await getNextPosition(targetPath.list.id),
    },
    actorUser: currentUser,
    request,
  });

  return {
    message: `Moved "${card.name}" to "${targetPath.list.name}".`,
    item: {
      id: card.id,
      name: card.name,
    },
  };
};

const executeArchiveOrDeleteCard = async ({ action, currentUser, request, index }) => {
  const args = action.args || {};
  const { item: cardCandidate, error } = resolveCard(index, args);

  if (!cardCandidate) {
    throw new Error(error);
  }

  const path = await sails.helpers.cards.getProjectPath({
    id: cardCandidate.id,
  });
  await ensureEditorMembership(path.board.id, currentUser.id);

  const deleted = await sails.helpers.cards.deleteOne.with({
    record: path.card,
    project: path.project,
    board: path.board,
    list: path.list,
    actorUser: currentUser,
    request,
  });

  return {
    message:
      action.type === ACTION_TYPES.ARCHIVE_CARD
        ? `Archived card "${deleted.name}".`
        : `Deleted card "${deleted.name}".`,
    item: {
      id: deleted.id,
      name: deleted.name,
    },
  };
};

const executeCreateList = async ({ action, currentUser, request, index }) => {
  const args = action.args || {};
  const listName = args.listName || args.name;

  if (!listName) {
    throw new Error('create_list requires listName');
  }

  const { item: board, error } = resolveBoard(index, args);

  if (!board) {
    throw new Error(error);
  }

  const path = await sails.helpers.boards.getProjectPath({
    id: board.id,
  });
  await ensureEditorMembership(path.board.id, currentUser.id);

  const list = await sails.helpers.lists.createOne.with({
    project: path.project,
    values: {
      board: path.board,
      position: await getNextListPosition(path.board.id),
      name: listName,
    },
    actorUser: currentUser,
    request,
  });

  return {
    message: `Created list "${list.name}" in "${path.board.name}".`,
    item: {
      id: list.id,
      name: list.name,
    },
  };
};

const executeUpdateList = async ({ action, currentUser, request, index }) => {
  const args = action.args || {};
  const { item: listCandidate, error } = resolveList(index, args);

  if (!listCandidate) {
    throw new Error(error);
  }

  const path = await sails.helpers.lists.getProjectPath({
    id: listCandidate.id,
  });
  await ensureEditorMembership(path.board.id, currentUser.id);

  const changes = _.isPlainObject(args.changes) ? { ...args.changes } : {};

  if (args.newName && !changes.name) {
    changes.name = args.newName;
  }

  if (_.isEmpty(changes)) {
    throw new Error('update_list requires changes');
  }

  const list = await sails.helpers.lists.updateOne.with({
    record: path.list,
    values: changes,
    project: path.project,
    board: path.board,
    actorUser: currentUser,
    request,
  });

  return {
    message: `Updated list "${list.name}".`,
    item: {
      id: list.id,
      name: list.name,
    },
  };
};

const executeDeleteList = async ({ action, currentUser, request, index }) => {
  const args = action.args || {};
  const { item: listCandidate, error } = resolveList(index, args);

  if (!listCandidate) {
    throw new Error(error);
  }

  const path = await sails.helpers.lists.getProjectPath({
    id: listCandidate.id,
  });
  await ensureEditorMembership(path.board.id, currentUser.id);

  const list = await sails.helpers.lists.deleteOne.with({
    record: path.list,
    project: path.project,
    board: path.board,
    actorUser: currentUser,
    request,
  });

  return {
    message: `Deleted list "${list.name}".`,
    item: {
      id: list.id,
      name: list.name,
    },
  };
};

const executeAction = async ({ action, currentUser, request, index, scope }) => {
  switch (action.type) {
    case ACTION_TYPES.CREATE_CARD:
      return executeCreateCard({ action, currentUser, request, index });
    case ACTION_TYPES.UPDATE_CARD:
      return executeUpdateCard({ action, currentUser, request, index, scope });
    case ACTION_TYPES.MOVE_CARD:
      return executeMoveCard({ action, currentUser, request, index });
    case ACTION_TYPES.ARCHIVE_CARD:
    case ACTION_TYPES.DELETE_CARD:
      return executeArchiveOrDeleteCard({ action, currentUser, request, index });
    case ACTION_TYPES.CREATE_LIST:
      return executeCreateList({ action, currentUser, request, index });
    case ACTION_TYPES.UPDATE_LIST:
      return executeUpdateList({ action, currentUser, request, index });
    case ACTION_TYPES.DELETE_LIST:
      return executeDeleteList({ action, currentUser, request, index });
    default:
      throw new Error(`Unsupported action type "${action.type}".`);
  }
};

const executeApprovedActions = async ({ actions, currentUser, request, context }) => {
  const results = [];
  let scope = await scopeService.getAuthorizedScope(currentUser.id, context);
  let index = scopeService.createSearchIndex(scope);

  await actions.reduce(
    (chain, action) =>
      chain.then(async () => {
        try {
          const result = await executeAction({
            action,
            currentUser,
            request,
            index,
            scope,
          });

          results.push({
            actionId: action.id,
            type: action.type,
            success: true,
            ...result,
          });

          scope = await scopeService.getAuthorizedScope(currentUser.id, context);
          index = scopeService.createSearchIndex(scope);
        } catch (error) {
          results.push({
            actionId: action.id,
            type: action.type,
            success: false,
            error: error.message || String(error),
          });
        }
      }),
    Promise.resolve(),
  );

  return results;
};

module.exports = {
  executeApprovedActions,
};
