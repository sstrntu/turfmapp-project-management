import { attr, fk } from 'redux-orm';

import BaseModel from './BaseModel';
import ActionTypes from '../constants/ActionTypes';

export default class extends BaseModel {
  static modelName = 'BoardMilestone';

  static fields = {
    id: attr(),
    name: attr(),
    dueDate: attr(),
    boardId: fk({
      to: 'Board',
      as: 'board',
      relatedName: 'milestones',
    }),
  };

  static reducer({ type, payload }, BoardMilestone) {
    switch (type) {
      case ActionTypes.BOARD_MILESTONE_CREATE:
        BoardMilestone.upsert(payload.milestone);
        break;
      case ActionTypes.BOARD_MILESTONE_CREATE__SUCCESS:
        if (payload.localId) {
          const existing = BoardMilestone.withId(payload.localId);
          if (existing) {
            existing.delete();
          }
        }
        BoardMilestone.upsert(payload.milestone);
        break;
      case ActionTypes.BOARD_MILESTONE_UPDATE:
        BoardMilestone.withId(payload.id).update(payload.data);
        break;
      case ActionTypes.BOARD_MILESTONE_UPDATE__SUCCESS:
        BoardMilestone.upsert(payload.milestone);
        break;
      case ActionTypes.BOARD_MILESTONE_DELETE: {
        const milestoneModel = BoardMilestone.withId(payload.id);
        if (milestoneModel) {
          milestoneModel.delete();
        }
        break;
      }
      case ActionTypes.BOARD_MILESTONE_DELETE__SUCCESS: {
        const milestoneModel = BoardMilestone.withId(payload.milestone.id);
        if (milestoneModel) {
          milestoneModel.delete();
        }
        break;
      }
      default:
    }
  }
}
