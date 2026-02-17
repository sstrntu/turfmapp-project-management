import { useState, useRef, useCallback } from 'react';
import { Conversation } from '@11labs/client';

export default function useVoiceConversation(agentId, actionHandler, getContextString) {
  const [status, setStatus] = useState('idle');
  const [messages, setMessages] = useState([]);
  const conversationRef = useRef(null);

  const start = useCallback(async () => {
    if (conversationRef.current) return;

    try {
      await navigator.mediaDevices.getUserMedia({ audio: true });
    } catch {
      setStatus('error');
      return;
    }

    try {
      const clientTools = {};
      Object.keys(actionHandler).forEach((toolName) => {
        clientTools[toolName] = async (params) => {
          const result = await actionHandler[toolName](params);
          return result;
        };
      });

      const contextString = getContextString ? getContextString() : '';

      const conversation = await Conversation.startSession({
        agentId,
        clientTools,
        overrides: contextString
          ? {
              agent: {
                prompt: {
                  prompt: contextString,
                },
              },
            }
          : undefined,
        onConnect: () => setStatus('connected'),
        onDisconnect: () => {
          setStatus('idle');
          conversationRef.current = null;
        },
        onModeChange: ({ mode }) => {
          setStatus(mode);
        },
        onMessage: (message) => {
          setMessages((prev) => [...prev, message]);
        },
        onError: () => {
          setStatus('error');
        },
      });

      conversationRef.current = conversation;
    } catch {
      setStatus('error');
    }
  }, [agentId, actionHandler, getContextString]);

  const stop = useCallback(async () => {
    if (conversationRef.current) {
      await conversationRef.current.endSession();
      conversationRef.current = null;
    }
    setStatus('idle');
  }, []);

  const clearMessages = useCallback(() => {
    setMessages([]);
  }, []);

  return { status, messages, start, stop, clearMessages };
}
