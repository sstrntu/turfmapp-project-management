const DAY_MS = 24 * 60 * 60 * 1000;
const DEFAULT_WINDOW_DAYS = 30;
const MAX_WINDOW_DAYS = 365;
const STALE_DAYS = 10;
const BLOCKED_KEYWORDS = ['blocked', 'on hold', 'waiting'];
const DUE_SOON_DAYS = 7;
const DUE_HORIZON_DAYS = [7, 14, 30];
const CONCENTRATION_RISK_THRESHOLD = 0.35;
const RISK_QUEUE_LIMIT = 200;

const Errors = {
  FORBIDDEN: {
    forbidden: 'Only admins and project owners can view analytics summary',
  },
  PROJECT_NOT_FOUND: {
    projectNotFound: 'Project not found',
  },
};

const normalizeText = (value) => (value || '').toString().trim().toLowerCase();

const hasBlockedKeyword = (value) => {
  const normalized = normalizeText(value);
  return normalized !== '' && BLOCKED_KEYWORDS.some((keyword) => normalized.includes(keyword));
};

const ratio = (numerator, denominator) => (denominator > 0 ? numerator / denominator : 0);

const getDailyWindow = (windowDays, now) => {
  const endAt = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());
  const startAt = endAt - (windowDays - 1) * DAY_MS;
  const dates = [];

  for (let timestamp = startAt; timestamp <= endAt; timestamp += DAY_MS) {
    dates.push(new Date(timestamp).toISOString().slice(0, 10));
  }

  return {
    startAt,
    endAt,
    dates,
  };
};

const addDateCount = (bucketByDate, value, startAt, endAt) => {
  if (!value) {
    return;
  }

  const dateValue = new Date(value);
  if (Number.isNaN(dateValue.getTime())) {
    return;
  }

  const dayTimestamp = Date.UTC(
    dateValue.getUTCFullYear(),
    dateValue.getUTCMonth(),
    dateValue.getUTCDate(),
  );

  if (dayTimestamp < startAt || dayTimestamp > endAt) {
    return;
  }

  const dayKey = new Date(dayTimestamp).toISOString().slice(0, 10);
  const nextBucketByDate = bucketByDate;
  if (!_.isUndefined(nextBucketByDate[dayKey])) {
    nextBucketByDate[dayKey] += 1;
  }
};

const createProjectBucket = (projectId, projectName, boardCount = 0) => ({
  projectId,
  projectName,
  boardCount,
  totalCards: 0,
  cardsWithDueDate: 0,
  overdueCards: 0,
  dueSoon7d: 0,
  blockedCards: 0,
  staleCards: 0,
  unassignedCards: 0,
  totalTasks: 0,
  completedTasks: 0,
  riskScore: 0,
});

const createBoardBucket = (boardId, boardName, projectId, projectName) => ({
  boardId,
  boardName,
  projectId,
  projectName,
  totalCards: 0,
  cardsWithDueDate: 0,
  overdueCards: 0,
  dueSoon7d: 0,
  blockedCards: 0,
  staleCards: 0,
  unassignedCards: 0,
  totalTasks: 0,
  completedTasks: 0,
  riskScore: 0,
});

const createUserBucket = (userId, name, username) => ({
  userId,
  name: name || 'Unknown',
  username: username || '',
  assignedCards: 0,
  assignedOverdue: 0,
  assignedDueSoon7d: 0,
  assignedBlocked: 0,
  assignedStale: 0,
});

const addCardToBucket = (
  bucket,
  {
    hasDueDate,
    isOverdue,
    isDueSoon,
    isBlocked,
    isStale,
    isUnassigned,
    taskTotal,
    taskCompleted,
    riskScore,
  },
) => {
  const nextBucket = bucket;

  nextBucket.totalCards += 1;
  nextBucket.totalTasks += taskTotal;
  nextBucket.completedTasks += taskCompleted;
  nextBucket.riskScore += riskScore;

  if (hasDueDate) {
    nextBucket.cardsWithDueDate += 1;
  }

  if (isOverdue) {
    nextBucket.overdueCards += 1;
  }

  if (isDueSoon) {
    nextBucket.dueSoon7d += 1;
  }

  if (isBlocked) {
    nextBucket.blockedCards += 1;
  }

  if (isStale) {
    nextBucket.staleCards += 1;
  }

  if (isUnassigned) {
    nextBucket.unassignedCards += 1;
  }
};

const withRates = (bucket) => ({
  ...bucket,
  overdueRate: ratio(bucket.overdueCards, bucket.cardsWithDueDate),
  taskCompletionRate: ratio(bucket.completedTasks, bucket.totalTasks),
});

