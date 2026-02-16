import http from './http';

export const fetchArchivedItems = (type, headers) =>
  http.get(`/archives?type=${type}`, undefined, headers);

export default {
  fetchArchivedItems,
};
