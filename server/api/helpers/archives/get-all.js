module.exports = {
  inputs: {
    fromModel: {
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
    userId: {
      type: 'string',
    },
  },

  async fn(inputs) {
    const criteria = {};

    // Filter by model type if specified
    if (inputs.fromModel) {
      criteria.fromModel = inputs.fromModel;
    }

    // Calculate pagination
    const offset = (inputs.page - 1) * inputs.limit;

    // Query archives with pagination
    const archives = await Archive.find(criteria)
      .limit(inputs.limit)
      .skip(offset)
      .sort('updatedAt DESC');

    // Get total count
    const total = await Archive.count(criteria);

    // Parse and format the archived records
    const items = archives.map((archive) => ({
      id: archive.id,
      archiveId: archive.id,
      originalId: archive.originalRecordId,
      modelType: archive.fromModel,
      name: archive.originalRecord.name,
      archivedAt: archive.createdAt,
      originalRecord: archive.originalRecord,
    }));

    return {
      items,
      total,
      page: inputs.page,
      limit: inputs.limit,
      pages: Math.ceil(total / inputs.limit),
    };
  },
};
