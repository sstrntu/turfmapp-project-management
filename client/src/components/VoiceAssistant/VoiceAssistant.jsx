import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import classNames from 'classnames';
import _ from 'lodash';
import { nanoid } from 'nanoid';
import { useSelector } from 'react-redux';

import aiApi from '../../api/ai';
import Config from '../../constants/Config';
import Markdown from '../../lib/custom-ui/components/Markdown';
import { selectCurrentBoard } from '../../selectors/boards';
import { selectCurrentProject } from '../../selectors/projects';
import useVoiceConversation from '../../hooks/use-voice-conversation';

import styles from './VoiceAssistant.module.scss';

const CHANNEL_TEXT = 'text';
const CHANNEL_VOICE = 'voice';
const logoImage = '/TM.png';
const SESSION_STORAGE_KEY_PREFIX = 'turfmapp-ai-session';

const createInitialChannelState = () => ({
  sessionId: null,
  messages: [],
  pendingPlan: null,
  selectedActionIds: [],
  isLoading: false,
  error: null,
});

const createMessage = (role, content, metadata = {}) => ({
  id: nanoid(),
  role,
  content,
  metadata,
  createdAt: new Date().toISOString(),
});

const getDefaultSelectedActionIds = (actions) =>
  actions.filter((action) => !action.requiresConfirmation).map((action) => action.id);

const getErrorMessage = (error, fallbackMessage) => {
  if (!error) {
    return fallbackMessage;
  }

  if (_.isString(error)) {
    return error;
  }

  if (_.isString(error.message)) {
    return error.message;
  }

  if (_.isPlainObject(error.message) && _.isString(error.message.message)) {
    return error.message.message;
  }

  if (_.isPlainObject(error.message) && _.isString(error.message.error)) {
    return error.message.error;
  }

  if (_.isString(error.error)) {
    return error.error;
  }

  return fallbackMessage;
};

const getSessionStorageKey = (channel) => `${SESSION_STORAGE_KEY_PREFIX}:${channel}`;

const getStoredSessionId = (channel) => {
  if (typeof window === 'undefined') {
    return null;
  }

  try {
    const value = window.localStorage.getItem(getSessionStorageKey(channel));

    if (!_.isString(value)) {
      return null;
    }

    const normalizedValue = value.trim();

    return normalizedValue || null;
  } catch (error) {
    return null;
  }
};

const setStoredSessionId = (channel, sessionId) => {
  if (typeof window === 'undefined') {
    return;
  }

  try {
    if (_.isString(sessionId) && sessionId.trim()) {
      window.localStorage.setItem(getSessionStorageKey(channel), sessionId.trim());
      return;
    }

    window.localStorage.removeItem(getSessionStorageKey(channel));
  } catch (error) {
    // Ignore storage errors and keep in-memory session state.
  }
};

const mapHistoryItemToMessage = (item) => {
  if (!_.isPlainObject(item)) {
    return null;
  }

  const content = _.isString(item.content) ? item.content : String(item.content || '');
  const normalizedContent = content.trim();

  if (!normalizedContent) {
    return null;
  }

  return {
    id: _.isString(item.id) && item.id.trim() ? item.id : nanoid(),
    role: item.role === 'assistant' ? 'assistant' : 'user',
    content: normalizedContent,
    metadata: _.isPlainObject(item.metadata) ? item.metadata : {},
    createdAt:
      _.isString(item.createdAt) && item.createdAt ? item.createdAt : new Date().toISOString(),
  };
};

