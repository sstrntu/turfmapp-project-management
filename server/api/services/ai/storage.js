const { v4: uuid } = require('uuid');

const MAX_HISTORY_ITEMS = 200;

const normalizeSessionId = (sessionId) => {
  if (!_.isString(sessionId)) {
    return null;
  }

  const trimmed = sessionId.trim();

  return trimmed || null;
};

const normalizeContent = (content) => {
  if (_.isString(content)) {
    return content.trim();
  }

  if (_.isNil(content)) {
    return '';
  }

  return String(content);
};

const normalizeMetadata = (metadata) => (_.isPlainObject(metadata) ? metadata : {});

const normalizeContext = (context) => {
  if (_.isString(context)) {
    try {
      const parsed = JSON.parse(context);

      return _.isPlainObject(parsed) ? parsed : {};
    } catch (error) {
      return {};
    }
  }

  return _.isPlainObject(context) ? context : {};
};

const toIsoDateString = (value) => {
  if (!value) {
    return new Date().toISOString();
  }

  if (_.isDate(value)) {
    return value.toISOString();
  }

  const parsed = new Date(value);

  if (!Number.isNaN(parsed.getTime())) {
    return parsed.toISOString();
  }

  return String(value);
};

const serializeMessage = (messageRecord) => ({
  id: String(messageRecord.id),
  role: messageRecord.role,
  content: messageRecord.content,
  metadata: messageRecord.metadata || {},
  createdAt: toIsoDateString(messageRecord.createdAt),
});

const findSession = async ({ userId, channel, sessionId }) => {
  const normalizedSessionId = normalizeSessionId(sessionId);

  if (!normalizedSessionId) {
    return null;
  }

  return AiSession.findOne({
    publicId: normalizedSessionId,
    userId,
    channel,
  });
};

const upsertSession = async ({ userId, channel, sessionId, context = {} }) => {
  const normalizedContext = normalizeContext(context);
  const normalizedSessionId = normalizeSessionId(sessionId) || uuid();

  let session = await findSession({
    userId,
    channel,
    sessionId: normalizedSessionId,
  });

  if (!session) {
    session = await AiSession.create({
      publicId: normalizedSessionId,
      userId,
      channel,
      context: _.isEmpty(normalizedContext) ? null : normalizedContext,
    }).fetch();

    return session;
  }

  if (!_.isEmpty(normalizedContext)) {
    session = await AiSession.updateOne({
      id: session.id,
    }).set({
      context: normalizedContext,
    });
  }

  return session;
};

const createSessionId = () => uuid();

const addHistoryTurn = async ({
  userId,
  channel,
  sessionId,
  role,
  content,
  metadata = {},
  context = {},
}) => {
  const normalizedContent = normalizeContent(content);

  if (!normalizedContent) {
    return null;
  }

  const session = await upsertSession({
    userId,
    channel,
    sessionId,
    context,
  });

  const message = await AiMessage.create({
    aiSessionId: session.id,
    role,
    content: normalizedContent,
    metadata: normalizeMetadata(metadata),
  }).fetch();

  return serializeMessage(message);
};

const getHistory = async ({ userId, channel, sessionId }) => {
  const session = await findSession({
    userId,
    channel,
    sessionId,
  });

  if (!session) {
    return [];
  }

  const newestFirst = await AiMessage.find({
    aiSessionId: session.id,
  })
    .sort('id DESC')
    .limit(MAX_HISTORY_ITEMS);

  return newestFirst.reverse().map(serializeMessage);
};

const storePlan = async ({ userId, channel, sessionId, message, actions, context = {} }) => {
  const session = await upsertSession({
    userId,
    channel,
    sessionId,
    context,
  });

  const planId = uuid();

  await AiPlan.create({
    publicId: planId,
    aiSessionId: session.id,
    userId,
    channel,
    message: _.isString(message) ? message : String(message || ''),
    actions: Array.isArray(actions) ? actions : [],
    context: normalizeContext(context),
    status: AiPlan.Statuses.PENDING,
  });

  return planId;
};

const getPlan = async (planId) => {
  if (!_.isString(planId) || !planId.trim()) {
    return null;
  }

  const plan = await AiPlan.findOne({
    publicId: planId,
  });

  if (!plan) {
    return null;
  }

  const session = await AiSession.findOne({
    id: plan.aiSessionId,
  });

  return {
    id: plan.publicId,
    userId: plan.userId,
    channel: plan.channel,
    sessionId: session ? session.publicId : null,
    message: plan.message,
    actions: Array.isArray(plan.actions) ? plan.actions : [],
    context: normalizeContext(plan.context),
    status: plan.status,
    createdAt: toIsoDateString(plan.createdAt),
  };
};

const deletePlan = async (planId, data = {}) => {
  if (!_.isString(planId) || !planId.trim()) {
    return;
  }

  await AiPlan.update({
    publicId: planId,
  }).set({
    status: data.status || AiPlan.Statuses.CONSUMED,
    executionResults: data.executionResults || null,
  });
};

module.exports = {
  addHistoryTurn,
  getHistory,
  createSessionId,
  storePlan,
  getPlan,
  deletePlan,
};
