import { useState, useRef, useCallback, useEffect } from 'react';
import { Conversation } from '@11labs/client';

import Config from '../constants/Config';
import aiApi from '../api/ai';

export default function useVoiceConversation({ context, onTranscript, onAgentMessage, onError }) {
  const [status, setStatus] = useState('idle');
  const [isSpeaking, setIsSpeaking] = useState(false);
  const conversationRef = useRef(null);
  const contextRef = useRef(context);

  useEffect(() => {
    contextRef.current = context;
  }, [context]);

  const stop = useCallback(async () => {
    if (conversationRef.current) {
      try {
        await conversationRef.current.endSession();
      } catch (error) {
        // Ignore end-session errors
      }
      conversationRef.current = null;
    }
    setStatus('idle');
    setIsSpeaking(false);
  }, []);

  const start = useCallback(async () => {
    if (conversationRef.current) {
      return;
    }

    if (!Config.ELEVENLABS_AGENT_ID) {
      setStatus('error');
      if (onError) onError('ElevenLabs agent ID is not configured.');
      return;
    }

    setStatus('connecting');

    let voiceContext;
    try {
      voiceContext = await aiApi.getVoiceContext({
        projectId: contextRef.current?.projectId,
        boardId: contextRef.current?.boardId,
      });
    } catch (error) {
      setStatus('error');
      const detail = error?.message || error?.error || '';
      if (onError) onError(detail ? `Voice context error: ${detail}` : 'Failed to load workspace context for voice.');
      return;
    }

    try {
      const conversation = await Conversation.startSession({
        agentId: Config.ELEVENLABS_AGENT_ID,
        overrides: {
          agent: {
            prompt: {
              prompt: voiceContext.systemPrompt,
            },
          },
        },
        clientTools: {
          get_board_context: async () => {
            try {
              const fresh = await aiApi.getVoiceContext({
                projectId: contextRef.current?.projectId,
                boardId: contextRef.current?.boardId,
              });
              return JSON.stringify(fresh.workspace);
            } catch (error) {
              return JSON.stringify({ error: 'Failed to fetch board context' });
            }
          },
          create_card: async ({ cardName, listName, boardName, description, dueDate }) => {
            try {
              const result = await aiApi.voiceExecute({
                type: 'create_card',
                args: { cardName, listName, boardName, description, dueDate },
                context: contextRef.current,
              });
              return result.message;
            } catch (error) {
              return `Error: ${error.message || 'Failed to create card'}`;
            }
          },
          update_card: async ({
            cardName,
            listName,
            boardName,
            changes,
            assigneeNames,
            labelNames,
          }) => {
            try {
              const result = await aiApi.voiceExecute({
                type: 'update_card',
                args: { cardName, listName, boardName, changes, assigneeNames, labelNames },
                context: contextRef.current,
              });
              return result.message;
            } catch (error) {
              return `Error: ${error.message || 'Failed to update card'}`;
            }
          },
          move_card: async ({ cardName, targetListName, boardName }) => {
            try {
              const result = await aiApi.voiceExecute({
                type: 'move_card',
                args: { cardName, targetListName, boardName },
                context: contextRef.current,
              });
              return result.message;
            } catch (error) {
              return `Error: ${error.message || 'Failed to move card'}`;
            }
          },
          archive_card: async ({ cardName, listName, boardName }) => {
            try {
              const result = await aiApi.voiceExecute({
                type: 'archive_card',
                args: { cardName, listName, boardName },
                context: contextRef.current,
              });
              return result.message;
            } catch (error) {
              return `Error: ${error.message || 'Failed to archive card'}`;
            }
          },
          delete_card: async ({ cardName, listName, boardName }) => {
            try {
              const result = await aiApi.voiceExecute({
                type: 'delete_card',
                args: { cardName, listName, boardName },
                context: contextRef.current,
              });
              return result.message;
            } catch (error) {
              return `Error: ${error.message || 'Failed to delete card'}`;
            }
          },
          create_list: async ({ listName, boardName }) => {
            try {
              const result = await aiApi.voiceExecute({
                type: 'create_list',
                args: { listName, boardName },
                context: contextRef.current,
              });
              return result.message;
            } catch (error) {
              return `Error: ${error.message || 'Failed to create list'}`;
            }
          },
          update_list: async ({ listName, boardName, changes }) => {
            try {
              const result = await aiApi.voiceExecute({
                type: 'update_list',
                args: { listName, boardName, changes },
                context: contextRef.current,
              });
              return result.message;
            } catch (error) {
              return `Error: ${error.message || 'Failed to update list'}`;
            }
          },
          delete_list: async ({ listName, boardName }) => {
            try {
              const result = await aiApi.voiceExecute({
                type: 'delete_list',
                args: { listName, boardName },
                context: contextRef.current,
              });
              return result.message;
            } catch (error) {
              return `Error: ${error.message || 'Failed to delete list'}`;
            }
          },
        },
        onConnect: () => {
          setStatus('connected');
        },
        onDisconnect: () => {
          conversationRef.current = null;
          setStatus('idle');
          setIsSpeaking(false);
        },
        onError: (message) => {
          setStatus('error');
          if (onError) onError(message || 'Voice session error');
        },
        onModeChange: ({ mode }) => {
          setIsSpeaking(mode === 'speaking');
        },
        onMessage: ({ message, source }) => {
          if (source === 'user' && onTranscript) {
            onTranscript(message);
          }
          if (source === 'ai' && onAgentMessage) {
            onAgentMessage(message);
          }
        },
      });

      conversationRef.current = conversation;
    } catch (error) {
      setStatus('error');
      if (onError) onError(error?.message || 'Failed to start voice session');
    }
  }, [onError, onTranscript, onAgentMessage]);

  useEffect(
    () => () => {
      if (conversationRef.current) {
        try {
          conversationRef.current.endSession();
        } catch (error) {
          // Ignore cleanup errors
        }
        conversationRef.current = null;
      }
    },
    [],
  );

  return { status, isSpeaking, start, stop };
}
