import React, { useEffect, useCallback } from 'react';
import { useStore } from 'react-redux';

import Config from '../../constants/Config';
import createVoiceActionHandler from '../../utils/voice-actions';

const SCRIPT_ID = 'elevenlabs-convai-script';
const SCRIPT_SRC = 'https://unpkg.com/@elevenlabs/convai-widget-embed';

function VoiceAssistant() {
  const store = useStore();

  const handleCall = useCallback(
    (event) => {
      const actionHandler = createVoiceActionHandler(store);

      /* eslint-disable no-param-reassign */
      event.detail.config.clientTools = {
        get_current_board_context: async () => {
          const result = await actionHandler.get_current_board_context();
          return result;
        },
        create_card: async (params) => {
          const result = await actionHandler.create_card(params);
          return result;
        },
        update_card: async (params) => {
          const result = await actionHandler.update_card(params);
          return result;
        },
        move_card: async (params) => {
          const result = await actionHandler.move_card(params);
          return result;
        },
        delete_card: async (params) => {
          const result = await actionHandler.delete_card(params);
          return result;
        },
        create_list: async (params) => {
          const result = await actionHandler.create_list(params);
          return result;
        },
        update_list: async (params) => {
          const result = await actionHandler.update_list(params);
          return result;
        },
        delete_list: async (params) => {
          const result = await actionHandler.delete_list(params);
          return result;
        },
        search_cards: async (params) => {
          const result = await actionHandler.search_cards(params);
          return result;
        },
        get_cards_by_user: async (params) => {
          const result = await actionHandler.get_cards_by_user(params);
          return result;
        },
        get_workload_summary: async () => {
          const result = await actionHandler.get_workload_summary();
          return result;
        },
        get_overdue_cards: async () => {
          const result = await actionHandler.get_overdue_cards();
          return result;
        },
        get_user_projects: async (params) => {
          const result = await actionHandler.get_user_projects(params);
          return result;
        },
        get_project_summary: async (params) => {
          const result = await actionHandler.get_project_summary(params);
          return result;
        },
        get_all_projects_overview: async () => {
          const result = await actionHandler.get_all_projects_overview();
          return result;
        },
      };
      /* eslint-enable no-param-reassign */
    },
    [store],
  );

  useEffect(() => {
    if (!Config.ELEVENLABS_AGENT_ID) return undefined;

    document.addEventListener('elevenlabs-convai:call', handleCall);

    if (!document.getElementById(SCRIPT_ID)) {
      const script = document.createElement('script');
      script.id = SCRIPT_ID;
      script.src = SCRIPT_SRC;
      script.async = true;
      document.body.appendChild(script);
    }

    return () => {
      document.removeEventListener('elevenlabs-convai:call', handleCall);
    };
  }, [handleCall]);

  if (!Config.ELEVENLABS_AGENT_ID) {
    return null;
  }

  return <elevenlabs-convai agent-id={Config.ELEVENLABS_AGENT_ID} />;
}

export default VoiceAssistant;