function VoiceAssistant() {
  const currentProject = useSelector(selectCurrentProject);
  const currentBoard = useSelector(selectCurrentBoard);

  const [isOpen, setIsOpen] = useState(false);
  const [activeChannel, setActiveChannel] = useState(CHANNEL_TEXT);
  const [draftByChannel, setDraftByChannel] = useState({
    [CHANNEL_TEXT]: '',
    [CHANNEL_VOICE]: '',
  });
  const [pendingUploadByChannel, setPendingUploadByChannel] = useState({
    [CHANNEL_TEXT]: null,
    [CHANNEL_VOICE]: null,
  });
  const [channelState, setChannelState] = useState({
    [CHANNEL_TEXT]: createInitialChannelState(),
    [CHANNEL_VOICE]: createInitialChannelState(),
  });

  const messageListRef = useRef(null);
  const imageInputRef = useRef(null);
  const audioInputRef = useRef(null);
  const channelStateRef = useRef(channelState);

  useEffect(() => {
    channelStateRef.current = channelState;
  }, [channelState]);

  const context = useMemo(
    () => ({
      ...(currentProject?.id && {
        projectId: currentProject.id,
      }),
      ...(currentBoard?.id && {
        boardId: currentBoard.id,
      }),
    }),
    [currentBoard?.id, currentProject?.id],
  );

  const updateChannelState = useCallback((channel, updater) => {
    setChannelState((prevState) => {
      const current = prevState[channel];
      const next = _.isFunction(updater) ? updater(current) : updater;

      return {
        ...prevState,
        [channel]: next,
      };
    });
  }, []);

  const textSessionId = channelState[CHANNEL_TEXT].sessionId;
  const voiceSessionId = channelState[CHANNEL_VOICE].sessionId;

  useEffect(() => {
    let isCancelled = false;

    const loadChannelHistory = async (channel) => {
      const storedSessionId = getStoredSessionId(channel);

      if (!storedSessionId) {
        return;
      }

      updateChannelState(channel, (current) => ({
        ...current,
        sessionId: current.sessionId || storedSessionId,
      }));

      try {
        const response = await aiApi.getHistory({
          sessionId: storedSessionId,
          channel,
        });

        if (isCancelled) {
          return;
        }

        const historyItems = _.isArray(response.items)
          ? response.items.map(mapHistoryItemToMessage).filter(Boolean)
          : [];

        updateChannelState(channel, (current) => {
          if (current.messages.length > 0) {
            return current;
          }

          return {
            ...current,
            sessionId: storedSessionId,
            messages: historyItems,
          };
        });
      } catch (error) {
        if (isCancelled) {
          return;
        }

        setStoredSessionId(channel, null);

        updateChannelState(channel, (current) => {
          if (current.messages.length > 0) {
            return current;
          }

          return {
            ...current,
            sessionId: null,
          };
        });
      }
    };

    loadChannelHistory(CHANNEL_TEXT);
    loadChannelHistory(CHANNEL_VOICE);

    return () => {
      isCancelled = true;
    };
  }, [updateChannelState]);

  useEffect(() => {
    setStoredSessionId(CHANNEL_TEXT, textSessionId);
  }, [textSessionId]);

  useEffect(() => {
    setStoredSessionId(CHANNEL_VOICE, voiceSessionId);
  }, [voiceSessionId]);

  const applyPlanResponse = useCallback(
    (channel, response) => {
      const actions = _.isArray(response.proposedActions) ? response.proposedActions : [];
      const hasPlan = !!response.planId && actions.length > 0;

      updateChannelState(channel, (current) => {
        const messages = [...current.messages];

        if (response.assistantMessage) {
          messages.push(createMessage('assistant', response.assistantMessage));
        }

        return {
          ...current,
          sessionId: response.sessionId || current.sessionId,
          messages,
          pendingPlan: hasPlan
            ? {
                id: response.planId,
                actions,
              }
            : null,
          selectedActionIds: hasPlan ? getDefaultSelectedActionIds(actions) : [],
          isLoading: false,
          error: null,
        };
      });
    },
    [updateChannelState],
  );

  const applyErrorResponse = useCallback(
    (channel, message) => {
      updateChannelState(channel, (current) => ({
        ...current,
        isLoading: false,
        error: message,
        messages: [...current.messages, createMessage('assistant', message)],
      }));
    },
    [updateChannelState],
  );

  const runTextPlan = useCallback(
    async (channel, rawMessage) => {
      const message = rawMessage.trim();

      if (!message) {
        return;
      }

      updateChannelState(channel, (current) => ({
        ...current,
        isLoading: true,
        error: null,
        pendingPlan: null,
        selectedActionIds: [],
        messages: [...current.messages, createMessage('user', message)],
      }));

      try {
        const response = await aiApi.chat({
          sessionId: channelStateRef.current[channel].sessionId,
          channel,
          message,
          context,
        });

        applyPlanResponse(channel, response);
      } catch (error) {
        const errorMessage = getErrorMessage(error, 'Failed to process AI request.');
        applyErrorResponse(channel, errorMessage);
      }
    },
    [applyErrorResponse, applyPlanResponse, context, updateChannelState],
  );

  const runFilePlan = useCallback(
    async ({ channel, prompt, file, type }) => {
      if (!file) {
        return;
      }

      const promptText = prompt.trim();
      const userMessage =
        promptText ||
        (type === 'image' ? `Uploaded image: ${file.name}` : `Uploaded audio file: ${file.name}`);

      updateChannelState(channel, (current) => ({
        ...current,
        isLoading: true,
        error: null,
        pendingPlan: null,
        selectedActionIds: [],
        messages: [...current.messages, createMessage('user', userMessage, { source: type })],
      }));

      try {
        const payload = {
          sessionId: channelStateRef.current[channel].sessionId,
          channel,
          prompt: promptText || null,
          context,
          file,
        };

        const response =
          type === 'image' ? await aiApi.ingestImage(payload) : await aiApi.ingestAudio(payload);

        applyPlanResponse(channel, response);
      } catch (error) {
        const fallbackMessage =
          type === 'image'
            ? 'Failed to analyze the uploaded image.'
            : 'Failed to analyze the uploaded audio.';

        applyErrorResponse(channel, getErrorMessage(error, fallbackMessage));
      }
    },
    [applyErrorResponse, applyPlanResponse, context, updateChannelState],
  );

  const handleVoiceTranscript = useCallback(
    (text) => {
      updateChannelState(CHANNEL_VOICE, (current) => ({
        ...current,
        messages: [...current.messages, createMessage('user', text)],
      }));
    },
    [updateChannelState],
  );

  const handleVoiceAgentMessage = useCallback(
    (text) => {
      updateChannelState(CHANNEL_VOICE, (current) => ({
        ...current,
        messages: [...current.messages, createMessage('assistant', text)],
      }));
    },
    [updateChannelState],
  );

  const handleVoiceError = useCallback(
    (errorMsg) => {
      updateChannelState(CHANNEL_VOICE, (current) => ({
        ...current,
        error: errorMsg,
      }));
    },
    [updateChannelState],
  );

  const {
    status: voiceStatus,
    isSpeaking: voiceIsSpeaking,
    start: startVoiceSession,
    stop: stopVoiceSession,
  } = useVoiceConversation({
    context,
    onTranscript: handleVoiceTranscript,
    onAgentMessage: handleVoiceAgentMessage,
    onError: handleVoiceError,
  });

  useEffect(() => {
    if (!isOpen || !messageListRef.current) {
      return;
    }

    messageListRef.current.scrollTop = messageListRef.current.scrollHeight;
  }, [activeChannel, channelState, isOpen]);

  useEffect(
    () => () => {
      stopVoiceSession();
    },
    [stopVoiceSession],
  );

  const activeState = channelState[activeChannel];
  const activeDraft = draftByChannel[activeChannel];
  const activePendingUpload = pendingUploadByChannel[activeChannel];

  const canUseVoice = useMemo(() => {
    if (typeof window === 'undefined') {
      return false;
    }

    return !!Config.ELEVENLABS_AGENT_ID && !!navigator.mediaDevices?.getUserMedia;
  }, []);
  const isVoiceActive = voiceStatus === 'connected' || voiceStatus === 'connecting';
  const thinkingActivityText = activeState.isLoading
    ? 'Thinking... analyzing your request and planning actions.'
    : null;
  const assistantActivityText = useMemo(() => {
    if (activeChannel !== CHANNEL_VOICE) {
      return null;
    }

    if (voiceStatus === 'connecting') {
      return 'Connecting to voice assistant...';
    }

    if (voiceStatus === 'connected' && voiceIsSpeaking) {
      return 'Speaking...';
    }

    if (voiceStatus === 'connected') {
      return 'Listening...';
    }

    return null;
  }, [activeChannel, voiceStatus, voiceIsSpeaking]);

  const setDraft = useCallback((channel, value) => {
    setDraftByChannel((prevDrafts) => ({
      ...prevDrafts,
      [channel]: value,
    }));
  }, []);

  const setPendingUpload = useCallback((channel, value) => {
    setPendingUploadByChannel((prevUploads) => ({
      ...prevUploads,
      [channel]: value,
    }));
  }, []);

  const handleResetSession = useCallback(async () => {
    if (activeChannel === CHANNEL_VOICE && isVoiceActive) {
      await stopVoiceSession();
    }

    setStoredSessionId(activeChannel, null);
    setDraft(activeChannel, '');
    setPendingUpload(activeChannel, null);
    updateChannelState(activeChannel, createInitialChannelState());
  }, [
    activeChannel,
    isVoiceActive,
    setPendingUpload,
    setDraft,
    stopVoiceSession,
    updateChannelState,
  ]);

  const handleSendDraft = useCallback(async () => {
    const value = draftByChannel[activeChannel] || '';
    const trimmed = value.trim();
    const pendingUpload = pendingUploadByChannel[activeChannel];

    if ((!trimmed && !pendingUpload) || activeState.isLoading) {
      return;
    }

    setDraft(activeChannel, '');
    setPendingUpload(activeChannel, null);

    if (pendingUpload) {
      await runFilePlan({
        channel: activeChannel,
        prompt: trimmed,
        file: pendingUpload.file,
        type: pendingUpload.type,
      });

      return;
    }

    await runTextPlan(activeChannel, trimmed);
  }, [
    activeChannel,
    activeState.isLoading,
    draftByChannel,
    pendingUploadByChannel,
    runFilePlan,
    runTextPlan,
    setDraft,
    setPendingUpload,
  ]);

  const toggleActionSelection = useCallback(
    (channel, actionId) => {
      updateChannelState(channel, (current) => {
        const nextSet = new Set(current.selectedActionIds);

        if (nextSet.has(actionId)) {
          nextSet.delete(actionId);
        } else {
          nextSet.add(actionId);
        }

        return {
          ...current,
          selectedActionIds: Array.from(nextSet),
        };
      });
    },
    [updateChannelState],
  );

  const handleConfirmSelected = useCallback(
    async (channel) => {
      const state = channelStateRef.current[channel];
      const planId = state.pendingPlan?.id;

      if (!planId || state.selectedActionIds.length === 0 || state.isLoading) {
        return;
      }

      updateChannelState(channel, (current) => ({
        ...current,
        isLoading: true,
        error: null,
      }));

      try {
        const response = await aiApi.confirmPlan({
          planId,
          approvedActionIds: state.selectedActionIds,
          approveAll: false,
        });

        const detailLines = (_.isArray(response.executedActions) ? response.executedActions : [])
          .map((result) => {
            const statusText = result.success ? 'ok' : 'failed';
            const detail = result.message || result.error || 'No details';

            return `${statusText.toUpperCase()}: ${result.type} - ${detail}`;
          })
          .join('\n');

        updateChannelState(channel, (current) => ({
          ...current,
          pendingPlan: null,
          selectedActionIds: [],
          isLoading: false,
          error: null,
          messages: [
            ...current.messages,
            createMessage(
              'assistant',
              detailLines ? `${response.summary}\n${detailLines}` : response.summary,
            ),
          ],
        }));
      } catch (error) {
        const errorMessage = getErrorMessage(error, 'Failed to confirm actions.');
        applyErrorResponse(channel, errorMessage);
      }
    },
    [applyErrorResponse, updateChannelState],
  );

  const handleImageInput = useCallback(
    (event) => {
      const file = event.target.files?.[0];

      if (!file || activeState.isLoading) {
        return;
      }

      setPendingUpload(activeChannel, {
        type: 'image',
        file,
      });

      if (imageInputRef.current) {
        imageInputRef.current.value = '';
      }
    },
    [activeChannel, activeState.isLoading, setPendingUpload],
  );

  const handleAudioInput = useCallback(
    (event) => {
      const file = event.target.files?.[0];

      if (!file || activeState.isLoading) {
        return;
      }

      setPendingUpload(activeChannel, {
        type: 'audio',
        file,
      });

      if (audioInputRef.current) {
        audioInputRef.current.value = '';
      }
    },
    [activeChannel, activeState.isLoading, setPendingUpload],
  );

  const handlePendingUploadClear = useCallback(() => {
    setPendingUpload(activeChannel, null);

    if (imageInputRef.current) {
      imageInputRef.current.value = '';
    }

    if (audioInputRef.current) {
      audioInputRef.current.value = '';
    }
  }, [activeChannel, setPendingUpload]);

  const handleVoiceToggle = useCallback(async () => {
    if (!canUseVoice) {
      return;
    }

    if (isVoiceActive) {
      await stopVoiceSession();
      return;
    }

    await startVoiceSession();
  }, [canUseVoice, isVoiceActive, startVoiceSession, stopVoiceSession]);

  const handleCloseLauncher = useCallback(async () => {
    setIsOpen(false);

    if (isVoiceActive) {
      await stopVoiceSession();
    }
  }, [isVoiceActive, stopVoiceSession]);

  const handleOpenTextLauncher = useCallback(async () => {
    setIsOpen(true);
    setActiveChannel(CHANNEL_TEXT);

    if (isVoiceActive) {
      await stopVoiceSession();
    }
  }, [isVoiceActive, stopVoiceSession]);

  const handleOpenVoiceLauncher = useCallback(async () => {
    setIsOpen(true);
    setActiveChannel(CHANNEL_VOICE);

    if (canUseVoice && !isVoiceActive) {
      await startVoiceSession();
    }
  }, [canUseVoice, isVoiceActive, startVoiceSession]);

  const handlePromptKeyDown = useCallback(
    (event) => {
      if (event.key !== 'Enter' || event.shiftKey) {
        return;
      }

      event.preventDefault();
      handleSendDraft();
    },
    [handleSendDraft],
  );

  const canResetSession = !!activeState.sessionId || activeState.messages.length > 0;

  let voiceButtonLabel = 'Start voice';
  if (voiceStatus === 'connecting') voiceButtonLabel = 'Connecting...';
  else if (isVoiceActive) voiceButtonLabel = 'Stop voice';

  return (
    <div className={styles.wrapper}>
      {isOpen && (
        <section className={styles.panel}>
          <div className={styles.hero}>
            <img src={logoImage} alt="TM assistant" className={styles.heroLogo} />
          </div>

          {assistantActivityText && (
            <div className={styles.activityStatus}>{assistantActivityText}</div>
          )}

          <div className={styles.sessionActions}>
            <button
              type="button"
              className={styles.resetSessionButton}
              onClick={handleResetSession}
              disabled={!canResetSession || activeState.isLoading}
            >
              Reset session
            </button>
          </div>

          <div className={styles.messages} ref={messageListRef}>
            {activeState.messages.length === 0 ? (
              <div className={styles.placeholder}>
                {activeChannel === CHANNEL_TEXT
                  ? 'Type a message to manage your board and cards.'
                  : 'Use voice to manage your board and cards.'}
              </div>
            ) : (
              activeState.messages.map((message) => (
                <article
                  key={message.id}
                  className={classNames(styles.message, {
                    [styles.messageUser]: message.role === 'user',
                    [styles.messageAssistant]: message.role === 'assistant',
                  })}
                >
                  {message.role === 'assistant' ? (
                    <div className={styles.assistantMarkdown}>
                      <Markdown>{message.content}</Markdown>
                    </div>
                  ) : (
                    message.content
                  )}
                </article>
              ))
            )}
          </div>

          {activeChannel === CHANNEL_TEXT && activeState.pendingPlan && (
            <section className={styles.planContainer}>
              <div className={styles.planTitle}>Proposed actions</div>
              <div className={styles.planList}>
                {activeState.pendingPlan.actions.map((action) => {
                  const isChecked = activeState.selectedActionIds.includes(action.id);
                  const actionCheckboxId = `action-toggle-${action.id}`;

                  return (
                    <div key={action.id} className={styles.planItem}>
                      <input
                        id={actionCheckboxId}
                        type="checkbox"
                        checked={isChecked}
                        onChange={() => toggleActionSelection(activeChannel, action.id)}
                      />
                      <label htmlFor={actionCheckboxId}>
                        <span className={styles.planItemType}>{action.type}</span>
                        <span className={styles.planItemReason}>{action.reason}</span>
                      </label>
                    </div>
                  );
                })}
              </div>
              <button
                type="button"
                className={styles.confirmButton}
                onClick={() => handleConfirmSelected(activeChannel)}
                disabled={activeState.selectedActionIds.length === 0 || activeState.isLoading}
              >
                Confirm selected actions
              </button>
            </section>
          )}

          {activeChannel === CHANNEL_VOICE && (
            <div className={styles.voiceControlCard}>
              <span className={styles.voiceMetaLabel}>ElevenLabs Voice Channel</span>
              <button
                type="button"
                className={classNames(styles.voiceButton, {
                  [styles.voiceButtonInactive]: !canUseVoice,
                  [styles.voiceButtonActive]: canUseVoice && isVoiceActive,
                })}
                onClick={handleVoiceToggle}
                disabled={!canUseVoice || voiceStatus === 'connecting'}
              >
                {voiceButtonLabel}
              </button>
              {activeState.error && <div className={styles.errorText}>{activeState.error}</div>}
            </div>
          )}

          {activeChannel === CHANNEL_TEXT && (
            <>
              {thinkingActivityText && (
                <div className={classNames(styles.activityStatus, styles.activityStatusComposer)}>
                  {thinkingActivityText}
                </div>
              )}
              <div className={styles.composer}>
                <textarea
                  className={styles.promptInput}
                  value={activeDraft}
                  placeholder="Send a message..."
                  onChange={(event) => setDraft(activeChannel, event.target.value)}
                  onKeyDown={handlePromptKeyDown}
                  rows={2}
                  disabled={activeState.isLoading}
                />
                {activePendingUpload && (
                  <div className={styles.pendingUploadRow}>
                    <div className={styles.pendingUploadMeta}>
                      <i
                        className={
                          activePendingUpload.type === 'image'
                            ? 'image outline icon'
                            : 'file audio outline icon'
                        }
                      />
                      <span className={styles.pendingUploadName}>
                        {activePendingUpload.file.name}
                      </span>
                    </div>
                    <button
                      type="button"
                      className={styles.pendingUploadRemoveButton}
                      onClick={handlePendingUploadClear}
                      disabled={activeState.isLoading}
                    >
                      Remove
                    </button>
                  </div>
                )}
                <div className={styles.composerFooter}>
                  <div className={styles.composerUtility}>
                    <button
                      type="button"
                      className={styles.iconButton}
                      onClick={() => imageInputRef.current?.click()}
                      disabled={activeState.isLoading}
                      aria-label="Upload image"
                    >
                      <i className="image outline icon" />
                    </button>
                    <button
                      type="button"
                      className={styles.iconButton}
                      onClick={() => audioInputRef.current?.click()}
                      disabled={activeState.isLoading}
                      aria-label="Upload audio"
                    >
                      <i className="file audio outline icon" />
                    </button>
                  </div>
                  <button
                    type="button"
                    className={styles.sendButton}
                    onClick={handleSendDraft}
                    disabled={
                      activeState.isLoading || (!activeDraft.trim() && !activePendingUpload)
                    }
                    aria-label="Send message"
                  >
                    <i className="arrow up icon" />
                  </button>
                </div>
                {activeState.error && <div className={styles.errorText}>{activeState.error}</div>}
              </div>

              <input
                ref={imageInputRef}
                type="file"
                accept="image/*"
                className={styles.hiddenInput}
                onChange={handleImageInput}
              />
              <input
                ref={audioInputRef}
                type="file"
                accept="audio/*"
                className={styles.hiddenInput}
                onChange={handleAudioInput}
              />
            </>
          )}
        </section>
      )}

      {isOpen ? (
        <button
          type="button"
          className={classNames(styles.launcherCircle, styles.launcherClose)}
          aria-label="Close assistant"
          onClick={handleCloseLauncher}
        >
          <i className="chevron down icon" />
        </button>
      ) : (
        <div className={styles.launcherRow}>
          <button
            type="button"
            className={classNames(styles.launcherCircle, styles.launcherCircleChat, {
              [styles.launcherCircleActive]: activeChannel === CHANNEL_TEXT,
            })}
            aria-label="Open chat assistant"
            onClick={handleOpenTextLauncher}
          >
            <i className="comment alternate outline icon" />
          </button>
          <button
            type="button"
            className={classNames(styles.launcherCircle, styles.launcherCircleVoice, {
              [styles.launcherCircleActive]: activeChannel === CHANNEL_VOICE || isVoiceActive,
            })}
            aria-label="Open voice assistant"
            onClick={handleOpenVoiceLauncher}
            disabled={!canUseVoice}
          >
            <i className="microphone icon" />
          </button>
        </div>
      )}
    </div>
  );
}

export default VoiceAssistant;
