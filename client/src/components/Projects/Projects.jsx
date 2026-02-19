import upperFirst from 'lodash/upperFirst';
import camelCase from 'lodash/camelCase';
import React, { useCallback, useMemo, useState, useRef, useEffect } from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';
import { useTranslation } from 'react-i18next';
import { Link, useNavigate } from 'react-router-dom';
import { Container, Grid, Icon } from 'semantic-ui-react';

import Paths from '../../constants/Paths';
import { ProjectBackgroundTypes } from '../../constants/Enums';
import { ReactComponent as PlusIcon } from '../../assets/images/plus-icon.svg';
import api from '../../api';
import { getAnalytics } from '../../api/analytics';

import styles from './Projects.module.scss';
import globalStyles from '../../styles.module.scss';

const DAY_MS = 24 * 60 * 60 * 1000;
const FALLBACK_DUE_SOON_DAYS = 7;
const FALLBACK_DUE_WINDOW_DAYS = 30;
const FALLBACK_STALE_DAYS = 10;
const BLOCKED_HINTS = ['blocked', 'on hold', 'waiting'];

const hasValue = (value) => value !== undefined && value !== null;

const normalizeSkill = (value) => (value || '').toString().trim().toLowerCase();

const extractSkills = (skills) => {
  if (Array.isArray(skills)) {
    return skills;
  }

  if (typeof skills === 'string') {
    return skills.split(',');
  }

  return [];
};

const isBlockedText = (value) => {
  const normalizedValue = (value || '').toString().trim().toLowerCase();

  return (
    normalizedValue !== '' &&
    BLOCKED_HINTS.some((hint) => normalizedValue.includes(hint))
  );
};

const formatCapacityStatus = (value) => {
  if (value === 'overCapacity') {
    return 'Over capacity';
  }

  if (value === 'underCapacity') {
    return 'Under capacity';
  }

  return 'Balanced';
};

