import { createSelector } from 'redux-orm';

import orm from '../orm';

export const selectCurrentUserId = ({ auth: { userId } }) => userId;

export const selectUsers = createSelector(orm, ({ User }) =>
  User.getOrderedUndeletedQuerySet().toRefArray(),
);

export const selectUsersExceptCurrent = createSelector(
  orm,
  (state) => selectCurrentUserId(state),
  ({ User }, id) =>
    User.getOrderedUndeletedQuerySet()
      .exclude({
        id,
      })
      .toRefArray(),
);

export const selectCurrentUser = createSelector(
  orm,
  (state) => selectCurrentUserId(state),
  ({ User }, id) => {
    if (!id) {
      return id;
    }

    const userModel = User.withId(id);

    if (!userModel) {
      return userModel;
    }

    return userModel.ref;
  },
);

export const selectProjectsForCurrentUser = createSelector(
  orm,
  (state) => selectCurrentUserId(state),
  ({ User }, id) => {
    if (!id) {
      return id;
    }

    const userModel = User.withId(id);

    if (!userModel) {
      return userModel;
    }

    return userModel.getOrderedAvailableProjectsModelArray().map((projectModel) => {
      const boardsModels = projectModel.getOrderedBoardsModelArrayAvailableForUser(userModel.id);

      let notificationsTotal = 0;
      boardsModels.forEach((boardModel) => {
        boardModel.cards.toModelArray().forEach((cardModel) => {
          notificationsTotal += cardModel.getUnreadNotificationsQuerySet().count();
        });
      });

      return {
        ...projectModel.ref,
        notificationsTotal,
        firstBoardId: boardsModels[0] && boardsModels[0].id,
      };
    });
  },
);

export const selectProjectsToListsForCurrentUser = createSelector(
  orm,
  (state) => selectCurrentUserId(state),
  ({ User }, id) => {
    if (!id) {
      return id;
    }

    const userModel = User.withId(id);

    if (!userModel) {
      return userModel;
    }

    return userModel.getOrderedAvailableProjectsModelArray().map((projectModel) => ({
      ...projectModel.ref,
      boards: projectModel.getOrderedBoardsModelArrayForUser(id).map((boardModel) => ({
        ...boardModel.ref,
        lists: boardModel.getOrderedListsQuerySet().toRefArray(),
      })),
    }));
  },
);

export const selectDueCardsForCurrentUser = createSelector(
  orm,
  (state) => selectCurrentUserId(state),
  ({ User }, id) => {
    if (!id) {
      return [];
    }

    const userModel = User.withId(id);

    if (!userModel) {
      return [];
    }

    const dueCards = [];

    userModel.getOrderedAvailableProjectsModelArray().forEach((projectModel) => {
      projectModel
        .getOrderedBoardsModelArrayAvailableForUser(userModel.id)
        .forEach((boardModel) => {
          boardModel.cards.toModelArray().forEach((cardModel) => {
            if (!cardModel.dueDate) {
              return;
            }

            dueCards.push({
              ...cardModel.ref,
              projectId: projectModel.id,
              projectName: projectModel.name,
              boardId: boardModel.id,
              boardName: boardModel.name,
            });
          });
        });
    });

    return dueCards;
  },
);

export const selectMilestonesForCurrentUser = createSelector(
  orm,
  (state) => selectCurrentUserId(state),
  ({ User }, id) => {
    if (!id) {
      return [];
    }

    const userModel = User.withId(id);

    if (!userModel) {
      return [];
    }

    const milestones = [];

    userModel.getOrderedAvailableProjectsModelArray().forEach((projectModel) => {
      projectModel
        .getOrderedBoardsModelArrayAvailableForUser(userModel.id)
        .forEach((boardModel) => {
          boardModel.milestones.toModelArray().forEach((milestoneModel) => {
            milestones.push({
              ...milestoneModel.ref,
              boardId: boardModel.id,
              boardName: boardModel.name,
              projectId: projectModel.id,
              projectName: projectModel.name,
            });
          });
        });
    });

    return milestones;
  },
);

export const selectNotificationsForCurrentUser = createSelector(
  orm,
  (state) => selectCurrentUserId(state),
  ({ User }, id) => {
    if (!id) {
      return id;
    }

    const userModel = User.withId(id);

    if (!userModel) {
      return userModel;
    }

    return userModel
      .getOrderedUnreadNotificationsQuerySet()
      .toModelArray()
      .map((notificationModel) => ({
        ...notificationModel.ref,
        activity: notificationModel.activity && {
          ...notificationModel.activity.ref,
          user: notificationModel.activity.user.ref,
        },
        card: notificationModel.card && notificationModel.card.ref,
      }));
  },
);

export default {
  selectCurrentUserId,
  selectUsers,
  selectUsersExceptCurrent,
  selectCurrentUser,
  selectProjectsForCurrentUser,
  selectProjectsToListsForCurrentUser,
  selectDueCardsForCurrentUser,
  selectMilestonesForCurrentUser,
  selectNotificationsForCurrentUser,
};
