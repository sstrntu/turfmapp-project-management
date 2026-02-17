import { createSelector } from 'redux-orm';

import orm from '../orm';
import { selectPath } from '../selectors/router';
import entryActions from '../entry-actions';

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
  };
}