const Projects = React.memo(
  ({
    items, calendarDueCards, calendarMilestones,
    projectsToLists, canAdd, isAdmin, onAdd, onEditProject,
  }) => {
  const [t] = useTranslation();
  const navigate = useNavigate();
  const today = useMemo(() => new Date(), []);

  const [viewingMonth, setViewingMonth] = useState(today.getMonth());
  const [viewingYear, setViewingYear] = useState(today.getFullYear());
  const [calendarView, setCalendarView] = useState('projects');

  // Milestone creation popover state
  const [milestonePopover, setMilestonePopover] = useState(null); // { day }
  const [detailsPopover, setDetailsPopover] = useState(null); // { day, type, items }
  const [milestoneForm, setMilestoneForm] = useState({ projectId: '', boardId: '', name: '' });
  const [editingMilestone, setEditingMilestone] = useState(null);
  const [editForm, setEditForm] = useState({ name: '', dueDate: '' });
  const [analyticsDueCards, setAnalyticsDueCards] = useState(null);
  const [analyticsData, setAnalyticsData] = useState(null);
  const popoverRef = useRef(null);

  // Close popover when clicking outside
  useEffect(() => {
    const handleClickOutside = (e) => {
      if (popoverRef.current && !popoverRef.current.contains(e.target)) {
        setMilestonePopover(null);
        setDetailsPopover(null);
        setEditingMilestone(null);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  useEffect(() => {
    let isMounted = true;

    const loadCalendarDueCards = async () => {
      try {
        const data = await getAnalytics();

        if (!isMounted || !data || !Array.isArray(data.cards)) {
          return;
        }

        const projectsById = new Map(
          (Array.isArray(data.projects) ? data.projects : []).map((project) => [
            project.id,
            project.name,
          ]),
        );
        const boardsById = new Map(
          (Array.isArray(data.boards) ? data.boards : []).map((board) => [board.id, board]),
        );

        const dueCards = data.cards
          .filter((card) => card.dueDate)
          .map((card) => {
            const board = boardsById.get(card.boardId);
            const projectId = board && board.projectId;

            return {
              ...card,
              projectId,
              projectName: projectId ? projectsById.get(projectId) : undefined,
              boardName: board && board.name,
            };
          });

        setAnalyticsDueCards(dueCards);
        setAnalyticsData(data.summary ? data : null);
      } catch {
        // Keep selector-provided cards as fallback when analytics request is unavailable.
        if (isMounted) {
          setAnalyticsDueCards(null);
          setAnalyticsData(null);
        }
      }
    };

    loadCalendarDueCards();

    return () => {
      isMounted = false;
    };
  }, []);

  const effectiveCalendarDueCards = analyticsDueCards === null
    ? calendarDueCards
    : analyticsDueCards;

  const derivedAnalytics = useMemo(() => {
    if (!analyticsData) {
      return null;
    }

    const cards = Array.isArray(analyticsData.cards) ? analyticsData.cards : [];
    const projects = Array.isArray(analyticsData.projects) ? analyticsData.projects : [];
    const boards = Array.isArray(analyticsData.boards) ? analyticsData.boards : [];
    const lists = Array.isArray(analyticsData.lists) ? analyticsData.lists : [];
    const users = Array.isArray(analyticsData.users) ? analyticsData.users : [];
    const cardMemberships = Array.isArray(analyticsData.cardMemberships)
      ? analyticsData.cardMemberships
      : [];

    if (cards.length === 0) {
      return {
        skillByProject: [],
        skillBySkillset: [],
        projectByClient: [],
        projectByProject: [],
        resourceByUser: [],
        resourceSummary: null,
        overCapacityUsers: [],
        underCapacityUsers: [],
      };
    }

    const now = new Date();
    const dueSoonCutoff = new Date(now.getTime() + FALLBACK_DUE_SOON_DAYS * DAY_MS);
    const due30Cutoff = new Date(now.getTime() + FALLBACK_DUE_WINDOW_DAYS * DAY_MS);
    const staleCutoff = new Date(now.getTime() - FALLBACK_STALE_DAYS * DAY_MS);
    const projectById = new Map(projects.map((project) => [project.id, project]));
    const boardById = new Map(boards.map((board) => [board.id, board]));
    const userById = new Map(users.map((user) => [user.id, user]));
    const listNameById = new Map(lists.map((list) => [list.id, list.name || '']));
    const assigneeIdsByCardId = new Map();

    cardMemberships.forEach(({ cardId, userId }) => {
      if (!assigneeIdsByCardId.has(cardId)) {
        assigneeIdsByCardId.set(cardId, new Set());
      }

      assigneeIdsByCardId.get(cardId).add(userId);
    });

    const skillsByUserId = new Map();
    const skillOwnersBySkill = new Map();
    users.forEach((user) => {
      const userSkills = new Set(
        extractSkills(user.skills)
          .map((skill) => normalizeSkill(skill))
          .filter((skill) => skill !== ''),
      );

      skillsByUserId.set(user.id, userSkills);

      userSkills.forEach((skill) => {
        if (!skillOwnersBySkill.has(skill)) {
          skillOwnersBySkill.set(skill, new Set());
        }

        skillOwnersBySkill.get(skill).add(user.id);
      });
    });

    const projectClientBuckets = new Map();
    const projectBucketsByBoardId = new Map();
    const skillByProjectBuckets = new Map();
    const skillBySkillsetBuckets = new Map();
    const userCapacityById = new Map(
      users.map((user) => [
        user.id,
        {
          userId: user.id,
          name: user.name || 'Unknown',
          assignedCards: 0,
          dueIn30d: 0,
        },
      ]),
    );
    let totalDueIn30d = 0;
    let blockersCount = 0;
    let unupdatedCards = 0;
    let overdueCards = 0;

    const ensureProjectClientBucket = (projectId) => {
      if (!projectId) {
        return null;
      }

      if (!projectClientBuckets.has(projectId)) {
        const project = projectById.get(projectId);
        projectClientBuckets.set(projectId, {
          clientId: projectId,
          clientName: project ? project.name : 'Unknown client',
          totalCards: 0,
          blockedCards: 0,
          dueSoon7d: 0,
          overdueCards: 0,
        });
      }

      return projectClientBuckets.get(projectId);
    };
    const ensureProjectBucket = (board) => {
      if (!board) {
        return null;
      }

      if (!projectBucketsByBoardId.has(board.id)) {
        const project = projectById.get(board.projectId);
        projectBucketsByBoardId.set(board.id, {
          projectId: board.id,
          projectName: board.name || 'Unknown project',
          clientId: board.projectId || null,
          clientName: project ? project.name : 'Unknown client',
          totalCards: 0,
          blockedCards: 0,
          dueSoon7d: 0,
          overdueCards: 0,
        });
      }

      return projectBucketsByBoardId.get(board.id);
    };
    const ensureProjectSkillBucket = (board) => {
      if (!board) {
        return null;
      }

      if (!skillByProjectBuckets.has(board.id)) {
        const project = projectById.get(board.projectId);
        skillByProjectBuckets.set(board.id, {
          projectId: board.id,
          projectName: board.name || 'Unknown project',
          clientId: board.projectId || null,
          clientName: project ? project.name : 'Unknown client',
          cardsWithSkillNeed: 0,
          coveredCards: 0,
          uncoveredCards: 0,
          skillsNeededSet: new Set(),
          skillDetailsBySkill: new Map(),
        });
      }

      return skillByProjectBuckets.get(board.id);
    };
    const ensureSkillsetBucket = (skill) => {
      if (!skillBySkillsetBuckets.has(skill)) {
        skillBySkillsetBuckets.set(skill, {
          skill,
          neededCards: 0,
          coveredCards: 0,
          uncoveredCards: 0,
          dueIn30d: 0,
        });
      }

      return skillBySkillsetBuckets.get(skill);
    };
    const ensureUserBucket = (userId) => {
      if (!userCapacityById.has(userId)) {
        const user = userById.get(userId);
        userCapacityById.set(userId, {
          userId,
          name: user ? user.name : 'Unknown',
          assignedCards: 0,
          dueIn30d: 0,
        });
      }

      return userCapacityById.get(userId);
    };

    cards.forEach((card) => {
      const board = boardById.get(card.boardId);
      const assigneeIds = Array.from(assigneeIdsByCardId.get(card.id) || []);
      const listName = listNameById.get(card.listId) || '';
      const isCompleted = card.isDueDateCompleted === true;
      const dueDate = card.dueDate ? new Date(card.dueDate) : null;
      const updatedAt = card.updatedAt ? new Date(card.updatedAt) : null;
      const hasDueDate = !!(dueDate && !Number.isNaN(dueDate.getTime()));
      const isOverdue = hasDueDate && !isCompleted && dueDate < now;
      const isDueSoon = hasDueDate && !isCompleted && dueDate >= now && dueDate < dueSoonCutoff;
      const isDueIn30d = hasDueDate && !isCompleted && dueDate >= now && dueDate < due30Cutoff;
      const isBlocked = isBlockedText(listName);
      const isUnupdated =
        !isCompleted &&
        !!(updatedAt && !Number.isNaN(updatedAt.getTime()) && updatedAt < staleCutoff);

      if (isBlocked) {
        blockersCount += 1;
      }

      if (isUnupdated) {
        unupdatedCards += 1;
      }

      if (isOverdue) {
        overdueCards += 1;
      }

      if (board && !isCompleted) {
        const clientBucket = ensureProjectClientBucket(board.projectId);
        const projectBucket = ensureProjectBucket(board);

        if (clientBucket) {
          clientBucket.totalCards += 1;
          if (isBlocked) {
            clientBucket.blockedCards += 1;
          }
          if (isDueSoon) {
            clientBucket.dueSoon7d += 1;
          }
          if (isOverdue) {
            clientBucket.overdueCards += 1;
          }
        }

        if (projectBucket) {
          projectBucket.totalCards += 1;
          if (isBlocked) {
            projectBucket.blockedCards += 1;
          }
          if (isDueSoon) {
            projectBucket.dueSoon7d += 1;
          }
          if (isOverdue) {
            projectBucket.overdueCards += 1;
          }
        }
      }

      assigneeIds.forEach((userId) => {
        const userBucket = ensureUserBucket(userId);
        userBucket.assignedCards += 1;
        if (isDueIn30d) {
          userBucket.dueIn30d += 1;
        }
      });

      if (isDueIn30d) {
        totalDueIn30d += 1;
      }

      if (!board || isCompleted) {
        return;
      }

      const cardSkills = new Set();
      assigneeIds.forEach((userId) => {
        const userSkills = skillsByUserId.get(userId);
        if (!userSkills || userSkills.size === 0) {
          return;
        }

        userSkills.forEach((skill) => cardSkills.add(skill));
      });

      if (cardSkills.size === 0) {
        return;
      }

      const projectSkillBucket = ensureProjectSkillBucket(board);
      if (!projectSkillBucket) {
        return;
      }

      projectSkillBucket.cardsWithSkillNeed += 1;
      let cardCovered = true;

      cardSkills.forEach((skill) => {
        const skilledUsers = skillOwnersBySkill.get(skill) || new Set();
        const skilledAssignees = assigneeIds.filter((userId) => skilledUsers.has(userId));
        const skillCovered = skilledAssignees.length > 0;
        const skillsetBucket = ensureSkillsetBucket(skill);

        skillsetBucket.neededCards += 1;
        if (skillCovered) {
          skillsetBucket.coveredCards += 1;
        } else {
          skillsetBucket.uncoveredCards += 1;
          cardCovered = false;
        }
        if (isDueIn30d) {
          skillsetBucket.dueIn30d += 1;
        }

        if (!projectSkillBucket.skillDetailsBySkill.has(skill)) {
          projectSkillBucket.skillDetailsBySkill.set(skill, {
            skill,
            neededCards: 0,
            coveredCards: 0,
            uncoveredCards: 0,
            dueIn30d: 0,
            assignedSkilledUserIds: new Set(),
          });
        }

        const projectSkillDetail = projectSkillBucket.skillDetailsBySkill.get(skill);
        projectSkillDetail.neededCards += 1;
        if (skillCovered) {
          projectSkillDetail.coveredCards += 1;
        } else {
          projectSkillDetail.uncoveredCards += 1;
        }
        if (isDueIn30d) {
          projectSkillDetail.dueIn30d += 1;
        }
        skilledAssignees.forEach((userId) => projectSkillDetail.assignedSkilledUserIds.add(userId));

        projectSkillBucket.skillsNeededSet.add(skill);
      });

      if (cardCovered) {
        projectSkillBucket.coveredCards += 1;
      } else {
        projectSkillBucket.uncoveredCards += 1;
      }
    });

    const skilledUsersCount = Array.from(skillsByUserId.values()).filter(
      (skills) => skills.size > 0,
    ).length;
    const configuredCapacityPerDay =
      analyticsData &&
      analyticsData.skillsAllocation &&
      analyticsData.skillsAllocation.capacityAssumptions
        ? analyticsData.skillsAllocation.capacityAssumptions.teamCapacityPerSkilledUserPerDay || 0
        : 0;
    const inferredCapacityPerDay =
      skilledUsersCount > 0 ? totalDueIn30d / (skilledUsersCount * FALLBACK_DUE_WINDOW_DAYS) : 0;
    const capacityPerSkilledUserPerDay =
      configuredCapacityPerDay > 0 ? configuredCapacityPerDay : inferredCapacityPerDay;

    const skillBySkillset = Array.from(skillBySkillsetBuckets.values())
      .map((skillset) => {
        const skilledUsers = skillOwnersBySkill.has(skillset.skill)
          ? skillOwnersBySkill.get(skillset.skill).size
          : 0;
        const capacityIn30d =
          skilledUsers * capacityPerSkilledUserPerDay * FALLBACK_DUE_WINDOW_DAYS;
        const gapIn30d = Math.max(0, skillset.dueIn30d - capacityIn30d);

        return {
          ...skillset,
          skilledUsers,
          capacityIn30d,
          gapIn30d,
          overCapacity: gapIn30d > 0,
        };
      })
      .sort(
        (a, b) =>
          b.gapIn30d - a.gapIn30d ||
          b.uncoveredCards - a.uncoveredCards ||
          a.skill.localeCompare(b.skill),
      );
    const trackedSkillsetCount = new Set([
      ...Array.from(skillOwnersBySkill.keys()),
      ...Array.from(skillBySkillsetBuckets.keys()),
    ]).size;

    const skillByProject = Array.from(skillByProjectBuckets.values())
      .map((projectSkillBucket) => {
        const skillDetails = Array.from(projectSkillBucket.skillDetailsBySkill.values()).map(
          (detail) => {
            const capacityIn30d =
              detail.assignedSkilledUserIds.size *
              capacityPerSkilledUserPerDay *
              FALLBACK_DUE_WINDOW_DAYS;

            return {
              skill: detail.skill,
              neededCards: detail.neededCards,
              coveredCards: detail.coveredCards,
              uncoveredCards: detail.uncoveredCards,
              dueIn30d: detail.dueIn30d,
              capacityIn30d,
              gapIn30d: Math.max(0, detail.dueIn30d - capacityIn30d),
            };
          },
        );
        const dueIn30d = skillDetails.reduce((sum, detail) => sum + detail.dueIn30d, 0);
        const capacityIn30d = skillDetails.reduce((sum, detail) => sum + detail.capacityIn30d, 0);
        const overCapacitySkills = skillDetails.filter((detail) => detail.gapIn30d > 0).length;

        return {
          projectId: projectSkillBucket.projectId,
          projectName: projectSkillBucket.projectName,
          clientId: projectSkillBucket.clientId,
          clientName: projectSkillBucket.clientName,
          cardsWithSkillNeed: projectSkillBucket.cardsWithSkillNeed,
          coveredCards: projectSkillBucket.coveredCards,
          uncoveredCards: projectSkillBucket.uncoveredCards,
          skillsNeededCount: projectSkillBucket.skillsNeededSet.size,
          overCapacitySkills,
          dueIn30d,
          capacityIn30d,
          gapIn30d: Math.max(0, dueIn30d - capacityIn30d),
        };
      })
      .sort(
        (a, b) =>
          b.gapIn30d - a.gapIn30d ||
          b.uncoveredCards - a.uncoveredCards ||
          a.projectName.localeCompare(b.projectName),
      );

    const projectByClient = Array.from(projectClientBuckets.values()).sort(
      (a, b) =>
        b.overdueCards - a.overdueCards ||
        b.blockedCards - a.blockedCards ||
        b.dueSoon7d - a.dueSoon7d ||
        a.clientName.localeCompare(b.clientName),
    );
    const projectByProject = Array.from(projectBucketsByBoardId.values()).sort(
      (a, b) =>
        b.overdueCards - a.overdueCards ||
        b.blockedCards - a.blockedCards ||
        b.dueSoon7d - a.dueSoon7d ||
        a.projectName.localeCompare(b.projectName),
    );

    const activeCapacityRows = Array.from(userCapacityById.values()).filter(
      (userBucket) => userBucket.assignedCards > 0 || userBucket.dueIn30d > 0,
    );
    const totalPeopleCount = Array.from(userCapacityById.values()).length;
    const totalAssignedCards = Array.from(userCapacityById.values()).reduce(
      (result, row) => result + (row.assignedCards || 0),
      0,
    );
    const avgCardsAssignedPerPerson =
      totalPeopleCount > 0
        ? totalAssignedCards / totalPeopleCount
        : 0;
    const targetCardsPerUserIn30d =
      activeCapacityRows.length > 0 ? totalDueIn30d / activeCapacityRows.length : 0;
    const resourceByUser = activeCapacityRows
      .map((row) => {
        const utilization =
          targetCardsPerUserIn30d > 0 ? row.dueIn30d / targetCardsPerUserIn30d : 0;
        let capacityStatus = 'balanced';

        if (targetCardsPerUserIn30d > 0) {
          if (utilization > 1.2) {
            capacityStatus = 'overCapacity';
          } else if (utilization < 0.6) {
            capacityStatus = 'underCapacity';
          }
        }

        return {
          ...row,
          targetCardsPerUserIn30d,
          utilization,
          capacityStatus,
        };
      })
      .sort(
        (a, b) =>
          b.utilization - a.utilization ||
          b.dueIn30d - a.dueIn30d ||
          a.name.localeCompare(b.name),
      );

    const overCapacityUsers = resourceByUser.filter((row) => row.capacityStatus === 'overCapacity');
    const underCapacityUsers = resourceByUser.filter(
      (row) => row.capacityStatus === 'underCapacity',
    );
    const balancedUsers = resourceByUser.filter((row) => row.capacityStatus === 'balanced');
    const resourceSummary =
      resourceByUser.length > 0
        ? {
            totalUsers: resourceByUser.length,
            overCapacityUsers: overCapacityUsers.length,
            underCapacityUsers: underCapacityUsers.length,
            balancedUsers: balancedUsers.length,
            targetCardsPerUserIn30d,
          }
        : null;

    return {
      skillByProject,
      skillBySkillset,
      projectByClient,
      projectByProject,
      resourceByUser,
      resourceSummary,
      overCapacityUsers,
      underCapacityUsers,
      capacityPerSkilledUserPerDay,
      cardCount: cards.length,
      blockersCount,
      unupdatedCards,
      overdueCards,
      skillsetCount: trackedSkillsetCount,
      avgCardsAssignedPerPerson,
    };
  }, [analyticsData]);

  const analyticsKpis = useMemo(() => {
    if (!analyticsData) {
      return [];
    }

    const summary = (analyticsData && analyticsData.summary) || {};
    const totalCards = hasValue(summary.totalActiveCards)
      ? summary.totalActiveCards
      : (derivedAnalytics && derivedAnalytics.cardCount) ||
        (Array.isArray(analyticsData.cards) ? analyticsData.cards.length : 0);
    const blockers = hasValue(summary.blockedCards)
      ? summary.blockedCards
      : (derivedAnalytics && derivedAnalytics.blockersCount) || 0;
    const unupdatedCards = hasValue(summary.staleCards)
      ? summary.staleCards
      : (derivedAnalytics && derivedAnalytics.unupdatedCards) || 0;
    const overdueCards = hasValue(summary.overdueCards)
      ? summary.overdueCards
      : (derivedAnalytics && derivedAnalytics.overdueCards) || 0;
    const workloadRows =
      (analyticsData.breakdowns && analyticsData.breakdowns.users) ||
      (analyticsData.resourceAnalysis && analyticsData.resourceAnalysis.byUser) ||
      (derivedAnalytics && derivedAnalytics.resourceByUser) ||
      [];
    const resourceSummary =
      (analyticsData.resourceAnalysis && analyticsData.resourceAnalysis.summary) ||
      (derivedAnalytics && derivedAnalytics.resourceSummary) ||
      null;
    let overCapacityResources = workloadRows.filter(
      (row) => row.capacityStatus === 'overCapacity',
    ).length;

    if (derivedAnalytics && derivedAnalytics.overCapacityUsers) {
      overCapacityResources = derivedAnalytics.overCapacityUsers.length;
    }

    if (resourceSummary && hasValue(resourceSummary.overCapacityUsers)) {
      overCapacityResources = resourceSummary.overCapacityUsers;
    }
    const totalAssignedCards = workloadRows.reduce(
      (result, row) => result + (row.assignedCards || 0),
      0,
    );
    const totalPeopleCount = Array.isArray(analyticsData.users)
      ? analyticsData.users.length
      : workloadRows.length;
    const avgCardsAssignedPerPerson =
      totalPeopleCount > 0
        ? totalAssignedCards / totalPeopleCount
        : (derivedAnalytics && derivedAnalytics.avgCardsAssignedPerPerson) || 0;

    return [
      { label: 'Cards', value: totalCards || 0 },
      { label: 'Blockers', value: blockers || 0 },
      { label: 'Unupdated Cards', value: unupdatedCards || 0 },
      { label: 'Number of Overdue Cards', value: overdueCards || 0 },
      {
        label: 'Avg. Cards Assigned / Person',
        value: (Math.round(avgCardsAssignedPerPerson * 10) / 10).toFixed(1),
      },
      { label: 'Over Capacity Resources', value: overCapacityResources || 0 },
    ];
  }, [analyticsData, derivedAnalytics]);

  const projectAnalysisByClient = useMemo(() => {
    if (!analyticsData) {
      return [];
    }

    const nextRows =
      (analyticsData.projectAnalysis && analyticsData.projectAnalysis.byClient) ||
      (analyticsData.deliveryHealth && analyticsData.deliveryHealth.byClient) ||
      (derivedAnalytics && derivedAnalytics.projectByClient) ||
      [];

    return nextRows;
  }, [analyticsData, derivedAnalytics]);

  const projectAnalysisByProject = useMemo(() => {
    if (!analyticsData) {
      return [];
    }

    const nextRows =
      (analyticsData.projectAnalysis && analyticsData.projectAnalysis.byProject) ||
      (analyticsData.deliveryHealth && analyticsData.deliveryHealth.byProject) ||
      (derivedAnalytics && derivedAnalytics.projectByProject) ||
      [];

    return nextRows;
  }, [analyticsData, derivedAnalytics]);

  const fallbackResourceByUser = useMemo(() => {
    if (
      !analyticsData
      || !analyticsData.resourcePlanning
      || !analyticsData.resourcePlanning.demandHorizon
      || !analyticsData.resourcePlanning.demandHorizon.byUser
    ) {
      return derivedAnalytics ? derivedAnalytics.resourceByUser : [];
    }

    const demandByUser = analyticsData.resourcePlanning.demandHorizon.byUser;
    const workloadByUser =
      (analyticsData.resourcePlanning && analyticsData.resourcePlanning.workloadByUser) || [];
    const workloadById = new Map(workloadByUser.map((row) => [row.userId, row]));
    const dueIn30dTotal = demandByUser.reduce(
      (result, row) => result + (row.dueIn30d || 0),
      0,
    );
    const targetCardsPerUserIn30d =
      demandByUser.length > 0 ? dueIn30dTotal / demandByUser.length : 0;

    return demandByUser
      .map((demandRow) => {
        const workloadRow = workloadById.get(demandRow.userId) || {};
        const utilization =
          targetCardsPerUserIn30d > 0 ? (demandRow.dueIn30d || 0) / targetCardsPerUserIn30d : 0;
        let capacityStatus = 'balanced';

        if (targetCardsPerUserIn30d > 0) {
          if (utilization > 1.2) {
            capacityStatus = 'overCapacity';
          } else if (utilization < 0.6) {
            capacityStatus = 'underCapacity';
          }
        }

        return {
          userId: demandRow.userId,
          name: demandRow.name || workloadRow.name || 'Unknown',
          dueIn30d: demandRow.dueIn30d || 0,
          assignedCards: workloadRow.assignedCards || 0,
          capacityStatus,
        };
      })
      .sort(
        (a, b) =>
          b.dueIn30d - a.dueIn30d ||
          b.assignedCards - a.assignedCards ||
          a.name.localeCompare(b.name),
      );
  }, [analyticsData, derivedAnalytics]);
  const resourceCapacityByUser = useMemo(() => {
    if (!analyticsData) {
      return [];
    }

    const nextRows =
      (analyticsData.resourceAnalysis && analyticsData.resourceAnalysis.byUser) ||
      fallbackResourceByUser;

    return nextRows
      .map((row) => ({
        ...row,
        capacityStatus: row.capacityStatus || 'balanced',
      }));
  }, [analyticsData, fallbackResourceByUser]);

  const handlePrevMonth = useCallback(() => {
    setMilestonePopover(null);
    setDetailsPopover(null);
    setEditingMilestone(null);
    setViewingMonth((prev) => {
      if (prev === 0) {
        setViewingYear((y) => y - 1);
        return 11;
      }
      return prev - 1;
    });
  }, []);

  const handleNextMonth = useCallback(() => {
    setMilestonePopover(null);
    setDetailsPopover(null);
    setEditingMilestone(null);
    setViewingMonth((prev) => {
      if (prev === 11) {
        setViewingYear((y) => y + 1);
        return 0;
      }
      return prev + 1;
    });
  }, []);

  const handleToday = useCallback(() => {
    setMilestonePopover(null);
    setDetailsPopover(null);
    setEditingMilestone(null);
    setViewingMonth(today.getMonth());
    setViewingYear(today.getFullYear());
  }, [today]);

  const isCurrentMonth = viewingMonth === today.getMonth() && viewingYear === today.getFullYear();

  const calendarData = useMemo(() => {
    const year = viewingYear;
    const month = viewingMonth;
    const firstDay = new Date(year, month, 1).getDay();
    const totalDays = new Date(year, month + 1, 0).getDate();
    const cells = Array(firstDay).fill(null);
    const now = new Date();

    if (calendarView === 'tasks') {
      const dueCardsByDay = {};

      effectiveCalendarDueCards.forEach((card) => {
        const dueDate = card.dueDate instanceof Date ? card.dueDate : new Date(card.dueDate);

        if (Number.isNaN(dueDate.getTime())) {
          return;
        }

        if (dueDate.getFullYear() !== year || dueDate.getMonth() !== month) {
          return;
        }

        const day = dueDate.getDate();
        const isCompleted = !!card.isDueDateCompleted;
        const isOverdue = !isCompleted && dueDate.getTime() < now.getTime();

        if (!dueCardsByDay[day]) {
          dueCardsByDay[day] = [];
        }

        dueCardsByDay[day].push({
          id: card.id,
          name: card.name,
          projectName: card.projectName,
          isCompleted,
          isOverdue,
        });
      });

      for (let day = 1; day <= totalDays; day += 1) {
        cells.push({
          day,
          dueCards: dueCardsByDay[day] || [],
          milestones: [],
        });
      }

      const totalDueCards = effectiveCalendarDueCards.filter((card) => {
        const dueDate = card.dueDate instanceof Date ? card.dueDate : new Date(card.dueDate);
        return (
          !Number.isNaN(dueDate.getTime()) &&
          dueDate.getFullYear() === year &&
          dueDate.getMonth() === month
        );
      }).length;

      return { cells, totalDueCards, totalMilestones: 0 };
    }

    // Projects view - show milestones
    const milestonesByDay = {};

    calendarMilestones.forEach((ms) => {
      const dueDate = ms.dueDate instanceof Date ? ms.dueDate : new Date(ms.dueDate);

      if (Number.isNaN(dueDate.getTime())) {
        return;
      }

      if (dueDate.getFullYear() !== year || dueDate.getMonth() !== month) {
        return;
      }

      const day = dueDate.getDate();

      if (!milestonesByDay[day]) {
        milestonesByDay[day] = [];
      }

      milestonesByDay[day].push({
        id: ms.id,
        name: ms.name,
        boardName: ms.boardName,
        boardId: ms.boardId,
        projectName: ms.projectName,
        isOverdue: dueDate.getTime() < now.getTime(),
      });
    });

    for (let day = 1; day <= totalDays; day += 1) {
      cells.push({
        day,
        dueCards: [],
        milestones: milestonesByDay[day] || [],
      });
    }

    const totalMilestones = calendarMilestones.filter((ms) => {
      const dueDate = ms.dueDate instanceof Date ? ms.dueDate : new Date(ms.dueDate);
      return (
        !Number.isNaN(dueDate.getTime()) &&
        dueDate.getFullYear() === year &&
        dueDate.getMonth() === month
      );
    }).length;

    return { cells, totalDueCards: 0, totalMilestones };
  }, [effectiveCalendarDueCards, calendarMilestones, viewingMonth, viewingYear, calendarView]);

  const monthLabel = useMemo(() =>
    new Intl.DateTimeFormat(undefined, {
      month: 'long',
      year: 'numeric',
    }).format(new Date(viewingYear, viewingMonth, 1)),
  [viewingMonth, viewingYear]);

  const weekDays = useMemo(() =>
    Array.from({ length: 7 }, (_, dayIndex) =>
      new Intl.DateTimeFormat(undefined, { weekday: 'short' }).format(
        new Date(2026, 1, 15 + dayIndex),
      ),
    ),
  []);

  const todayDay = isCurrentMonth ? today.getDate() : -1;

  const handleCellClick = useCallback((dayData) => {
    if (!dayData) {
      return;
    }

    const hasDueCards = dayData.dueCards && dayData.dueCards.length > 0;
    const hasMilestones = dayData.milestones && dayData.milestones.length > 0;

    setMilestonePopover(null);
    setEditingMilestone(null);

    if (calendarView === 'tasks' && hasDueCards) {
      setDetailsPopover({
        day: dayData.day,
        type: 'tasks',
        items: dayData.dueCards,
      });
      return;
    }

    if (calendarView === 'projects' && hasMilestones) {
      setDetailsPopover({
        day: dayData.day,
        type: 'projects',
        items: dayData.milestones,
      });
      return;
    }

    setDetailsPopover(null);

    if (calendarView === 'projects') {
      setMilestonePopover({ day: dayData.day });
      setMilestoneForm({ projectId: '', boardId: '', name: '' });
    }
  }, [calendarView]);

  const handleMilestoneClick = useCallback((e, milestone, day) => {
    e.stopPropagation();
    setDetailsPopover(null);
    setMilestonePopover({ day });
    setEditingMilestone(milestone);
    setEditForm({
      name: milestone.name,
      dueDate: new Date(viewingYear, viewingMonth, day).toISOString().split('T')[0],
    });
  }, [viewingYear, viewingMonth]);

  const boardsForSelectedProject = useMemo(() => {
    if (!milestoneForm.projectId || !projectsToLists) return [];
    const project = projectsToLists.find((p) => p.id === milestoneForm.projectId);
    return project ? project.boards : [];
  }, [milestoneForm.projectId, projectsToLists]);

  const handleCreateMilestone = useCallback(async () => {
    if (!milestoneForm.boardId || !milestoneForm.name || !milestonePopover) return;

    const dueDate = new Date(viewingYear, viewingMonth, milestonePopover.day, 12, 0, 0);

    try {
      await api.createBoardMilestone(milestoneForm.boardId, {
        name: milestoneForm.name,
        dueDate: dueDate.toISOString(),
      });
      setMilestonePopover(null);
      setDetailsPopover(null);
      setMilestoneForm({ projectId: '', boardId: '', name: '' });
      // Force re-render by reloading
      window.location.reload();
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error('Failed to create milestone:', err);
    }
  }, [milestoneForm, milestonePopover, viewingYear, viewingMonth]);

  const handleUpdateMilestone = useCallback(async () => {
    if (!editingMilestone || !editForm.name) return;

    try {
      await api.updateBoardMilestone(editingMilestone.id, {
        name: editForm.name,
        ...(editForm.dueDate && { dueDate: new Date(editForm.dueDate).toISOString() }),
      });
      setEditingMilestone(null);
      setMilestonePopover(null);
      setDetailsPopover(null);
      window.location.reload();
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error('Failed to update milestone:', err);
    }
  }, [editingMilestone, editForm]);

  const handleDeleteMilestone = useCallback(async () => {
    if (!editingMilestone) return;

    try {
      await api.deleteBoardMilestone(editingMilestone.id);
      setEditingMilestone(null);
      setMilestonePopover(null);
      setDetailsPopover(null);
      window.location.reload();
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error('Failed to delete milestone:', err);
    }
  }, [editingMilestone]);

  const handleEditClick = useCallback(
    (e, item) => {
      e.preventDefault();
      e.stopPropagation();
      const projectPath = item.firstBoardId
        ? Paths.BOARDS.replace(':id', item.firstBoardId)
        : Paths.PROJECTS.replace(':id', item.id);
      navigate(projectPath);
      onEditProject();
    },
    [navigate, onEditProject],
  );

  return (
    <Container className={styles.cardsWrapper}>
      <Grid className={styles.gridFix}>
        {items.map((item) => (
          <Grid.Column key={item.id} mobile={8} computer={4}>
            <Link
              to={
                item.firstBoardId
                  ? Paths.BOARDS.replace(':id', item.firstBoardId)
                  : Paths.PROJECTS.replace(':id', item.id)
              }
            >
              <div
                className={classNames(
                  styles.card,
                  styles.open,
                  item.background &&
                    item.background.type === ProjectBackgroundTypes.GRADIENT &&
                    globalStyles[`background${upperFirst(camelCase(item.background.name))}`],
                )}
                style={{
                  background:
                    item.background &&
                    item.background.type === 'image' &&
                    `url("${item.backgroundImage.coverUrl}") center / cover`,
                }}
              >
                {item.notificationsTotal > 0 && (
                  <span className={styles.notification}>{item.notificationsTotal}</span>
                )}
                <div className={styles.pastelTint} />
                <div className={styles.cardOverlay} />
                {isAdmin && (
                  <button
                    type="button"
                    className={styles.editButton}
                    onClick={(e) => handleEditClick(e, item)}
                    title={t('action.archiveProject', { context: 'title' })}
                  >
                    <Icon fitted name="pencil" className={styles.editIcon} />
                  </button>
                )}
                <div className={styles.openTitle}>{item.name}</div>
              </div>
            </Link>
          </Grid.Column>
        ))}
        {canAdd && (
          <Grid.Column mobile={8} computer={4}>
            <button type="button" className={classNames(styles.card, styles.add)} onClick={onAdd}>
              <div className={styles.addTitleWrapper}>
                <div className={styles.addTitle}>
                  <PlusIcon className={styles.addGridIcon} />
                  {t('action.createProject')}
                </div>
              </div>
            </button>
          </Grid.Column>
        )}
      </Grid>
      {analyticsKpis.length > 0 && (
        <section className={styles.analyticsSummary} aria-label="Analytics summary">
          <div className={styles.analyticsHeader}>
            <h2 className={styles.analyticsTitle}>Analytics Summary</h2>
            <span className={styles.analyticsMeta}>
              {analyticsData
                && analyticsData.scope
                && analyticsData.scope.windowDays
                ? `Last ${analyticsData.scope.windowDays} days`
                : 'Last 30 days'}
            </span>
          </div>
          <div className={styles.analyticsKpiGrid}>
            {analyticsKpis.map((metric) => (
              <div key={metric.label} className={styles.analyticsKpiCard}>
                <div className={styles.analyticsKpiValue}>{metric.value}</div>
                <div className={styles.analyticsKpiLabel}>{metric.label}</div>
              </div>
            ))}
          </div>
          <div className={styles.analyticsInsights}>
            <div className={classNames(styles.analyticsPanel, styles.analyticsPanelScrollable)}>
              <h3 className={styles.analyticsPanelTitle}>Project Analysis by Client</h3>
              {projectAnalysisByClient.length === 0 && (
                <p className={styles.analyticsEmpty}>No client project analysis available.</p>
              )}
              {projectAnalysisByClient.length > 0 && (
                <div className={styles.analyticsRowsScrollable}>
                  {projectAnalysisByClient.map((client) => (
                    <div key={client.clientId} className={styles.analyticsRow}>
                      <span className={styles.analyticsRowName}>{client.clientName}</span>
                      <span className={styles.analyticsRowValue}>
                        Blocked {client.blockedCards}
                        {' | '}
                        Due soon {client.dueSoon7d}
                        {' | '}
                        Overdue {client.overdueCards}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </div>
            <div className={classNames(styles.analyticsPanel, styles.analyticsPanelScrollable)}>
              <h3 className={styles.analyticsPanelTitle}>Project Analysis by Project</h3>
              {projectAnalysisByProject.length === 0 && (
                <p className={styles.analyticsEmpty}>No project-level analysis available.</p>
              )}
              {projectAnalysisByProject.length > 0 && (
                <div className={styles.analyticsRowsScrollable}>
                  {projectAnalysisByProject.map((project) => (
                    <div key={project.projectId} className={styles.analyticsRow}>
                      <span className={styles.analyticsRowName}>
                        {project.projectName}
                      </span>
                      <span className={styles.analyticsRowValue}>
                        Blocked {project.blockedCards}
                        {' | '}
                        Due soon {project.dueSoon7d}
                        {' | '}
                        Overdue {project.overdueCards}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </div>
            <div className={classNames(styles.analyticsPanel, styles.analyticsPanelScrollable)}>
              <h3 className={styles.analyticsPanelTitle}>Resource Capacity by User</h3>
              {resourceCapacityByUser.length === 0 && (
                <p className={styles.analyticsEmpty}>No user capacity pressure detected.</p>
              )}
              {resourceCapacityByUser.length > 0 && (
                <div className={styles.analyticsRowsScrollable}>
                  {resourceCapacityByUser.map((user) => (
                    <div key={user.userId} className={styles.analyticsRow}>
                      <span className={styles.analyticsRowName}>{user.name}</span>
                      <span className={styles.analyticsRowValue}>
                        {formatCapacityStatus(user.capacityStatus)}
                        {' | '}
                        {user.assignedCards || 0} assigned
                        {' | '}
                        {user.dueIn30d || 0} due 30d
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </section>
      )}
      <section className={styles.teamCalendar} aria-label="Team calendar">
        <div className={styles.calendarHeader}>
          <h2 className={styles.calendarTitle}>Team Calendar</h2>
          <div className={styles.calendarNav}>
            <button
              type="button"
              className={styles.navButton}
              onClick={handlePrevMonth}
              title="Previous month"
            >
              <Icon name="chevron left" />
            </button>
            <span className={styles.calendarMonth}>{monthLabel}</span>
            <button
              type="button"
              className={styles.navButton}
              onClick={handleNextMonth}
              title="Next month"
            >
              <Icon name="chevron right" />
            </button>
            {!isCurrentMonth && (
              <button type="button" className={styles.todayButton} onClick={handleToday}>
                Today
              </button>
            )}
          </div>
        </div>
        <div className={styles.viewToggle}>
          <button
            type="button"
            className={classNames(
              styles.viewTab,
              calendarView === 'projects' && styles.viewTabActive,
            )}
            onClick={() => {
              setCalendarView('projects');
              setMilestonePopover(null);
              setDetailsPopover(null);
              setEditingMilestone(null);
            }}
          >
            <Icon name="flag" />
            Projects
          </button>
          <button
            type="button"
            className={classNames(
              styles.viewTab,
              calendarView === 'tasks' && styles.viewTabActive,
            )}
            onClick={() => {
              setCalendarView('tasks');
              setMilestonePopover(null);
              setDetailsPopover(null);
              setEditingMilestone(null);
            }}
          >
            <Icon name="tasks" />
            Tasks
          </button>
        </div>
        <div className={styles.calendarGrid} role="grid">
          {weekDays.map((weekDay) => (
            <div key={weekDay} className={styles.weekDay}>
              {weekDay}
            </div>
          ))}
          {calendarData.cells.map((day, index) => {
            const key = day ? `day-${day.day}` : `empty-${index}`;
            const isToday = day && day.day === todayDay;
            const dueCards = day ? day.dueCards : [];
            const milestones = day ? day.milestones : [];
            const hasDueCards = dueCards.length > 0;
            const hasMilestones = milestones.length > 0;
            const hasOverdueCards = dueCards.some((card) => card.isOverdue);
            const hasOverdueMilestones = milestones.some((ms) => ms.isOverdue);
            const isPopoverDay = milestonePopover && day && milestonePopover.day === day.day;
            const isDetailsPopoverDay =
              detailsPopover &&
              day &&
              detailsPopover.day === day.day &&
              detailsPopover.type === calendarView;

            let title;
            if (calendarView === 'tasks' && hasDueCards) {
              title = dueCards
                .slice(0, 3)
                .map(
                  (card) =>
                    `${card.name}${card.projectName ? ` (${card.projectName})` : ''}${
                      card.isOverdue ? ' - overdue' : ''
                    }`,
                )
                .concat(dueCards.length > 3 ? [`+${dueCards.length - 3} more`] : [])
                .join('\n');
            } else if (calendarView === 'projects' && hasMilestones) {
              title = milestones
                .slice(0, 3)
                .map((ms) => `${ms.name} (${ms.boardName})`)
                .concat(milestones.length > 3 ? [`+${milestones.length - 3} more`] : [])
                .join('\n');
            }

            const isClickable =
              day &&
              ((calendarView === 'tasks' && hasDueCards) || calendarView === 'projects');
            const cellProps = isClickable ? {
              onClick: () => handleCellClick(day),
              onKeyDown: (e) => {
                if (e.key === 'Enter' || e.key === ' ') {
                  handleCellClick(day);
                }
              },
              role: 'button',
              tabIndex: 0,
            } : {};

            return (
              <div
                key={key}
                className={classNames(
                  styles.calendarCell,
                  isToday && styles.today,
                  hasDueCards && calendarView === 'tasks'
                    && styles.hasDueCards,
                  hasOverdueCards && calendarView === 'tasks'
                    && styles.hasOverdueCards,
                  hasMilestones && calendarView === 'projects'
                    && styles.hasMilestones,
                  hasOverdueMilestones
                    && calendarView === 'projects'
                    && styles.hasOverdueCards,
                  isClickable && styles.clickableCell,
                )}
                title={title}
                {...cellProps} // eslint-disable-line react/jsx-props-no-spreading
              >
                {day ? (
                  <>
                    <span className={styles.dayNumber}>{day.day}</span>
                    {calendarView === 'tasks' && hasDueCards && (
                      <span className={styles.dueCount}>{dueCards.length}</span>
                    )}
                    {calendarView === 'projects' && hasMilestones && (
                      <div className={styles.milestoneIndicators}>
                        {milestones.slice(0, 2).map((ms) => (
                          <button
                            key={ms.id}
                            type="button"
                            className={styles.milestoneChip}
                            onClick={(e) => handleMilestoneClick(e, ms, day.day)}
                            title={`${ms.name} (${ms.boardName})`}
                          >
                            <Icon name="flag" size="small" />
                            <span className={styles.milestoneChipText}>{ms.name}</span>
                          </button>
                        ))}
                        {milestones.length > 2 && (
                          <span className={styles.milestoneMore}>+{milestones.length - 2}</span>
                        )}
                      </div>
                    )}
                    {isDetailsPopoverDay && (
                      // eslint-disable-next-line jsx-a11y/no-noninteractive-element-interactions
                      <div
                        className={styles.milestonePopover}
                        ref={popoverRef}
                        role="dialog"
                        onClick={(e) => e.stopPropagation()}
                        onKeyDown={(e) => e.stopPropagation()}
                      >
                        <div className={styles.popoverTitle}>
                          {calendarView === 'tasks' ? 'Due Tasks' : 'Project Milestones'}
                          {' - '}
                          {day.day}
                        </div>
                        {detailsPopover.items.map((item) => (
                          <div key={item.id} className={styles.popoverDetailItem}>
                            <Link
                              to={
                                calendarView === 'tasks'
                                  ? Paths.CARDS.replace(':id', item.id)
                                  : Paths.BOARDS.replace(':id', item.boardId)
                              }
                              className={styles.popoverDetailLink}
                              onClick={() => setDetailsPopover(null)}
                            >
                              {item.name}
                            </Link>
                            <div className={styles.popoverDetailMeta}>
                              {calendarView === 'tasks'
                                ? item.projectName || 'No project'
                                : `${item.projectName || 'No project'} (${item.boardName})`}
                            </div>
                          </div>
                        ))}
                        <div className={styles.popoverActions}>
                          {calendarView === 'projects' && (
                            <button
                              type="button"
                              className={styles.popoverSave}
                              onClick={() => {
                                setDetailsPopover(null);
                                setEditingMilestone(null);
                                setMilestonePopover({ day: day.day });
                                setMilestoneForm({ projectId: '', boardId: '', name: '' });
                              }}
                            >
                              Add Milestone
                            </button>
                          )}
                          <button
                            type="button"
                            className={styles.popoverCancel}
                            onClick={() => setDetailsPopover(null)}
                          >
                            Close
                          </button>
                        </div>
                      </div>
                    )}
                    {isPopoverDay && (
                      // eslint-disable-next-line jsx-a11y/no-noninteractive-element-interactions
                      <div
                        className={styles.milestonePopover}
                        ref={popoverRef}
                        role="dialog"
                        onClick={(e) => e.stopPropagation()}
                        onKeyDown={(e) => e.stopPropagation()}
                      >
                        {editingMilestone ? (
                          <>
                            <div className={styles.popoverTitle}>Edit Milestone</div>
                            <input
                              type="text"
                              className={styles.popoverInput}
                              value={editForm.name}
                              onChange={(e) => setEditForm((f) => ({ ...f, name: e.target.value }))}
                              placeholder="Milestone name"
                            />
                            <input
                              type="date"
                              className={styles.popoverInput}
                              value={editForm.dueDate}
                              onChange={(e) => setEditForm(
                                (f) => ({ ...f, dueDate: e.target.value }),
                              )}
                            />
                            <div className={styles.popoverActions}>
                              <button
                                type="button"
                                className={styles.popoverSave}
                                onClick={handleUpdateMilestone}
                              >
                                Save
                              </button>
                              <button
                                type="button"
                                className={styles.popoverDelete}
                                onClick={handleDeleteMilestone}
                              >
                                Delete
                              </button>
                              <button
                                type="button"
                                className={styles.popoverCancel}
                                onClick={() => {
                                  setEditingMilestone(null);
                                  setMilestonePopover(null);
                                }}
                              >
                                Cancel
                              </button>
                            </div>
                          </>
                        ) : (
                          <>
                            <div className={styles.popoverTitle}>Add Milestone</div>
                            <select
                              className={styles.popoverSelect}
                              value={milestoneForm.projectId}
                              onChange={(e) => setMilestoneForm(
                                (f) => ({
                                  ...f,
                                  projectId: e.target.value,
                                  boardId: '',
                                }),
                              )}
                            >
                              <option value="">Select Client</option>
                              {projectsToLists && projectsToLists.map((p) => (
                                <option key={p.id} value={p.id}>{p.name}</option>
                              ))}
                            </select>
                            <select
                              className={styles.popoverSelect}
                              value={milestoneForm.boardId}
                              onChange={(e) => setMilestoneForm(
                                (f) => ({ ...f, boardId: e.target.value }),
                              )}
                              disabled={!milestoneForm.projectId}
                            >
                              <option value="">Select Board</option>
                              {boardsForSelectedProject.map((b) => (
                                <option key={b.id} value={b.id}>{b.name}</option>
                              ))}
                            </select>
                            <input
                              type="text"
                              className={styles.popoverInput}
                              value={milestoneForm.name}
                              onChange={(e) => setMilestoneForm(
                                (f) => ({ ...f, name: e.target.value }),
                              )}
                              placeholder="Milestone name"
                            />
                            <div className={styles.popoverActions}>
                              <button
                                type="button"
                                className={styles.popoverSave}
                                onClick={handleCreateMilestone}
                                disabled={!milestoneForm.boardId || !milestoneForm.name}
                              >
                                Create
                              </button>
                              <button
                                type="button"
                                className={styles.popoverCancel}
                                onClick={() => setMilestonePopover(null)}
                              >
                                Cancel
                              </button>
                            </div>
                          </>
                        )}
                      </div>
                    )}
                  </>
                ) : null}
              </div>
            );
          })}
        </div>
        <p className={styles.calendarNote}>
          {calendarView === 'tasks'
            ? `Shared monthly view. ${calendarData.totalDueCards} due this month.`
            : `Project milestones. ${calendarData.totalMilestones} `
              + `milestone${calendarData.totalMilestones !== 1 ? 's' : ''}`
              + ' this month. Click a date to view details or add one.'
          }
        </p>
      </section>
    </Container>
  );
  },
);

Projects.propTypes = {
  items: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  calendarDueCards: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  calendarMilestones: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  projectsToLists: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  canAdd: PropTypes.bool.isRequired,
  isAdmin: PropTypes.bool.isRequired,
  onAdd: PropTypes.func.isRequired,
  onEditProject: PropTypes.func.isRequired,
};

export default Projects;
