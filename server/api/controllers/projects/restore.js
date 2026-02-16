const Errors = {
  NOT_ENOUGH_RIGHTS: {
    notEnoughRights: 'Not enough rights',
  },
  ARCHIVE_NOT_FOUND: {
    archiveNotFound: 'Archived project not found',
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
      fromModel: 'project',
    });

    if (!archive) {
      throw Errors.ARCHIVE_NOT_FOUND;
    }

    // Only project managers (now admins) can restore projects
    const user = await User.findOne(currentUser.id);
    if (!user || !user.isAdmin) {
      throw Errors.NOT_ENOUGH_RIGHTS;
    }

    // Restore the project
    const project = await sails.helpers.projects.restoreOne.with({
      archiveId: inputs.id,
      actorUser: currentUser,
      request: this.req,
    });

    if (!project) {
      throw Errors.ARCHIVE_NOT_FOUND;
    }

    return {
      item: project,
    };
  },
};
