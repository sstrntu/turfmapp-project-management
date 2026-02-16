const Errors = {
  NOT_ENOUGH_RIGHTS: {
    notEnoughRights: 'Not enough rights',
  },
  ARCHIVE_NOT_FOUND: {
    archiveNotFound: 'Archived card not found',
  },
};

module.exports = {
  inputs: {
    id: {
      type: 'string',
      regex: /^[0-9]+$/,
      required: true,
    },
    listId: {
      type: 'string',
      regex: /^[0-9]+$/,
      required: true,
    },
  },

  exits: {
    notEnoughRights: {
      responseType: 'forbidden',
    },
    archiveNotFound: {
      responseType: 'notFound',
    },
  },

  async fn(inputs) {
    const { currentUser } = this.req;

    // Find the archive record
    const archive = await Archive.findOne({
      id: inputs.id,
      fromModel: 'card',
    });

    if (!archive) {
      throw Errors.ARCHIVE_NOT_FOUND;
    }

    // Get the list to restore to
    const list = await List.findOne(inputs.listId);
    if (!list) {
      throw Errors.ARCHIVE_NOT_FOUND;
    }

    // Get the board and project for permission check
    const board = await Board.findOne(list.boardId);
    if (!board) {
      throw Errors.ARCHIVE_NOT_FOUND;
    }

    const project = await Project.findOne(board.projectId);
    if (!project) {
      throw Errors.ARCHIVE_NOT_FOUND;
    }

    // Check if user has access to the board
    const boardMembership = await BoardMembership.findOne({
      boardId: board.id,
      userId: currentUser.id,
    });

    if (!boardMembership) {
      throw Errors.ARCHIVE_NOT_FOUND; // Forbidden
    }

    if (boardMembership.role !== BoardMembership.Roles.EDITOR) {
      throw Errors.NOT_ENOUGH_RIGHTS;
    }

    // Restore the card
    const card = await sails.helpers.cards.restoreOne.with({
      archiveId: inputs.id,
      project,
      board,
      list,
      actorUser: currentUser,
      request: this.req,
    });

    if (!card) {
      throw Errors.ARCHIVE_NOT_FOUND;
    }

    return {
      item: card,
    };
  },
};
