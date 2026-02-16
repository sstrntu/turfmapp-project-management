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

    // Only admins can permanently delete
    const user = await User.findOne(currentUser.id);
    if (!user || !user.isAdmin) {
      throw Errors.NOT_ENOUGH_RIGHTS;
    }

    // Permanently delete the project
    const result = await sails.helpers.projects.permanentDeleteOne.with({
      archiveId: inputs.id,
      actorUser: currentUser,
    });

    return result;
  },
};
