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
    name: {
      type: 'string',
    },
    dueDate: {
      type: 'string',
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

    const values = {};
    if (inputs.name !== undefined) {
      values.name = inputs.name;
    }
    if (inputs.dueDate !== undefined) {
      values.dueDate = new Date(inputs.dueDate);
    }

    const updated = await BoardMilestone.updateOne({ id: inputs.id }).set(values);

    if (!updated) {
      throw Errors.MILESTONE_NOT_FOUND;
    }

    return {
      item: updated,
    };
  },
};
