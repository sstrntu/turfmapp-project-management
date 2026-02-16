export const selectArchivedCards = ({ archives: { items = [] } }) => {
  return items.filter((item) => item && item.type === 'card');
};

export const selectArchivedProjects = ({ archives: { items = [] } }) => {
  return items.filter((item) => item && item.type === 'project');
};

export default {
  selectArchivedCards,
  selectArchivedProjects,
};
