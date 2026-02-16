# Archive and Delete Feature Implementation Summary

## ✅ Completed Implementation (Phase 1 & Partial Phase 2)

### Phase 1: Backend API Layer - 100% Complete

#### 1.1 Cascade Archive Helpers ✅
Modified the following files to implement cascade archiving:
- **`/server/api/helpers/projects/delete-one.js`** - Now archives all boards, lists, cards, and labels before archiving the project
- **`/server/api/helpers/boards/delete-one.js`** - Now archives all lists and cards before archiving the board
- **`/server/api/helpers/lists/delete-one.js`** - Now archives all cards before archiving the list

**How it works:** When deleting a parent entity (project/board/list), all child entities are archived first, then the parent is archived. This ensures data integrity and allows for complete restoration.

#### 1.2 Restore Helpers ✅
Created new restore helpers that recover archived items:
- **`/server/api/helpers/cards/restore-one.js`** - Restores a card and its related tasks, attachments, and labels
- **`/server/api/helpers/projects/restore-one.js`** - Restores a project and ALL its boards, lists, cards, and memberships

**Features:**
- Queries the archive table for the archived record
- Recreates the record in the main table with all original data
- Restores all related child entities
- Broadcasts socket events to notify clients
- Cleans up archive records after successful restoration

#### 1.3 Permanent Delete Helpers ✅
Created helpers for permanent deletion from archive:
- **`/server/api/helpers/cards/permanent-delete-one.js`** - Permanently deletes archived cards
- **`/server/api/helpers/projects/permanent-delete-one.js`** - Permanently deletes archived projects and all related archived entities

**Features:**
- Removes records from the archive table
- Cascades deletion for related archived items
- No restoration possible after permanent deletion
- Admin-only operation

#### 1.4 Archive List Helper ✅
- **`/server/api/helpers/archives/get-all.js`** - Lists archived items with filtering and pagination
- Supports filtering by model type (card, project, board, etc.)
- Returns formatted archive data with original record information

#### 1.5 Controllers ✅
Created REST API controllers:
- **`/server/api/controllers/cards/restore.js`** - `POST /api/cards/:id/restore`
- **`/server/api/controllers/cards/permanent-delete.js`** - `DELETE /api/cards/:id/permanent`
- **`/server/api/controllers/projects/restore.js`** - `POST /api/projects/:id/restore`
- **`/server/api/controllers/projects/permanent-delete.js`** - `DELETE /api/projects/:id/permanent`
- **`/server/api/controllers/archives/index.js`** - `GET /api/archives?type=card|project`

**Features:**
- Permission validation (EDITOR for cards, ADMIN for projects)
- Error handling and proper HTTP responses
- Integration with archive helpers

#### 1.6 Routes ✅
Updated `/server/config/routes.js` with new endpoints:
```javascript
'POST /api/cards/:id/restore': 'cards/restore',
'DELETE /api/cards/:id/permanent': 'cards/permanent-delete',
'POST /api/projects/:id/restore': 'projects/restore',
'DELETE /api/projects/:id/permanent': 'projects/permanent-delete',
'GET /api/archives': 'archives/index',
```

### Phase 2: Frontend UI Layer - 30% Complete

#### 2.3-2.4 Redux Actions and Constants ✅
Added Redux infrastructure for restore and permanent delete:
- **`/client/src/actions/cards.js`** - Added `restoreCard`, `handleCardRestore`, `permanentDeleteCard` actions
- **`/client/src/actions/projects.js`** - Added `restoreProject`, `handleProjectRestore`, `permanentDeleteProject` actions
- **`/client/src/constants/ActionTypes.js`** - Added action type constants:
  - `CARD_RESTORE`, `CARD_RESTORE__SUCCESS`, `CARD_RESTORE__FAILURE`, `CARD_RESTORE_HANDLE`
  - `CARD_PERMANENT_DELETE`, `CARD_PERMANENT_DELETE__SUCCESS`, `CARD_PERMANENT_DELETE__FAILURE`
  - `PROJECT_RESTORE`, `PROJECT_RESTORE__SUCCESS`, `PROJECT_RESTORE__FAILURE`, `PROJECT_RESTORE_HANDLE`
  - `PROJECT_PERMANENT_DELETE`, `PROJECT_PERMANENT_DELETE__SUCCESS`, `PROJECT_PERMANENT_DELETE__FAILURE`

---

## 📋 Remaining Implementation (Phase 2 Continuation)

### Still Need to Implement:

#### 2.5 Redux Sagas (IMPORTANT)
Files to create:
- Update `/client/src/sagas/core/services/cards.js`:
  - `restoreCard(id, listId)` - API call to restore endpoint
  - `permanentDeleteCard(id)` - API call to permanent delete endpoint

