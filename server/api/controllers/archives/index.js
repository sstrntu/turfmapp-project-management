const Errors = {
  NOT_AUTHENTICATED: {
    notAuthenticated: 'Not authenticated',
  },
};

module.exports = {
  inputs: {
    type: {
      type: 'string',
      example: 'card',
    },
    page: {
      type: 'number',
      defaultsTo: 1,
    },
    limit: {
      type: 'number',
      defaultsTo: 50,
    },
  },

  exits: {
    notAuthenticated: {
      responseType: 'unauthorized',
    },
  },

  async fn(inputs) {
    const { currentUser } = this.req;

    if (!currentUser) {
      throw Errors.NOT_AUTHENTICATED;
    }

    // Get archived items
    const archives = await sails.helpers.archives.getAll.with({
      fromModel: inputs.type,
      page: inputs.page,
      limit: inputs.limit,
      userId: currentUser.id,
    });

    return archives;
  },
};
