import ActionTypes from '../constants/ActionTypes';

const initialState = {
  items: [],
  isFetching: false,
  error: null,
};

// eslint-disable-next-line default-param-last
export default (state = initialState, { type, payload }) => {
  switch (type) {
    case ActionTypes.FETCH_ARCHIVED_ITEMS:
      return {
        ...state,
        isFetching: true,
        error: null,
      };
    case `${ActionTypes.FETCH_ARCHIVED_ITEMS}__SUCCESS`:
      return {
        ...state,
        items: payload.items || [],
        isFetching: false,
      };
    case `${ActionTypes.FETCH_ARCHIVED_ITEMS}__FAILURE`:
      return {
        ...state,
        isFetching: false,
        error: payload.error,
      };
    default:
      return state;
  }
};
