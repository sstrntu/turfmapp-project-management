const Errors = {
  BOARD_NOT_FOUND: {
    boardNotFound: 'Board not found',
  },
  NOT_ENOUGH_RIGHTS: {
    notEnoughRights: 'Not enough rights',
  },
};

module.exports = {
  inputs: {
    boardId: {
      type: 'string',
      regex: /^[0-9]+$/,
      required: true,
    },
    name: {
      type: 'string',
      required: true,
    },
    dueDate: {
      type: 'string',
      required: true,
    },
  },

  exits: {
    boardNotFound: {
      responseType: 'notFound',
    },
    notEnoughRights: {
      responseType: 'forbidden',
    },
  },

  async fn(inputs) {
    const { currentUser } = this.req;

    const board = await Board.findOne({ id: inputs.boardId });

    if (!board) {
      throw Errors.BOARD_NOT_FOUND;
    }

    const boardMembership = await BoardMembership.findOne({
      boardId: board.id,
      userId: currentUser.id,
    });

    if (!boardMembership) {
      throw Errors.BOARD_NOT_FOUND;
    }

    const milestone = await BoardMilestone.create({
      name: inputs.name,
      dueDate: new Date(inputs.dueDate),
      boardId: board.id,
    }).fetch();

    return {
      item: milestone,
    };
  },
};
