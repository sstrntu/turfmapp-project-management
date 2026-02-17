import { createSelector } from 'redux-orm';

import orm from '../orm';
import { selectPath } from '../selectors/router';
import entryActions from '../entry-actions';
import { getAnalytics } from '../api/analytics';

function findListByName(lists, name) {
  const lower = name.toLowerCase();
  const exact = lists.find((l) => l.name.toLowerCase() === lower);
  if (exact) return exact;

  return lists.find((l) => l.name.toLowerCase().includes(lower));
}

function findCardByName(cards, name) {
  const lower = name.toLowerCase();
  const exact = cards.find((c) => c.name.toLowerCase() === lower);
  if (exact) return exact;

  return cards.find((c) => c.name.toLowerCase().includes(lower));
}

const selectBoardContext = createSelector(
  orm,
  (state) => selectPath(state).boardId,
  ({ Board }, boardId) => {
    if (!boardId) return null;

    const boardModel = Board.withId(boardId);
    if (!boardModel) return null;

    const lists = boardModel
      .getOrderedListsQuerySet()
      .toModelArray()
      .map((listModel) => ({
        id: listModel.id,
        name: listModel.name,
        position: listModel.position,
        cards: listModel
          .getOrderedCardsQuerySet()
          .toModelArray()
          .map((cardModel) => ({
            id: cardModel.id,
            name: cardModel.name,
            description: cardModel.description,
            position: cardModel.position,
            dueDate: cardModel.dueDate,
            listId: cardModel.listId,
            users: cardModel.users.toRefArray().map((user) => ({
              id: user.id,
              name: user.name,
              username: user.username,
            })),
          })),
      }));

    return {
      boardId,
      boardName: boardModel.name,
      projectId: boardModel.projectId,
      lists,
    };
  },
);

export function getBoardContextString(store) {
  const ctx = selectBoardContext(store.getState());
  if (!ctx) return '';

  const summary = ctx.lists
    .map((list) => {
      const cardNames =
        list.cards.length > 0
          ? list.cards
              .map((c) => `  - ${c.name}${c.dueDate ? ` (due: ${c.dueDate})` : ''}`)
              .join('\n')
          : '  (empty)';
      return `${list.name} (${list.cards.length} cards):\n${cardNames}`;
    })
    .join('\n\n');

  return `You are currently viewing the board "${ctx.boardName}".\n\nHere are all the lists and cards on this board:\n\n${summary}\n\nUse this context to answer questions. When the user refers to cards or lists, match them against these names. You can call tools to create, update, move, or delete cards and lists.`;
}

