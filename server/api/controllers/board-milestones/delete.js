const Errors = {
  MILESTONE_NOT_FOUND: {
    milestoneNotFound: 'Milestone not found',
  },
  NOT_ENOUGH_RIGHTS: {
    notEnoughRights: 'Not enough rights',
  },
};

module.exports = {
  inputs: {
    id: {
      type: 'string',
      regex: /^[0-9]+$/,
      required: true,
    },
  },

  exits: {
    milestoneNotFound: {
      responseType: 'notFound',
    },
    notEnoughRights: {
      responseType: 'forbidden',
    },
  },

  async fn(inputs) {
    const { currentUser } = this.req;

    const milestone = await BoardMilestone.findOne({ id: inputs.id });

    if (!milestone) {
      throw Errors.MILESTONE_NOT_FOUND;
    }

    const boardMembership = await BoardMembership.findOne({
      boardId: milestone.boardId,
      userId: currentUser.id,
    });

    if (!boardMembership) {
      throw Errors.MILESTONE_NOT_FOUND;
    }

    const deleted = await BoardMilestone.destroyOne({ id: inputs.id });

    if (!deleted) {
      throw Errors.MILESTONE_NOT_FOUND;
    }

    return {
      item: deleted,
    };
  },
};
