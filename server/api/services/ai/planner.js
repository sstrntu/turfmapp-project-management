const { v4: uuid } = require('uuid');

const openaiService = require('./openai');
const scopeService = require('./scope');
const { ACTION_TYPES, DESTRUCTIVE_ACTION_TYPES, MAX_ACTIONS_PER_REQUEST } = require('./constants');

const SUPPORTED_ACTIONS = new Set(Object.values(ACTION_TYPES));

const SYSTEM_PROMPT = `You are an AI operations planner for a project management app.
You must produce strict JSON with:
{
  "assistantMessage": "string",
  "actions": [
    {
      "type": "create_card|update_card|move_card|archive_card|delete_card|create_list|update_list|delete_list",
      "args": { "..." : "..." },
      "reason": "string"
    }
  ]
}

Rules:
- Only include actions that were explicitly or strongly implied by user intent.
- Never invent entity names that are not present in accessible context unless the action is to create a new entity.
- Authorized workspace context always includes a JSON payload. Use it as the source of truth.
- User directory is provided under context "users" and may include each user's skills.
- User entries may include activeCards (current workload/capacity signal).
- If context.users is non-empty, do not claim you lack access to user/skill data.
- If context.users is empty, then you may ask the user for missing user/skill details.
- For existing entities, pass name fields:
  card operations: cardName, optional listName, boardName, projectName.
  list operations: listName, optional boardName, projectName.
  create_card requires cardName and listName (if user gave one).
  move_card requires cardName and targetListName.
  update_card can use:
    - changes object for direct card fields only: name, description, dueDate, color, isDueDateCompleted
    - labelNames (array of strings) to add labels
    - assigneeNames (array of user names/emails/usernames or skill tags) to add assignees
- When assigning, prefer users whose skills match the requested work, then prefer lower activeCards.
  create_list requires listName and boardName when available.
- For bulk decomposition (long note/photo/audio), return multiple create_card actions.
- Keep actions under 50.
- If intent is informational only, return actions as [].
- Do not execute; only plan.
- assistantMessage must be concise and easy to scan:
  - Prefer 2-5 short bullets or <= 120 words total.
  - Do not repeat or paraphrase the user's full raw text/transcript.
  - Summarize what will be done and any key assumption only.
- Do not include markdown headings in assistantMessage; plain bullets and short lines are preferred.`;

const normalizeString = (value) => (typeof value === 'string' ? value.trim() : value);

const normalizeArgs = (args = {}) => {
  if (!_.isPlainObject(args)) {
    return {};
  }

  const normalized = _.mapValues(args, (value) => {
    if (Array.isArray(value)) {
      return value.map((item) => (typeof item === 'string' ? item.trim() : item));
    }

    if (_.isPlainObject(value)) {
      return _.mapValues(value, (innerValue) =>
        typeof innerValue === 'string' ? innerValue.trim() : innerValue,
      );
    }

    return typeof value === 'string' ? value.trim() : value;
  });

  if (!normalized.cardName && normalized.name && normalized.typeHint === 'card') {
    normalized.cardName = normalized.name;
  }

  return normalized;
};

const normalizePlannedActions = (actions) => {
  if (!Array.isArray(actions)) {
    return [];
  }

  const deduped = [];

  actions.forEach((action, index) => {
    if (!_.isPlainObject(action)) {
      return;
    }

    const type = normalizeString(action.type);

    if (!SUPPORTED_ACTIONS.has(type)) {
      return;
    }

    if (deduped.length >= MAX_ACTIONS_PER_REQUEST) {
      return;
    }

    deduped.push({
      id: uuid(),
      type,
      args: normalizeArgs(action.args),
      reason: normalizeString(action.reason) || `Planned action ${index + 1}`,
      requiresConfirmation: DESTRUCTIVE_ACTION_TYPES.has(type),
    });
  });

  return deduped;
};

const buildHistoryMessages = (history) =>
  history.slice(-16).map((item) => ({
    role: item.role === 'assistant' ? 'assistant' : 'user',
    content: String(item.content || ''),
  }));

const planFromMessages = async ({ history, userMessageContent, scope }) => {
  const promptSummary = scopeService.buildPromptSummary(scope);
  const contextMessage = `Authorized workspace context (JSON): ${JSON.stringify(promptSummary)}`;

  const messages = [
    {
      role: 'system',
      content: SYSTEM_PROMPT,
    },
    {
      role: 'system',
      content: contextMessage,
    },
    ...buildHistoryMessages(history),
    {
      role: 'user',
      content: userMessageContent,
    },
  ];

  const raw = await openaiService.requestJsonPlan({ messages });
  const assistantMessage = normalizeString(raw.assistantMessage) || 'I prepared a plan.';

  return {
    assistantMessage,
    actions: normalizePlannedActions(raw.actions),
  };
};

const planFromText = async ({ message, history, scope }) => {
  if (!openaiService.isConfigured()) {
    return {
      assistantMessage:
        'AI planning is unavailable because OPENAI_API_KEY is not configured on the server.',
      actions: [],
    };
  }

  return planFromMessages({
    history,
    scope,
    userMessageContent: String(message || ''),
  });
};

const planFromImage = async ({ prompt, history, scope, imageDataUri }) => {
  if (!openaiService.isConfigured()) {
    return {
      assistantMessage:
        'AI image planning is unavailable because OPENAI_API_KEY is not configured on the server.',
      actions: [],
    };
  }

  const textPrompt = normalizeString(prompt) || 'Analyze this image and plan card/list actions.';

  return planFromMessages({
    history,
    scope,
    userMessageContent: [
      {
        type: 'text',
        text: textPrompt,
      },
      {
        type: 'image_url',
        image_url: {
          url: imageDataUri,
        },
      },
    ],
  });
};

module.exports = {
  planFromText,
  planFromImage,
  normalizePlannedActions,
};
