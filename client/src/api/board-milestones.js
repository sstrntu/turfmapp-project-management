import socket from './socket';

const createBoardMilestone = (boardId, data, headers) =>
  socket.post(`/boards/${boardId}/milestones`, data, headers);

const updateBoardMilestone = (id, data, headers) =>
  socket.patch(`/board-milestones/${id}`, data, headers);

const deleteBoardMilestone = (id, headers) =>
  socket.delete(`/board-milestones/${id}`, undefined, headers);

export default {
  createBoardMilestone,
  updateBoardMilestone,
  deleteBoardMilestone,
};
