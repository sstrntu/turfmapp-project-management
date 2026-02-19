import http from './http';
import socket from './socket';
import root from './root';
import accessTokens from './access-tokens';
import users from './users';
import projects from './projects';
import projectManagers from './project-managers';
import boards from './boards';
import boardMemberships from './board-memberships';
import boardMilestones from './board-milestones';
import labels from './labels';
import lists from './lists';
import cards from './cards';
import cardMemberships from './card-memberships';
import cardLabels from './card-labels';
import tasks from './tasks';
import attachments from './attachments';
import activities from './activities';
import commentActivities from './comment-activities';
import notifications from './notifications';
import archives from './archives';
import ai from './ai';

export { http, socket };

export default {
  ...root,
  ...accessTokens,
  ...users,
  ...projects,
  ...projectManagers,
  ...boards,
  ...boardMemberships,
  ...boardMilestones,
  ...labels,
  ...lists,
  ...cards,
  ...cardMemberships,
  ...cardLabels,
  ...tasks,
  ...attachments,
  ...activities,
  ...commentActivities,
  ...notifications,
  ...archives,
  ...ai,
};
