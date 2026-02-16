import { call, put, all } from 'redux-saga/effects';

import request from '../request';
import api from '../../../api';
import actions from '../../../actions';

function* fetchArchivedItemsByType(type) {
  let response;
  try {
    response = yield call(request, api.fetchArchivedItems, type);
  } catch (error) {
    console.error(`Failed to fetch archived ${type}s:`, error);
    return [];
  }

  console.log(`Raw response from API for ${type}:`, response);

  // Map backend response to frontend format
  const items = (response.items || []).map((item) => ({
    id: item.originalId,
    archiveId: item.archiveId,
    name: item.name,
    type,
    createdAt: item.archivedAt,
    boardCount: item.originalRecord?.boards?.length || 0,
    listName: item.originalRecord?.list?.name,
  }));

  console.log(`Mapped ${type} items:`, items);
  return items;
}

export function* fetchArchivedItems() {
  // Fetch both cards and projects in parallel
  const [cards, projects] = yield all([
    call(fetchArchivedItemsByType, 'card'),
    call(fetchArchivedItemsByType, 'project'),
  ]);

  const allItems = [...cards, ...projects];
  console.log('All archived items combined:', allItems);
  yield put(actions.fetchArchivedItems.success(allItems));
}

export default {
  fetchArchivedItems,
};