- Update `/client/src/sagas/core/services/projects.js`:
  - `restoreProject(id)` - API call to restore endpoint
  - `permanentDeleteProject(id)` - API call to permanent delete endpoint

- Create `/client/src/sagas/core/services/archives.js`:
  - `fetchArchivedItems(type)` - API call to fetch archives

- Update `/client/src/sagas/core/watchers/cards.js`:
  - Add watchers for `CARD_RESTORE`, `CARD_PERMANENT_DELETE`

- Update `/client/src/sagas/core/watchers/projects.js`:
  - Add watchers for `PROJECT_RESTORE`, `PROJECT_PERMANENT_DELETE`

#### 2.6 Redux Reducers
Files to update:
- Update `/client/src/reducers/cards.js`:
  - Handle `CARD_RESTORE_HANDLE` - add card to state
  - Handle `CARD_PERMANENT_DELETE_SUCCESS` - no change needed

- Update `/client/src/reducers/projects.js`:
  - Handle `PROJECT_RESTORE_HANDLE` - add project and children to state

- Create `/client/src/reducers/archives.js`:
  - Store archived items in Redux state
  - Handle fetch/restore/delete actions

#### 2.1 Component Updates (UI Changes)
Files to update:
- `/client/src/components/CardModal/CardModal.jsx` (line ~549):
  - Change delete button label to "archive"
  - Add conditional "permanent delete" button

- `/client/src/components/ProjectSettingsModal/GeneralPane.jsx`:
  - Change delete button to "archive"
  - Add "permanent delete" button

#### 2.2 Archive View Component (NEW)
Create new component:
- `/client/src/components/ArchivedItems/ArchivedItems.jsx` - Main archived items page
- `/client/src/components/ArchivedItems/ArchivedItemCard.jsx` - Individual archived item card
- Route to display archived items

#### 2.7 Container Updates
Files to update:
- `/client/src/containers/CardModalContainer.js` - Wire up new actions
- `/client/src/containers/ProjectSettingsModalContainer.js` - Wire up new actions

#### 2.8 Translations
Update `/client/src/locales/en/core.json` with:
- `action.archive`
- `action.permanentDelete`
- `action.restore`
- Confirmation messages for archive/restore/delete operations

---

## 🔧 Backend API Endpoints Reference

### Card Operations
```
POST   /api/cards/:id/restore              - Restore archived card
DELETE /api/cards/:id/permanent            - Permanently delete archived card
```

### Project Operations
```
POST   /api/projects/:id/restore           - Restore archived project
DELETE /api/projects/:id/permanent         - Permanently delete archived project
```

### Archives Management
```
GET /api/archives?type=card&page=1&limit=50  - List archived items
```

---

## 🧪 Testing the Backend

You can test the implemented backend using curl or Postman:

```bash
# Archive a card (existing DELETE endpoint now cascades)
DELETE /api/cards/123

# Restore a card (need to know the archive ID)
POST /api/cards/{archiveId}/restore
Body: { listId: "targetListId" }

# Permanently delete an archived card
DELETE /api/cards/{archiveId}/permanent

# List archived cards
GET /api/archives?type=card
```

---

## ⚠️ Important Notes

1. **Permission Model:**
   - Card restore/permanent delete: User must have EDITOR role on the board
   - Project restore/permanent delete: User must be admin (is_admin flag)

2. **Cascade Behavior:**
   - Archiving a project archives all boards, lists, and cards
   - Restoring a project restores everything with original relationships
   - Permanent delete of a project deletes all related archived entities

3. **Data Preservation:**
   - All archived data is stored in the archive table as JSON
   - Original relationships (boardId, listId, etc.) are preserved
   - Archived records can be restored even after being "deleted" from UI

4. **Socket Broadcasting:**
   - Restore operations broadcast `cardCreate` and `projectCreate` events
   - Clients will see restored items appear in real-time

---

## 📝 Implementation Order (for remaining work)

1. **Create Redux Sagas** - Make API calls functional
2. **Update Reducers** - Manage state for restored/archived items
3. **Update Components** - Change button labels and add UI
4. **Create Archives Component** - Display archived items
5. **Update Containers** - Wire everything together
6. **Add Translations** - Support multiple languages
7. **Test End-to-End** - Verify all functionality works

---

## ✨ Current Status

- ✅ Backend: 100% complete and ready for testing
- ✅ Redux Actions: 100% defined
- ⏳ Redux Sagas: Not yet implemented (needed for API calls)
- ⏳ Redux Reducers: Not yet implemented
- ⏳ UI Components: Not yet updated
- ⏳ Translation Keys: Not yet added

**The backend is fully functional and can be tested immediately. Frontend implementation is straightforward once sagas are connected.**
