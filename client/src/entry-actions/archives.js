import EntryActionTypes from '../constants/EntryActionTypes';

const closeArchivedItemsModal = () => ({
  type: EntryActionTypes.MODAL_CLOSE,
  payload: {},
});

const fetchArchivedItems = () => ({
  type: EntryActionTypes.FETCH_ARCHIVED_ITEMS,
  payload: {},
});

const restoreCard = (id, listId) => ({
  type: EntryActionTypes.CARD_RESTORE,
  payload: {
    id,
    listId,
  },
});

const restoreProject = (id) => ({
  type: EntryActionTypes.PROJECT_RESTORE,
  payload: {
    id,
  },
});

const permanentDeleteCard = (id) => ({
  type: EntryActionTypes.CARD_PERMANENT_DELETE,
  payload: {
    id,
  },
});

const permanentDeleteProject = (id) => ({
  type: EntryActionTypes.PROJECT_PERMANENT_DELETE,
  payload: {
    id,
  },
});

export default {
  closeArchivedItemsModal,
  fetchArchivedItems,
  restoreCard,
  restoreProject,
  permanentDeleteCard,
  permanentDeleteProject,
};