module.exports = {
  inputs: {
    windowDays: {
      type: 'number',
      min: 1,
      max: MAX_WINDOW_DAYS,
      defaultsTo: DEFAULT_WINDOW_DAYS,
    },
    projectId: {
      type: 'string',
      regex: /^[0-9]+$/,
    },
  },

  exits: {
    forbidden: {
      responseType: 'forbidden',
    },
    projectNotFound: {
      responseType: 'notFound',
    },
  },

  async fn(inputs) {
    const { currentUser } = this.req;
    const now = new Date();
    const windowDays = inputs.windowDays || DEFAULT_WINDOW_DAYS;

    let scopedProjectIds = [];

    if (currentUser.isAdmin) {
      if (inputs.projectId) {
        const project = await Project.findOne(inputs.projectId);
        if (!project) {
          throw Errors.PROJECT_NOT_FOUND;
        }

        scopedProjectIds = [project.id];
      } else {
        const allProjects = await sails.helpers.projects.getMany({});
        scopedProjectIds = sails.helpers.utils.mapRecords(allProjects);
      }
    } else {
      const managerProjectIds = await sails.helpers.users.getManagerProjectIds(currentUser.id);

      if (managerProjectIds.length === 0) {
        throw Errors.FORBIDDEN;
      }

      if (inputs.projectId) {
        if (!managerProjectIds.includes(inputs.projectId)) {
          throw Errors.FORBIDDEN;
        }

        scopedProjectIds = [inputs.projectId];
      } else {
        scopedProjectIds = managerProjectIds;
      }
    }

    scopedProjectIds = [...new Set(scopedProjectIds)];

    const projects =
      scopedProjectIds.length > 0 ? await sails.helpers.projects.getMany(scopedProjectIds) : [];
    const projectIds = sails.helpers.utils.mapRecords(projects);
    const boards = projectIds.length > 0 ? await sails.helpers.projects.getBoards(projectIds) : [];
    const boardIds = sails.helpers.utils.mapRecords(boards);

    const [lists, labels, cards] =
      boardIds.length > 0
        ? await Promise.all([
            sails.helpers.boards.getLists(boardIds),
            sails.helpers.boards.getLabels(boardIds),
            sails.helpers.boards.getCards(boardIds),
          ])
        : [[], [], []];

    const cardIds = sails.helpers.utils.mapRecords(cards);
    const [cardMembershipsResult, tasks, cardLabels, boardMemberships, projectManagers] =
      await Promise.all([
        cardIds.length > 0 ? sails.helpers.cards.getCardMemberships(cardIds) : [],
        cardIds.length > 0 ? sails.helpers.cards.getTasks(cardIds) : [],
        cardIds.length > 0 ? sails.helpers.cards.getCardLabels(cardIds) : [],
        boardIds.length > 0 ? sails.helpers.boards.getBoardMemberships(boardIds) : [],
        projectIds.length > 0 ? sails.helpers.projects.getProjectManagers(projectIds) : [],
      ]);

    const memberUserIds = sails.helpers.utils.mapRecords(cardMembershipsResult, 'userId', true);
    const boardMemberUserIds = sails.helpers.utils.mapRecords(boardMemberships, 'userId', true);
    const projectManagerUserIds = sails.helpers.utils.mapRecords(projectManagers, 'userId', true);
    const scopedUserIds = [
      ...new Set([...memberUserIds, ...boardMemberUserIds, ...projectManagerUserIds]),
    ];
    const users = scopedUserIds.length > 0 ? await sails.helpers.users.getMany(scopedUserIds) : [];

    const projectById = new Map(projects.map((project) => [project.id, project]));
    const boardById = new Map(boards.map((board) => [board.id, board]));
    const listById = new Map(lists.map((list) => [list.id, list]));
    const labelById = new Map(labels.map((label) => [label.id, label]));
    const userById = new Map(users.map((user) => [user.id, user]));

    const boardCountByProjectId = {};
    boards.forEach((board) => {
      boardCountByProjectId[board.projectId] = (boardCountByProjectId[board.projectId] || 0) + 1;
    });

    const assigneeIdsByCardId = new Map();
    cardMembershipsResult.forEach(({ cardId, userId }) => {
      let userIds = assigneeIdsByCardId.get(cardId);
      if (!userIds) {
        userIds = new Set();
        assigneeIdsByCardId.set(cardId, userIds);
      }

      userIds.add(userId);
    });

    const labelNamesByCardId = new Map();
    cardLabels.forEach(({ cardId, labelId }) => {
      const label = labelById.get(labelId);
      if (!label || !label.name) {
        return;
      }

      const labelNames = labelNamesByCardId.get(cardId) || [];
      labelNames.push(label.name);
      labelNamesByCardId.set(cardId, labelNames);
    });

    const taskStatsByCardId = new Map();
    tasks.forEach((task) => {
      const stats = taskStatsByCardId.get(task.cardId) || {
        total: 0,
        completed: 0,
      };

      stats.total += 1;
      if (task.isCompleted) {
        stats.completed += 1;
      }

      taskStatsByCardId.set(task.cardId, stats);
    });

    const { startAt, endAt, dates } = getDailyWindow(windowDays, now);
    const cardsCreatedByDate = {};
    const tasksCompletedByDate = {};

    dates.forEach((dateKey) => {
      cardsCreatedByDate[dateKey] = 0;
      tasksCompletedByDate[dateKey] = 0;
    });

    cards.forEach((card) => addDateCount(cardsCreatedByDate, card.createdAt, startAt, endAt));
    tasks
      .filter((task) => task.isCompleted)
      .forEach((task) => addDateCount(tasksCompletedByDate, task.updatedAt, startAt, endAt));

    const summary = {
      totalActiveCards: 0,
      cardsWithDueDate: 0,
      overdueCards: 0,
      dueSoon7d: 0,
      dueIn14d: 0,
      dueIn30d: 0,
      blockedCards: 0,
      staleCards: 0,
      unassignedCards: 0,
      totalTasks: 0,
      completedTasks: 0,
      skillTaggedCards: 0,
      uncoveredSkillTaggedCards: 0,
      skillCoverageRate: 0,
      skillsAtRisk: 0,
      overdueRate: 0,
      taskCompletionRate: 0,
    };

    const projectBuckets = new Map();
    projects.forEach((project) => {
      projectBuckets.set(
        project.id,
        createProjectBucket(project.id, project.name, boardCountByProjectId[project.id] || 0),
      );
    });

    const boardBuckets = new Map();
    boards.forEach((board) => {
      const project = projectById.get(board.projectId);
      boardBuckets.set(
        board.id,
        createBoardBucket(
          board.id,
          board.name,
          board.projectId,
          project ? project.name : 'Unknown project',
        ),
      );
    });

    const userBuckets = new Map();
    users.forEach((user) => {
      userBuckets.set(user.id, createUserBucket(user.id, user.name, user.username));
    });

    const skillsByUserId = new Map();
    const skillOwnersBySkill = new Map();
    users.forEach((user) => {
      const normalizedSkills = _.isArray(user.skills)
        ? user.skills.map(normalizeText).filter((skill) => skill !== '')
        : [];
      const userSkills = new Set(normalizedSkills);

      skillsByUserId.set(user.id, userSkills);

      userSkills.forEach((skill) => {
        if (!skillOwnersBySkill.has(skill)) {
          skillOwnersBySkill.set(skill, new Set());
        }

        skillOwnersBySkill.get(skill).add(user.id);
      });
    });

    const dueSoonCutoff = new Date(now.getTime() + DUE_SOON_DAYS * DAY_MS);
    const due14Cutoff = new Date(now.getTime() + 14 * DAY_MS);
    const due30Cutoff = new Date(now.getTime() + 30 * DAY_MS);
    const staleCutoff = new Date(now.getTime() - STALE_DAYS * DAY_MS);
    const windowEndExclusive = endAt + DAY_MS;
    const riskQueue = [];
    const projectDemandById = new Map();
    const userDemandById = new Map();
    const skillDemandBySkill = new Map();
    const skillCoverageByClientId = new Map();
    const skillCoverageByProjectId = new Map();
    const skillAnalyticsByProjectId = new Map();
    const ensureSkillDemand = (skill) => {
      if (!skillDemandBySkill.has(skill)) {
        skillDemandBySkill.set(skill, {
          skill,
          demandCards: 0,
          activeNeedCards: 0,
          coveredCards: 0,
          uncoveredCards: 0,
          coveredActiveNeedCards: 0,
          uncoveredActiveNeedCards: 0,
          skilledUsers: 0,
          assignedUserIds: new Set(),
          completedInWindow: 0,
          dueIn7d: 0,
          dueIn14d: 0,
          dueIn30d: 0,
        });
      }

      const skillDemand = skillDemandBySkill.get(skill);
      skillDemand.skilledUsers = skillOwnersBySkill.has(skill)
        ? skillOwnersBySkill.get(skill).size
        : 0;

      return skillDemand;
    };

    Array.from(skillOwnersBySkill.keys()).forEach((skill) => ensureSkillDemand(skill));

    projects.forEach((project) => {
      projectDemandById.set(project.id, {
        projectId: project.id,
        projectName: project.name,
        dueIn7d: 0,
        dueIn14d: 0,
        dueIn30d: 0,
      });

      skillCoverageByClientId.set(project.id, {
        clientId: project.id,
        clientName: project.name,
        skillNeedCards: 0,
        coveredSkillNeedCards: 0,
        uncoveredSkillNeedCards: 0,
      });
    });

    users.forEach((user) => {
      userDemandById.set(user.id, {
        userId: user.id,
        name: user.name,
        username: user.username,
        dueIn7d: 0,
        dueIn14d: 0,
        dueIn30d: 0,
      });
    });

    boards.forEach((board) => {
      const project = projectById.get(board.projectId);
      skillCoverageByProjectId.set(board.id, {
        projectId: board.id,
        projectName: board.name,
        clientId: board.projectId,
        clientName: project ? project.name : 'Unknown client',
        skillNeedCards: 0,
        coveredSkillNeedCards: 0,
        uncoveredSkillNeedCards: 0,
      });

      skillAnalyticsByProjectId.set(board.id, {
        projectId: board.id,
        projectName: board.name,
        clientId: board.projectId,
        clientName: project ? project.name : 'Unknown client',
        cardsWithSkillNeed: 0,
        coveredCards: 0,
        uncoveredCards: 0,
        skillsNeededSet: new Set(),
        skillDetailsBySkill: new Map(),
      });
    });

    cards.forEach((card) => {
      const board = boardById.get(card.boardId);
      const project = board && projectById.get(board.projectId);
      const list = listById.get(card.listId);
      const taskStats = taskStatsByCardId.get(card.id) || { total: 0, completed: 0 };
      const assigneeIds = Array.from(assigneeIdsByCardId.get(card.id) || []);
      const assignees = assigneeIds.map((userId) => {
        const user = userById.get(userId);
        return {
          id: userId,
          name: user ? user.name : 'Unknown',
          username: user ? user.username : '',
        };
      });
      const projectSkillAnalytics = board ? skillAnalyticsByProjectId.get(board.id) : null;
      const labelNames = labelNamesByCardId.get(card.id) || [];
      const requiredSkills = new Set();
      labelNames.forEach((labelName) => {
        const normalizedLabel = normalizeText(labelName);

        if (!normalizedLabel) {
          return;
        }

        if (normalizedLabel.startsWith('skill:')) {
          const explicitSkill = normalizeText(normalizedLabel.slice(6));
          if (explicitSkill) {
            requiredSkills.add(explicitSkill);
          }
          return;
        }

        if (normalizedLabel.startsWith('skill-')) {
          const explicitSkill = normalizeText(normalizedLabel.slice(6));
          if (explicitSkill) {
            requiredSkills.add(explicitSkill);
          }
          return;
        }

        if (skillOwnersBySkill.has(normalizedLabel)) {
          requiredSkills.add(normalizedLabel);
        }
      });

      if (requiredSkills.size === 0 && assigneeIds.length > 0) {
        assigneeIds.forEach((userId) => {
          const userSkills = skillsByUserId.get(userId);

          if (!userSkills || userSkills.size === 0) {
            return;
          }

          userSkills.forEach((skill) => requiredSkills.add(skill));
        });
      }
      const isDueDateCompleted = card.isDueDateCompleted === true;

      let hasDueDate = false;
      let isOverdue = false;
      let isDueSoon = false;
      let dueDateValue = null;

      if (card.dueDate) {
        const dueDate = new Date(card.dueDate);
        if (!Number.isNaN(dueDate.getTime())) {
          hasDueDate = true;
          dueDateValue = dueDate;
          isOverdue = !isDueDateCompleted && dueDate < now;
          isDueSoon = !isDueDateCompleted && dueDate >= now && dueDate < dueSoonCutoff;
        }
      }

      let isStale = false;
      if (card.updatedAt && !isDueDateCompleted) {
        const updatedAt = new Date(card.updatedAt);
        isStale = !Number.isNaN(updatedAt.getTime()) && updatedAt < staleCutoff;
      }

      const isBlockedByList = hasBlockedKeyword(list && list.name);
      const isBlockedByLabel = labelNames.some((labelName) => hasBlockedKeyword(labelName));
      const isBlocked = isBlockedByList || isBlockedByLabel;
      const isUnassigned = assigneeIds.length === 0;
      const riskScore =
        (isOverdue ? 5 : 0) + (isBlocked ? 3 : 0) + (isStale ? 2 : 0) + (isUnassigned ? 1 : 0);
      let cardSkillCovered = true;

      if (requiredSkills.size > 0) {
        summary.skillTaggedCards += 1;

        requiredSkills.forEach((skill) => {
          const skillDemand = ensureSkillDemand(skill);
          skillDemand.demandCards += 1;
          assigneeIds.forEach((userId) => skillDemand.assignedUserIds.add(userId));

          if (!isDueDateCompleted) {
            skillDemand.activeNeedCards += 1;
          }

          const skilledAssigneeIds = assigneeIds.filter((userId) => {
            const userSkills = skillsByUserId.get(userId);
            return userSkills && userSkills.has(skill);
          });
          const skillCovered = skilledAssigneeIds.length > 0;

          if (skillCovered) {
            skillDemand.coveredCards += 1;
            if (!isDueDateCompleted) {
              skillDemand.coveredActiveNeedCards += 1;
            }
          } else {
            skillDemand.uncoveredCards += 1;
            if (!isDueDateCompleted) {
              skillDemand.uncoveredActiveNeedCards += 1;
            }
            cardSkillCovered = false;
          }

          if (projectSkillAnalytics && !isDueDateCompleted) {
            if (!projectSkillAnalytics.skillDetailsBySkill.has(skill)) {
              projectSkillAnalytics.skillDetailsBySkill.set(skill, {
                skill,
                neededCards: 0,
                coveredCards: 0,
                uncoveredCards: 0,
                dueIn30d: 0,
                assignedSkilledUserIds: new Set(),
              });
            }

            const projectSkillDetail = projectSkillAnalytics.skillDetailsBySkill.get(skill);
            projectSkillDetail.neededCards += 1;
            projectSkillAnalytics.skillsNeededSet.add(skill);
            skilledAssigneeIds.forEach((userId) =>
              projectSkillDetail.assignedSkilledUserIds.add(userId),
            );

            if (skillCovered) {
              projectSkillDetail.coveredCards += 1;
            } else {
              projectSkillDetail.uncoveredCards += 1;
            }
          }

          if (isDueDateCompleted && card.updatedAt) {
            const updatedAt = new Date(card.updatedAt);
            if (
              !Number.isNaN(updatedAt.getTime()) &&
              updatedAt.getTime() >= startAt &&
              updatedAt.getTime() < windowEndExclusive
            ) {
              skillDemand.completedInWindow += 1;
            }
          }
        });

        if (!cardSkillCovered) {
          summary.uncoveredSkillTaggedCards += 1;
        }

        if (!isDueDateCompleted) {
          if (projectSkillAnalytics) {
            projectSkillAnalytics.cardsWithSkillNeed += 1;

            if (cardSkillCovered) {
              projectSkillAnalytics.coveredCards += 1;
            } else {
              projectSkillAnalytics.uncoveredCards += 1;
            }
          }

          if (project && skillCoverageByClientId.has(project.id)) {
            const clientSkillCoverage = skillCoverageByClientId.get(project.id);
            clientSkillCoverage.skillNeedCards += 1;

            if (cardSkillCovered) {
              clientSkillCoverage.coveredSkillNeedCards += 1;
            } else {
              clientSkillCoverage.uncoveredSkillNeedCards += 1;
            }
          }

          if (board && skillCoverageByProjectId.has(board.id)) {
            const projectSkillCoverage = skillCoverageByProjectId.get(board.id);
            projectSkillCoverage.skillNeedCards += 1;

            if (cardSkillCovered) {
              projectSkillCoverage.coveredSkillNeedCards += 1;
            } else {
              projectSkillCoverage.uncoveredSkillNeedCards += 1;
            }
          }
        }
      }

      summary.totalActiveCards += 1;

      addCardToBucket(summary, {
        hasDueDate,
        isOverdue,
        isDueSoon,
        isBlocked,
        isStale,
        isUnassigned,
        taskTotal: taskStats.total,
        taskCompleted: taskStats.completed,
        riskScore,
      });

      if (project && projectBuckets.has(project.id)) {
        addCardToBucket(projectBuckets.get(project.id), {
          hasDueDate,
          isOverdue,
          isDueSoon,
          isBlocked,
          isStale,
          isUnassigned,
          taskTotal: taskStats.total,
          taskCompleted: taskStats.completed,
          riskScore,
        });
      }

      if (board && boardBuckets.has(board.id)) {
        addCardToBucket(boardBuckets.get(board.id), {
          hasDueDate,
          isOverdue,
          isDueSoon,
          isBlocked,
          isStale,
          isUnassigned,
          taskTotal: taskStats.total,
          taskCompleted: taskStats.completed,
          riskScore,
        });
      }

      assigneeIds.forEach((userId) => {
        if (!userBuckets.has(userId)) {
          const user = userById.get(userId);
          userBuckets.set(
            userId,
            createUserBucket(userId, user ? user.name : 'Unknown', user ? user.username : ''),
          );
        }

        const userBucket = userBuckets.get(userId);
        userBucket.assignedCards += 1;
        if (isOverdue) {
          userBucket.assignedOverdue += 1;
        }
        if (isDueSoon) {
          userBucket.assignedDueSoon7d += 1;
        }
        if (isBlocked) {
          userBucket.assignedBlocked += 1;
        }
        if (isStale) {
          userBucket.assignedStale += 1;
        }
      });

      if (riskScore > 0) {
        riskQueue.push({
          cardId: card.id,
          cardName: card.name,
          projectId: project ? project.id : null,
          projectName: project ? project.name : 'Unknown project',
          boardId: board ? board.id : card.boardId,
          boardName: board ? board.name : 'Unknown board',
          listId: list ? list.id : card.listId,
          listName: list ? list.name : 'Unknown list',
          dueDate: card.dueDate || null,
          isDueDateCompleted: card.isDueDateCompleted,
          isOverdue,
          isBlocked,
          isStale,
          isUnassigned,
          assignees,
          riskScore,
        });
      }

      if (
        dueDateValue &&
        !isDueDateCompleted &&
        dueDateValue >= now &&
        dueDateValue < due30Cutoff
      ) {
        summary.dueIn30d += 1;
        if (dueDateValue < due14Cutoff) {
          summary.dueIn14d += 1;
        }

        if (project && projectDemandById.has(project.id)) {
          const projectDemand = projectDemandById.get(project.id);
          projectDemand.dueIn30d += 1;

          if (dueDateValue < due14Cutoff) {
            projectDemand.dueIn14d += 1;
          }

          if (dueDateValue < dueSoonCutoff) {
            projectDemand.dueIn7d += 1;
          }
        }

        assigneeIds.forEach((userId) => {
          if (!userDemandById.has(userId)) {
            const user = userById.get(userId);
            userDemandById.set(userId, {
              userId,
              name: user ? user.name : 'Unknown',
              username: user ? user.username : '',
              dueIn7d: 0,
              dueIn14d: 0,
              dueIn30d: 0,
            });
          }

          const userDemand = userDemandById.get(userId);
          userDemand.dueIn30d += 1;

          if (dueDateValue < due14Cutoff) {
            userDemand.dueIn14d += 1;
          }

          if (dueDateValue < dueSoonCutoff) {
            userDemand.dueIn7d += 1;
          }
        });

        requiredSkills.forEach((skill) => {
          const skillDemand = skillDemandBySkill.get(skill);
          if (!skillDemand) {
            return;
          }

          skillDemand.dueIn30d += 1;
          if (dueDateValue < due14Cutoff) {
            skillDemand.dueIn14d += 1;
          }
          if (dueDateValue < dueSoonCutoff) {
            skillDemand.dueIn7d += 1;
          }

          if (projectSkillAnalytics && projectSkillAnalytics.skillDetailsBySkill.has(skill)) {
            const projectSkillDetail = projectSkillAnalytics.skillDetailsBySkill.get(skill);
            projectSkillDetail.dueIn30d += 1;
          }
        });
      }
    });

    summary.overdueRate = ratio(summary.overdueCards, summary.cardsWithDueDate);
    summary.taskCompletionRate = ratio(summary.completedTasks, summary.totalTasks);
    summary.skillCoverageRate = ratio(
      summary.skillTaggedCards - summary.uncoveredSkillTaggedCards,
      summary.skillTaggedCards,
    );

    const projectBreakdown = Array.from(projectBuckets.values())
      .map(withRates)
      .sort((a, b) => b.riskScore - a.riskScore || a.projectName.localeCompare(b.projectName));

    const boardBreakdown = Array.from(boardBuckets.values())
      .map(withRates)
      .sort((a, b) => b.riskScore - a.riskScore || a.boardName.localeCompare(b.boardName));

    const userBreakdown = Array.from(userBuckets.values()).sort(
      (a, b) =>
        b.assignedCards - a.assignedCards ||
        b.assignedOverdue - a.assignedOverdue ||
        a.name.localeCompare(b.name),
    );

    const demandByProject = Array.from(projectDemandById.values()).sort(
      (a, b) => b.dueIn7d - a.dueIn7d || a.projectName.localeCompare(b.projectName),
    );

    const demandByUser = Array.from(userDemandById.values()).sort(
      (a, b) => b.dueIn7d - a.dueIn7d || a.name.localeCompare(b.name),
    );
    const demandByUserMap = new Map(demandByUser.map((row) => [row.userId, row]));
    const activeResourceUsersCount = userBreakdown.filter((row) => row.assignedCards > 0).length;
    const targetCardsPerUserIn30d =
      activeResourceUsersCount > 0 ? summary.dueIn30d / activeResourceUsersCount : 0;
    const resourceByUser = userBreakdown
      .map((userBucket) => {
        const userDemand = demandByUserMap.get(userBucket.userId) || {
          dueIn7d: 0,
          dueIn14d: 0,
          dueIn30d: 0,
        };
        const dueIn30d = userDemand.dueIn30d || 0;
        const utilization = targetCardsPerUserIn30d > 0 ? dueIn30d / targetCardsPerUserIn30d : 0;

        let capacityStatus = 'balanced';
        if (targetCardsPerUserIn30d > 0) {
          if (utilization > 1.2) {
            capacityStatus = 'overCapacity';
          } else if (utilization < 0.6) {
            capacityStatus = 'underCapacity';
          }
        }

        return {
          userId: userBucket.userId,
          name: userBucket.name,
          username: userBucket.username,
          assignedCards: userBucket.assignedCards,
          dueIn7d: userDemand.dueIn7d,
          dueIn14d: userDemand.dueIn14d,
          dueIn30d,
          targetCardsPerUserIn30d,
          utilization,
          capacityStatus,
        };
      })
      .sort(
        (a, b) =>
          b.utilization - a.utilization || b.dueIn30d - a.dueIn30d || a.name.localeCompare(b.name),
      );
    const overCapacityUsers = resourceByUser.filter((row) => row.capacityStatus === 'overCapacity');
    const underCapacityUsers = resourceByUser.filter(
      (row) => row.capacityStatus === 'underCapacity',
    );
    const balancedUsers = resourceByUser.filter((row) => row.capacityStatus === 'balanced');
    const resourceSummary = {
      totalUsers: resourceByUser.length,
      overCapacityUsers: overCapacityUsers.length,
      underCapacityUsers: underCapacityUsers.length,
      balancedUsers: balancedUsers.length,
      targetCardsPerUserIn30d,
    };
    const skillCoverageByClient = Array.from(skillCoverageByClientId.values())
      .map((row) => ({
        ...row,
        coverageRate: ratio(row.coveredSkillNeedCards, row.skillNeedCards),
      }))
      .sort(
        (a, b) =>
          b.uncoveredSkillNeedCards - a.uncoveredSkillNeedCards ||
          b.skillNeedCards - a.skillNeedCards ||
          a.clientName.localeCompare(b.clientName),
      );
    const skillCoverageByProject = Array.from(skillCoverageByProjectId.values())
      .map((row) => ({
        ...row,
        coverageRate: ratio(row.coveredSkillNeedCards, row.skillNeedCards),
      }))
      .sort(
        (a, b) =>
          b.uncoveredSkillNeedCards - a.uncoveredSkillNeedCards ||
          b.skillNeedCards - a.skillNeedCards ||
          a.projectName.localeCompare(b.projectName),
      );
    const resolveHealthStatus = (bucket) => {
      if (bucket.overdueRate >= 0.25 || bucket.blockedCards >= 5 || bucket.riskScore >= 20) {
        return 'offTrack';
      }

      if (bucket.overdueRate >= 0.1 || bucket.blockedCards > 0 || bucket.staleCards > 0) {
        return 'atRisk';
      }

      return 'onTrack';
    };
    const statusPriority = {
      offTrack: 0,
      atRisk: 1,
      onTrack: 2,
    };
    const deliveryHealthByClient = projectBreakdown
      .map((bucket) => {
        const status = resolveHealthStatus(bucket);

        return {
          clientId: bucket.projectId,
          clientName: bucket.projectName,
          status,
          taskCompletionRate: bucket.taskCompletionRate,
          overdueRate: bucket.overdueRate,
          overdueCards: bucket.overdueCards,
          blockedCards: bucket.blockedCards,
          staleCards: bucket.staleCards,
          dueSoon7d: bucket.dueSoon7d,
          blockersTotal: bucket.blockedCards + bucket.staleCards + bucket.overdueCards,
        };
      })
      .sort(
        (a, b) =>
          statusPriority[a.status] - statusPriority[b.status] ||
          b.blockersTotal - a.blockersTotal ||
          a.clientName.localeCompare(b.clientName),
      );
    const deliveryHealthByProject = boardBreakdown
      .map((bucket) => {
        const status = resolveHealthStatus(bucket);

        return {
          projectId: bucket.boardId,
          projectName: bucket.boardName,
          clientId: bucket.projectId,
          clientName: bucket.projectName,
          status,
          taskCompletionRate: bucket.taskCompletionRate,
          overdueRate: bucket.overdueRate,
          overdueCards: bucket.overdueCards,
          blockedCards: bucket.blockedCards,
          staleCards: bucket.staleCards,
          dueSoon7d: bucket.dueSoon7d,
          blockersTotal: bucket.blockedCards + bucket.staleCards + bucket.overdueCards,
        };
      })
      .sort(
        (a, b) =>
          statusPriority[a.status] - statusPriority[b.status] ||
          b.blockersTotal - a.blockersTotal ||
          a.projectName.localeCompare(b.projectName),
      );
    const topBlockersByClient = deliveryHealthByClient
      .filter((row) => row.blockersTotal > 0)
      .slice(0, 10);
    const topBlockersByProject = deliveryHealthByProject
      .filter((row) => row.blockersTotal > 0)
      .slice(0, 10);
    const deliveryHealthSummary = deliveryHealthByClient.reduce(
      (result, row) => ({
        ...result,
        [`${row.status}Count`]: result[`${row.status}Count`] + 1,
      }),
      {
        onTrackCount: 0,
        atRiskCount: 0,
        offTrackCount: 0,
      },
    );
    const projectAnalysisByClient = projectBreakdown
      .map((bucket) => ({
        clientId: bucket.projectId,
        clientName: bucket.projectName,
        totalCards: bucket.totalCards,
        blockedCards: bucket.blockedCards,
        dueSoon7d: bucket.dueSoon7d,
        overdueCards: bucket.overdueCards,
        riskScore: bucket.riskScore,
      }))
      .sort(
        (a, b) =>
          b.overdueCards - a.overdueCards ||
          b.blockedCards - a.blockedCards ||
          b.dueSoon7d - a.dueSoon7d ||
          a.clientName.localeCompare(b.clientName),
      );
    const projectAnalysisByProject = boardBreakdown
      .map((bucket) => ({
        projectId: bucket.boardId,
        projectName: bucket.boardName,
        clientId: bucket.projectId,
        clientName: bucket.projectName,
        totalCards: bucket.totalCards,
        blockedCards: bucket.blockedCards,
        dueSoon7d: bucket.dueSoon7d,
        overdueCards: bucket.overdueCards,
        riskScore: bucket.riskScore,
      }))
      .sort(
        (a, b) =>
          b.overdueCards - a.overdueCards ||
          b.blockedCards - a.blockedCards ||
          b.dueSoon7d - a.dueSoon7d ||
          a.projectName.localeCompare(b.projectName),
      );
    const projectAnalysisSummary = {
      clientsWithIssues: projectAnalysisByClient.filter(
        (row) => row.overdueCards > 0 || row.blockedCards > 0 || row.dueSoon7d > 0,
      ).length,
      projectsWithIssues: projectAnalysisByProject.filter(
        (row) => row.overdueCards > 0 || row.blockedCards > 0 || row.dueSoon7d > 0,
      ).length,
    };

    const trackedSkillsCount = new Set([
      ...Array.from(skillOwnersBySkill.keys()),
      ...Array.from(skillDemandBySkill.keys()),
    ]).size;
    const totalPeopleWithSkills = Array.from(skillsByUserId.values()).filter(
      (skills) => skills.size > 0,
    ).length;
    const completedCardsInWindow = cards.filter((card) => {
      if (!card.isDueDateCompleted || !card.updatedAt) {
        return false;
      }

      const updatedAt = new Date(card.updatedAt);
      if (Number.isNaN(updatedAt.getTime())) {
        return false;
      }

      return updatedAt.getTime() >= startAt && updatedAt.getTime() < windowEndExclusive;
    }).length;
    const averageCardCompletionPerDay = ratio(completedCardsInWindow, windowDays);
    const teamCapacityPerSkilledUserPerDay = ratio(
      completedCardsInWindow,
      Math.max(totalPeopleWithSkills, 1) * windowDays,
    );

    const skillLoad = Array.from(skillDemandBySkill.values())
      .map((skillDemand) => ({
        skill: skillDemand.skill,
        skilledUsers: skillDemand.skilledUsers,
        assignedUsersCount: skillDemand.assignedUserIds.size,
        demandCards: skillDemand.demandCards,
        activeNeedCards: skillDemand.activeNeedCards,
        coveredCards: skillDemand.coveredCards,
        uncoveredCards: skillDemand.uncoveredCards,
        coveredActiveNeedCards: skillDemand.coveredActiveNeedCards,
        uncoveredActiveNeedCards: skillDemand.uncoveredActiveNeedCards,
        coverageRate: ratio(skillDemand.coveredActiveNeedCards, skillDemand.activeNeedCards),
        demandPerSkilledUser:
          skillDemand.skilledUsers > 0
            ? skillDemand.activeNeedCards / skillDemand.skilledUsers
            : null,
        dueIn7d: skillDemand.dueIn7d,
        dueIn14d: skillDemand.dueIn14d,
        dueIn30d: skillDemand.dueIn30d,
        completedInWindow: skillDemand.completedInWindow,
        skillThroughputPerDay: ratio(skillDemand.completedInWindow, windowDays),
        capacityPerDay: Math.max(
          ratio(skillDemand.completedInWindow, windowDays),
          skillDemand.skilledUsers * teamCapacityPerSkilledUserPerDay,
        ),
        capacityIn7d:
          Math.max(
            ratio(skillDemand.completedInWindow, windowDays),
            skillDemand.skilledUsers * teamCapacityPerSkilledUserPerDay,
          ) * 7,
        capacityIn14d:
          Math.max(
            ratio(skillDemand.completedInWindow, windowDays),
            skillDemand.skilledUsers * teamCapacityPerSkilledUserPerDay,
          ) * 14,
        capacityIn30d:
          Math.max(
            ratio(skillDemand.completedInWindow, windowDays),
            skillDemand.skilledUsers * teamCapacityPerSkilledUserPerDay,
          ) * 30,
      }))
      .map((row) => ({
        ...row,
        gapIn7d: Math.max(0, row.dueIn7d - row.capacityIn7d),
        gapIn14d: Math.max(0, row.dueIn14d - row.capacityIn14d),
        gapIn30d: Math.max(0, row.dueIn30d - row.capacityIn30d),
      }))
      .sort(
        (a, b) =>
          b.uncoveredActiveNeedCards - a.uncoveredActiveNeedCards ||
          b.activeNeedCards - a.activeNeedCards ||
          a.skill.localeCompare(b.skill),
      );

    const currentSkillAllocation = skillLoad
      .slice()
      .sort(
        (a, b) =>
          b.uncoveredActiveNeedCards - a.uncoveredActiveNeedCards ||
          b.activeNeedCards - a.activeNeedCards ||
          a.skill.localeCompare(b.skill),
      );

    const futureSkillsAtRisk = skillLoad
      .filter((skillDemand) => skillDemand.gapIn14d > 0 || skillDemand.gapIn30d > 0)
      .sort(
        (a, b) =>
          b.gapIn30d - a.gapIn30d ||
          b.gapIn14d - a.gapIn14d ||
          b.uncoveredActiveNeedCards - a.uncoveredActiveNeedCards ||
          a.skill.localeCompare(b.skill),
      );

    const topSkillsAtRisk = futureSkillsAtRisk.slice(0, 10);

    summary.skillsAtRisk = topSkillsAtRisk.length;
    const skillAnalyticsByProject = Array.from(skillAnalyticsByProjectId.values())
      .map((projectSkillAnalytics) => {
        const skillDetails = Array.from(projectSkillAnalytics.skillDetailsBySkill.values())
          .map((detail) => {
            const capacityIn30d =
              detail.assignedSkilledUserIds.size * teamCapacityPerSkilledUserPerDay * 30;

            return {
              skill: detail.skill,
              neededCards: detail.neededCards,
              coveredCards: detail.coveredCards,
              uncoveredCards: detail.uncoveredCards,
              dueIn30d: detail.dueIn30d,
              assignedSkilledUsers: detail.assignedSkilledUserIds.size,
              capacityIn30d,
              gapIn30d: Math.max(0, detail.dueIn30d - capacityIn30d),
            };
          })
          .sort(
            (a, b) =>
              b.gapIn30d - a.gapIn30d ||
              b.uncoveredCards - a.uncoveredCards ||
              a.skill.localeCompare(b.skill),
          );
        const dueIn30d = skillDetails.reduce((result, row) => result + row.dueIn30d, 0);
        const capacityIn30d = skillDetails.reduce((result, row) => result + row.capacityIn30d, 0);
        const overCapacitySkills = skillDetails.filter((row) => row.gapIn30d > 0).length;

        return {
          projectId: projectSkillAnalytics.projectId,
          projectName: projectSkillAnalytics.projectName,
          clientId: projectSkillAnalytics.clientId,
          clientName: projectSkillAnalytics.clientName,
          cardsWithSkillNeed: projectSkillAnalytics.cardsWithSkillNeed,
          coveredCards: projectSkillAnalytics.coveredCards,
          uncoveredCards: projectSkillAnalytics.uncoveredCards,
          coverageRate: ratio(
            projectSkillAnalytics.coveredCards,
            projectSkillAnalytics.cardsWithSkillNeed,
          ),
          skillsNeededCount: projectSkillAnalytics.skillsNeededSet.size,
          overCapacitySkills,
          dueIn30d,
          capacityIn30d,
          gapIn30d: Math.max(0, dueIn30d - capacityIn30d),
          skillDetails,
        };
      })
      .sort(
        (a, b) =>
          b.gapIn30d - a.gapIn30d ||
          b.uncoveredCards - a.uncoveredCards ||
          a.projectName.localeCompare(b.projectName),
      );
    const skillsetAnalytics = skillLoad
      .map((skillset) => ({
        skill: skillset.skill,
        neededCards: skillset.activeNeedCards,
        coveredCards: skillset.coveredActiveNeedCards,
        uncoveredCards: skillset.uncoveredActiveNeedCards,
        dueIn30d: skillset.dueIn30d,
        capacityIn30d: skillset.capacityIn30d,
        gapIn30d: skillset.gapIn30d,
        overCapacity: skillset.gapIn30d > 0,
      }))
      .sort(
        (a, b) =>
          b.gapIn30d - a.gapIn30d ||
          b.uncoveredCards - a.uncoveredCards ||
          a.skill.localeCompare(b.skill),
      );
    const skillAnalyticsSummary = {
      skillsetsTracked: skillsetAnalytics.length,
      skillsetsNeeded: skillsetAnalytics.filter((row) => row.neededCards > 0).length,
      skillsetsOverCapacity: skillsetAnalytics.filter((row) => row.overCapacity).length,
      skillsetsUncovered: skillsetAnalytics.filter((row) => row.uncoveredCards > 0).length,
      projectsWithSkillNeeds: skillAnalyticsByProject.filter((row) => row.cardsWithSkillNeed > 0)
        .length,
    };

    const sortedRiskQueue = riskQueue
      .sort((a, b) => b.riskScore - a.riskScore || a.cardName.localeCompare(b.cardName))
      .slice(0, RISK_QUEUE_LIMIT);

    const topRiskProjects = projectBreakdown
      .filter((projectBucket) => projectBucket.riskScore > 0)
      .slice(0, 10)
      .map((projectBucket) => ({
        projectId: projectBucket.projectId,
        projectName: projectBucket.projectName,
        riskScore: projectBucket.riskScore,
        overdueCards: projectBucket.overdueCards,
        blockedCards: projectBucket.blockedCards,
        staleCards: projectBucket.staleCards,
      }));

    const totalAssignedCards = userBreakdown.reduce(
      (accumulator, userBucket) => accumulator + userBucket.assignedCards,
      0,
    );
    const topAssignee = userBreakdown[0] || null;
    const topAssigneeShare = topAssignee ? ratio(topAssignee.assignedCards, totalAssignedCards) : 0;
    const estimatedCompletions7d = averageCardCompletionPerDay * 7;
    const estimatedCompletions14d = averageCardCompletionPerDay * 14;
    const estimatedCompletions30d = averageCardCompletionPerDay * 30;
    const projectedLate7d = Math.max(0, summary.dueSoon7d - estimatedCompletions7d);
    const projectedLate14d = Math.max(0, summary.dueIn14d - estimatedCompletions14d);
    const projectedLate30d = Math.max(0, summary.dueIn30d - estimatedCompletions30d);
    const deliveryRiskIndex30d = summary.dueIn30d / Math.max(estimatedCompletions30d, 1);

    summary.concentrationTopAssigneeShare = topAssigneeShare;

    return {
      scope: {
        role: currentUser.isAdmin ? 'admin' : 'manager',
        projectIds,
        windowDays,
        projectFilterId: inputs.projectId || null,
        generatedAt: now.toISOString(),
      },
      summary,
      breakdowns: {
        projects: projectBreakdown,
        boards: boardBreakdown,
        users: userBreakdown,
      },
      issues: {
        riskQueue: sortedRiskQueue,
        topRiskProjects,
        blockedKeywords: BLOCKED_KEYWORDS,
        staleDaysThreshold: STALE_DAYS,
      },
      forecast: {
        windowDays,
        completedCardsInWindow,
        averageCardCompletionPerDay,
        dueDemand: {
          in7d: summary.dueSoon7d,
          in14d: summary.dueIn14d,
          in30d: summary.dueIn30d,
        },
        estimatedCompletions: {
          in7d: estimatedCompletions7d,
          in14d: estimatedCompletions14d,
          in30d: estimatedCompletions30d,
        },
        projectedLate: {
          in7d: projectedLate7d,
          in14d: projectedLate14d,
          in30d: projectedLate30d,
        },
        deliveryRiskIndex30d,
      },
      skillsAllocation: {
        trackedSkillsCount,
        totalPeopleWithSkills,
        capacityAssumptions: {
          windowDays,
          teamCapacityPerSkilledUserPerDay,
        },
        skillTaggedCards: summary.skillTaggedCards,
        uncoveredSkillTaggedCards: summary.uncoveredSkillTaggedCards,
        skillCoverageRate: summary.skillCoverageRate,
        skillsAtRisk: summary.skillsAtRisk,
        currentAllocation: currentSkillAllocation,
        futureAtRisk: futureSkillsAtRisk,
        topSkillsAtRisk,
        byClient: skillCoverageByClient,
        byProject: skillCoverageByProject,
        skillLoad,
      },
      skillAnalytics: {
        summary: skillAnalyticsSummary,
        byProject: skillAnalyticsByProject,
        bySkillset: skillsetAnalytics,
      },
      projectAnalysis: {
        summary: projectAnalysisSummary,
        byClient: projectAnalysisByClient,
        byProject: projectAnalysisByProject,
      },
      deliveryHealth: {
        summary: deliveryHealthSummary,
        byClient: deliveryHealthByClient,
        byProject: deliveryHealthByProject,
        topBlockersByClient,
        topBlockersByProject,
      },
      resourceAnalysis: {
        summary: resourceSummary,
        byUser: resourceByUser,
        overCapacityUsers,
        underCapacityUsers,
      },
      resourcePlanning: {
        demandHorizonDays: DUE_HORIZON_DAYS,
        workloadByUser: userBreakdown,
        demandHorizon: {
          byProject: demandByProject,
          byUser: demandByUser,
        },
        concentration: {
          threshold: CONCENTRATION_RISK_THRESHOLD,
          topAssignee: topAssignee
            ? {
                userId: topAssignee.userId,
                name: topAssignee.name,
                username: topAssignee.username,
                assignedCards: topAssignee.assignedCards,
                share: topAssigneeShare,
              }
            : null,
          isAtRisk: totalAssignedCards > 0 && topAssigneeShare > CONCENTRATION_RISK_THRESHOLD,
        },
      },
      trends: {
        cardsCreatedDaily: dates.map((date) => ({
          date,
          count: cardsCreatedByDate[date],
        })),
        tasksCompletedDaily: dates.map((date) => ({
          date,
          count: tasksCompletedByDate[date],
        })),
      },
      projects: projects.map((project) => ({
        id: project.id,
        name: project.name,
      })),
      boards: boards.map((board) => ({
        id: board.id,
        name: board.name,
        projectId: board.projectId,
      })),
      lists: lists.map((list) => ({
        id: list.id,
        name: list.name,
        boardId: list.boardId,
      })),
      cards: cards.map((card) => ({
        id: card.id,
        name: card.name,
        listId: card.listId,
        boardId: card.boardId,
        dueDate: card.dueDate,
        isDueDateCompleted: card.isDueDateCompleted,
        createdAt: card.createdAt,
        updatedAt: card.updatedAt,
      })),
      cardMemberships: cardMembershipsResult.map((cardMembership) => ({
        cardId: cardMembership.cardId,
        userId: cardMembership.userId,
      })),
      users: users.map((user) => ({
        id: user.id,
        name: user.name,
        username: user.username,
        skills: _.isArray(user.skills) ? user.skills : [],
      })),
    };
  },
};
