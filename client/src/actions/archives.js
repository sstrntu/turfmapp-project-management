import ActionTypes from '../constants/ActionTypes';

const createAction = (type) => {
  const action = (payload) => ({
    type,
    payload,
  });

  action.success = (items) => ({
    type: `${type}__SUCCESS`,
    payload: {
      items,
    },
  });

  action.failure = (error) => ({
    type: `${type}__FAILURE`,
    payload: {
      error,
    },
  });

  return action;
};

export const fetchArchivedItems = createAction(ActionTypes.FETCH_ARCHIVED_ITEMS);

export default {
  fetchArchivedItems,
};