export default function createVoiceActionHandler(store) {
  const getContext = () => selectBoardContext(store.getState());

  const getAllCards = () => {
    const ctx = getContext();
    if (!ctx) return [];
    return ctx.lists.flatMap((list) =>
      list.cards.map((card) => ({ ...card, listName: list.name })),
    );
  };

  return {
    get_current_board_context: async () => {
      const ctx = getContext();
      if (!ctx) return 'No board is currently open. Please navigate to a board first.';

      const summary = ctx.lists
        .map((list) => {
          const cardNames =
            list.cards.length > 0
              ? list.cards
                  .map((c) => {
                    const assignees =
                      c.users.length > 0
                        ? ` [assigned to: ${c.users.map((u) => u.name).join(', ')}]`
                        : '';
                    const due = c.dueDate ? ` (due: ${c.dueDate})` : '';
                    return `  - ${c.name}${assignees}${due}`;
                  })
                  .join('\n')
              : '  (empty)';
          return `${list.name} (${list.cards.length} cards):\n${cardNames}`;
        })
        .join('\n\n');

      return `Board: ${ctx.boardName}\n\n${summary}`;
    },

    create_card: async ({ listName, name, description }) => {
      const ctx = getContext();
      if (!ctx) return 'No board is currently open.';

      const list = findListByName(ctx.lists, listName);
      if (!list) {
        return `Could not find a list named "${listName}". Available lists: ${ctx.lists.map((l) => l.name).join(', ')}`;
      }

      store.dispatch(
        entryActions.createCard(list.id, {
          name,
          ...(description && { description }),
        }),
      );

      return `Created card "${name}" in ${list.name}.`;
    },

    update_card: async ({ cardName, data }) => {
      const cards = getAllCards();
      const card = findCardByName(cards, cardName);
      if (!card) return `Could not find a card named "${cardName}".`;

      store.dispatch(entryActions.updateCard(card.id, data));

      return `Updated card "${card.name}".`;
    },

    move_card: async ({ cardName, targetListName }) => {
      const ctx = getContext();
      if (!ctx) return 'No board is currently open.';

      const cards = getAllCards();
      const card = findCardByName(cards, cardName);
      if (!card) return `Could not find a card named "${cardName}".`;

      const targetList = findListByName(ctx.lists, targetListName);
      if (!targetList) {
        return `Could not find a list named "${targetListName}". Available lists: ${ctx.lists.map((l) => l.name).join(', ')}`;
      }

      store.dispatch(entryActions.moveCard(card.id, targetList.id, 0));

      return `Moved "${card.name}" to ${targetList.name}.`;
    },

    delete_card: async ({ cardName }) => {
      const cards = getAllCards();
      const card = findCardByName(cards, cardName);
      if (!card) return `Could not find a card named "${cardName}".`;

      store.dispatch(entryActions.deleteCard(card.id));

      return `Deleted card "${card.name}".`;
    },

    create_list: async ({ name }) => {
      const ctx = getContext();
      if (!ctx) return 'No board is currently open.';

      store.dispatch(entryActions.createListInCurrentBoard({ name }));

      return `Created list "${name}".`;
    },

    update_list: async ({ listName, data }) => {
      const ctx = getContext();
      if (!ctx) return 'No board is currently open.';

      const list = findListByName(ctx.lists, listName);
      if (!list) return `Could not find a list named "${listName}".`;

      store.dispatch(entryActions.updateList(list.id, data));

      return `Updated list "${list.name}".`;
    },

    delete_list: async ({ listName }) => {
      const ctx = getContext();
      if (!ctx) return 'No board is currently open.';

      const list = findListByName(ctx.lists, listName);
      if (!list) return `Could not find a list named "${listName}".`;

      store.dispatch(entryActions.deleteList(list.id));

      return `Deleted list "${list.name}".`;
    },

    search_cards: async ({ query }) => {
      const cards = getAllCards();
      const lower = query.toLowerCase();
      const matches = cards.filter(
        (c) =>
          c.name.toLowerCase().includes(lower) ||
          (c.description && c.description.toLowerCase().includes(lower)),
      );

      if (matches.length === 0) return `No cards found matching "${query}".`;

      return matches.map((c) => `"${c.name}" in ${c.listName}`).join(', ');
    },

    get_cards_by_user: async ({ userName }) => {
      const cards = getAllCards();
      const lower = userName.toLowerCase();
      const matches = cards.filter((c) =>
        c.users.some(
          (u) => u.name.toLowerCase().includes(lower) || u.username.toLowerCase().includes(lower),
        ),
      );

      if (matches.length === 0) return `No cards found assigned to "${userName}".`;

      return matches.map((c) => `"${c.name}" in ${c.listName}`).join(', ');
    },

    get_workload_summary: async () => {
      try {
        const data = await getAnalytics();
        const { cards, cardMemberships, users, boards, lists } = data;

        const userCardCount = {};
        cardMemberships.forEach((cm) => {
          userCardCount[cm.userId] = (userCardCount[cm.userId] || 0) + 1;
        });

        const ranked = users
          .map((u) => ({ name: u.name, username: u.username, count: userCardCount[u.id] || 0 }))
          .sort((a, b) => b.count - a.count);

        if (ranked.length === 0) {
          return 'No users with assigned cards found.';
        }

        const now = new Date();
        const overdueCount = cards.filter((c) => c.dueDate && new Date(c.dueDate) < now).length;

        const lines = ranked.map(
          (u, i) => `${i + 1}. ${u.name} (@${u.username}): ${u.count} cards`,
        );

        return `Workload across ${boards.length} boards, ${cards.length} total cards (${overdueCount} overdue), ${lists.length} lists:\n\n${lines.join('\n')}`;
      } catch (e) {
        // eslint-disable-next-line no-console
        console.error('Analytics error:', e);
        return `Failed to fetch analytics data: ${e?.message || String(e)}`;
      }
    },

    get_overdue_cards: async () => {
      try {
        const data = await getAnalytics();
        const { cards, cardMemberships, users, boards, lists } = data;

        const now = new Date();
        const overdue = cards.filter((c) => c.dueDate && new Date(c.dueDate) < now);

        if (overdue.length === 0) {
          return 'No overdue cards found across all boards.';
        }

        const boardMap = {};
        boards.forEach((b) => { boardMap[b.id] = b.name; });
        const listMap = {};
        lists.forEach((l) => { listMap[l.id] = l.name; });
        const userMap = {};
        users.forEach((u) => { userMap[u.id] = u.name; });

        const cardAssignees = {};
        cardMemberships.forEach((cm) => {
          if (!cardAssignees[cm.cardId]) { cardAssignees[cm.cardId] = []; }
          cardAssignees[cm.cardId].push(userMap[cm.userId] || 'Unknown');
        });

        const lines = overdue.map((c) => {
          const assignees = cardAssignees[c.id];
          const assigneeStr = assignees && assignees.length > 0
            ? ` [assigned to: ${assignees.join(', ')}]`
            : '';
          return `- "${c.name}" in ${listMap[c.listId] || 'Unknown list'} (${boardMap[c.boardId] || 'Unknown board'}) due: ${c.dueDate}${assigneeStr}`;
        });

        return `${overdue.length} overdue cards:\n\n${lines.join('\n')}`;
      } catch (e) {
        // eslint-disable-next-line no-console
        console.error('Analytics error:', e);
        return `Failed to fetch analytics data: ${e?.message || String(e)}`;
      }
    },

    get_user_projects: async ({ userName }) => {
      try {
        const data = await getAnalytics();
        const { projects, boards, cards, cardMemberships, users } = data;

        const lower = userName.toLowerCase();
        const user = users.find(
          (u) =>
            u.name.toLowerCase().includes(lower) || u.username.toLowerCase().includes(lower),
        );

        if (!user) {
          return `No user found matching "${userName}". Available users: ${users.map((u) => u.name).join(', ')}`;
        }

        const userCardIds = new Set(
          cardMemberships.filter((cm) => cm.userId === user.id).map((cm) => cm.cardId),
        );
        const userBoardIds = new Set(
          cards.filter((c) => userCardIds.has(c.id)).map((c) => c.boardId),
        );

        const boardMap = {};
        boards.forEach((b) => { boardMap[b.id] = b; });
        const projectBoardsMap = {};
        userBoardIds.forEach((bid) => {
          const board = boardMap[bid];
          if (board) {
            if (!projectBoardsMap[board.projectId]) { projectBoardsMap[board.projectId] = []; }
            projectBoardsMap[board.projectId].push(board.name);
          }
        });

        const projectMap = {};
        projects.forEach((p) => { projectMap[p.id] = p.name; });

        const projectEntries = Object.entries(projectBoardsMap);
        if (projectEntries.length === 0) {
          return `${user.name} (@${user.username}) has no card assignments across any projects.`;
        }

        const lines = projectEntries.map(
          ([pid, boardNames]) =>
            `- ${projectMap[pid] || 'Unknown project'}: ${boardNames.join(', ')}`,
        );

        return `${user.name} (@${user.username}) is involved in ${projectEntries.length} projects with ${userCardIds.size} cards:\n\n${lines.join('\n')}`;
      } catch (e) {
        // eslint-disable-next-line no-console
        console.error('Analytics error:', e);
        return `Failed to fetch analytics data: ${e?.message || String(e)}`;
      }
    },

    get_project_summary: async ({ projectName }) => {
      try {
        const data = await getAnalytics();
        const { projects, boards, lists, cards, cardMemberships, users } = data;

        const lower = projectName.toLowerCase();
        const project = projects.find((p) => p.name.toLowerCase().includes(lower));

        if (!project) {
          return `No project found matching "${projectName}". Available projects: ${projects.map((p) => p.name).join(', ')}`;
        }

        const projectBoards = boards.filter((b) => b.projectId === project.id);
        const boardIds = new Set(projectBoards.map((b) => b.id));
        const projectLists = lists.filter((l) => boardIds.has(l.boardId));
        const projectCards = cards.filter((c) => boardIds.has(c.boardId));

        const now = new Date();
        const overdueCount = projectCards.filter(
          (c) => c.dueDate && new Date(c.dueDate) < now,
        ).length;

        const listMap = {};
        projectLists.forEach((l) => { listMap[l.id] = l; });
        const boardMap = {};
        projectBoards.forEach((b) => { boardMap[b.id] = b.name; });

        const boardSummaries = projectBoards.map((board) => {
          const bLists = projectLists.filter((l) => l.boardId === board.id);
          const listLines = bLists.map((l) => {
            const listCards = projectCards.filter((c) => c.listId === l.id);
            return `    - ${l.name}: ${listCards.length} cards`;
          });
          const bCards = projectCards.filter((c) => c.boardId === board.id);
          return `  ${board.name} (${bCards.length} cards):\n${listLines.join('\n')}`;
        });

        return `Project: ${project.name}\n${projectBoards.length} boards, ${projectCards.length} total cards (${overdueCount} overdue)\n\n${boardSummaries.join('\n\n')}`;
      } catch (e) {
        // eslint-disable-next-line no-console
        console.error('Analytics error:', e);
        return `Failed to fetch analytics data: ${e?.message || String(e)}`;
      }
    },

    get_all_projects_overview: async () => {
      try {
        const data = await getAnalytics();
        const { projects, boards, cards } = data;

        if (projects.length === 0) {
          return 'No projects found.';
        }

        const now = new Date();

        const lines = projects.map((project) => {
          const projectBoards = boards.filter((b) => b.projectId === project.id);
          const boardIds = new Set(projectBoards.map((b) => b.id));
          const projectCards = cards.filter((c) => boardIds.has(c.boardId));
          const overdueCount = projectCards.filter(
            (c) => c.dueDate && new Date(c.dueDate) < now,
          ).length;

          const overdueStr = overdueCount > 0 ? `, ${overdueCount} overdue` : '';
          return `- ${project.name}: ${projectBoards.length} boards, ${projectCards.length} cards${overdueStr}`;
        });

        return `${projects.length} projects:\n\n${lines.join('\n')}`;
      } catch (e) {
        // eslint-disable-next-line no-console
        console.error('Analytics error:', e);
        return `Failed to fetch analytics data: ${e?.message || String(e)}`;
      }
    },
  };
}
