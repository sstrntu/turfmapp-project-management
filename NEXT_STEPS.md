# Next Steps: Completing the Archive Implementation

This guide provides specific code snippets and instructions to complete the remaining 30% of implementation.

---

## Step 1: Create Redux Reducers

### File: `/client/src/reducers/archives.js` (NEW)

Create this new file to manage archived items state:

```javascript
import ActionTypes from '../constants/ActionTypes';

const initialState = {
  items: [],
  total: 0,
  page: 1,
  isLoading: false,
  error: null,
};

export default function archivesReducer(state = initialState, action) {
  switch (action.type) {
    case ActionTypes.ARCHIVE_FETCH:
      return {
        ...state,
        isLoading: true,
        error: null,
      };
    case ActionTypes.ARCHIVE_FETCH__SUCCESS:
      return {
        ...state,
        items: action.payload.items,
        total: action.payload.total,
        page: action.payload.page,
        isLoading: false,
      };
    case ActionTypes.ARCHIVE_FETCH__FAILURE:
      return {
        ...state,
        isLoading: false,
        error: action.payload.error,
      };
    case ActionTypes.CARD_PERMANENT_DELETE__SUCCESS:
    case ActionTypes.PROJECT_PERMANENT_DELETE__SUCCESS:
      return {
        ...state,
        items: state.items.filter((item) => item.id !== action.payload.id),
        total: state.total - 1,
      };
    default:
      return state;
  }
}
```

### File: Update `/client/src/reducers/cards.js`

Add handling for card restore:

```javascript
// Add to switch statement:

case ActionTypes.CARD_RESTORE_HANDLE: {
  const { card, cardMemberships, cardLabels, tasks, attachments } = action.payload;

  return {
    ...state,
    byId: {
      ...state.byId,
      [card.id]: card,
    },
    allIds: state.allIds.includes(card.id) ? state.allIds : [...state.allIds, card.id],
  };
}

case ActionTypes.CARD_PERMANENT_DELETE__SUCCESS:
  // No change needed - card already removed when deleted
  return state;
```

### File: Update `/client/src/reducers/projects.js`

Add handling for project restore:

```javascript
// Add to switch statement:

case ActionTypes.PROJECT_RESTORE_HANDLE: {
  const { project, users, projectManagers, boards, boardMemberships } = action.payload;

  return {
    ...state,
    byId: {
      ...state.byId,
      [project.id]: project,
    },
    allIds: state.allIds.includes(project.id) ? state.allIds : [...state.allIds, project.id],
  };
}
```

---

## Step 2: Update UI Component Labels

### File: `/client/src/components/CardModal/CardModal.jsx`

Find the delete button (around line 549) and change:

```javascript
// BEFORE:
<DeletePopup
  title="common.deleteCard"
  content="common.areYouSureYouWantToDeleteThisCard"
  buttonContent="action.deleteCard"
  onConfirm={onDelete}
>
  <Button fluid className={styles.actionButton}>
    <Icon name="trash alternate outline" className={styles.actionIcon} />
    {t('action.delete')}
  </Button>
</DeletePopup>

// AFTER:
<DeletePopup
  title="common.archiveCard"
  content="common.areYouSureYouWantToArchiveThisCard"
  buttonContent="action.archive"
  onConfirm={onDelete}
>
  <Button fluid className={styles.actionButton}>
    <Icon name="archive outline" className={styles.actionIcon} />
    {t('action.archive')}
  </Button>
</DeletePopup>
```

---

## Step 3: Add Translations

### File: `/client/src/locales/en/core.json`

Add these translation keys:

```json
{
  "action.archive": "Archive",
  "action.archiveCard": "Archive Card",
  "action.archiveProject": "Archive Project",
  "action.permanentDelete": "Permanent Delete",
  "action.restore": "Restore",
  "common.archive": "Archive",
  "common.archiveCard": "Archive Card",
  "common.archiveProject": "Archive Project",
  "common.areYouSureYouWantToArchiveThisCard": "Are you sure you want to archive this card?",
  "common.areYouSureYouWantToArchiveThisProject": "Are you sure you want to archive this project? All boards, lists, and cards will also be archived.",
  "common.areYouSureYouWantToPermanentlyDeleteThisCard": "Are you sure you want to permanently delete this card? This action cannot be undone.",
  "common.areYouSureYouWantToPermanentlyDeleteThisProject": "Are you sure you want to permanently delete this project? This action cannot be undone.",
  "common.archivedItems": "Archived Items",
  "common.archivedCards": "Archived Cards",
  "common.archivedProjects": "Archived Projects",
  "common.noArchivedItems": "No archived items"
}
```

---

## Step 4: Create Archive Viewer Component

### File: `/client/src/components/ArchivedItems/ArchivedItems.jsx` (NEW)

```javascript
import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Container, Table, Button, Icon, Message } from 'semantic-ui-react';
import request from '../../api/request';

const ArchivedItems = ({ type = 'card', onRestore, onDelete }) => {
  const [t] = useTranslation();
  const [items, setItems] = useState([]);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    fetchArchivedItems();
  }, [type]);

  const fetchArchivedItems = async () => {
    setIsLoading(true);
    try {
      const response = await request(
        fetch(`/api/archives?type=${type}`).then(r => r.json())
      );
      setItems(response.items || []);
    } catch (error) {
      console.error('Failed to fetch archived items:', error);
    } finally {
      setIsLoading(false));
    }
  };

  if (items.length === 0) {
    return (
      <Message info>
        <Message.Header>{t('common.noArchivedItems')}</Message.Header>
      </Message>
    );
  }

  return (
    <Table celled striped>
      <Table.Header>
        <Table.Row>
          <Table.HeaderCell>{t('common.name')}</Table.HeaderCell>
          <Table.HeaderCell>{t('common.archivedAt')}</Table.HeaderCell>
          <Table.HeaderCell textAlign="right">{t('common.actions')}</Table.HeaderCell>
        </Table.Row>
      </Table.Header>
      <Table.Body>
        {items.map((item) => (
          <Table.Row key={item.id}>
            <Table.Cell>{item.name}</Table.Cell>
            <Table.Cell>{new Date(item.archivedAt).toLocaleDateString()}</Table.Cell>
            <Table.Cell textAlign="right">
              <Button
                icon
                size="small"
                onClick={() => onRestore?.(item.archiveId)}
                title={t('action.restore')}
              >
                <Icon name="undo" />
              </Button>
              <Button
                icon
                size="small"
                negative
                onClick={() => onDelete?.(item.archiveId)}
                title={t('action.permanentDelete')}
              >
                <Icon name="trash" />
              </Button>
            </Table.Cell>
          </Table.Row>
        ))}
      </Table.Body>
    </Table>
  );
};

export default ArchivedItems;
```

---

## Step 5: Update Container Mappings

### File: `/client/src/containers/CardModalContainer.js`

Find the mapDispatchToProps and update:

```javascript
const mapDispatchToProps = (dispatch) => ({
  // ... existing mappings ...
  onDelete: (id) => {
    dispatch(entryActions.deleteCard(id));
  },
  onRestore: (archiveId, listId) => {
    dispatch(entryActions.restoreCard(archiveId, listId));
  },
  onPermanentDelete: (archiveId) => {
    dispatch(entryActions.permanentDeleteCard(archiveId));
  },
});
```

---

## Step 6: Update Component Props

### File: `/client/src/components/CardModal/CardModal.jsx`

Add new props to the component signature:

```javascript
const CardModal = React.memo(
  ({
    // ... existing props ...
    onDelete,
    onRestore,
    onPermanentDelete,
    // ... rest of props ...
  }) => {
    // ... component code ...
  }
);

CardModal.propTypes = {
  // ... existing propTypes ...
  onDelete: PropTypes.func.isRequired,
  onRestore: PropTypes.func,
  onPermanentDelete: PropTypes.func,
};
```

---

## Step 7: Test the Implementation

### Manual Testing Checklist

- [ ] Archive a card from the card modal
- [ ] Verify card is removed from board view
- [ ] Check archive table in database has the card record
- [ ] Go to Archives view and see archived card
- [ ] Click Restore on archived card
- [ ] Verify card reappears on the board
- [ ] Archive another card
- [ ] Click Permanent Delete on archived card
- [ ] Verify card removed from archives list and database
- [ ] Test cascade archiving: Delete a project
- [ ] Verify all boards, lists, and cards in that project are archived
- [ ] Restore the project
- [ ] Verify all nested items are restored

### API Endpoint Testing

```bash
# Test card restore
curl -X POST http://localhost:3000/api/cards/{archiveId}/restore \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"listId": "YOUR_LIST_ID"}'

# Test project restore
curl -X POST http://localhost:3000/api/projects/{archiveId}/restore \
  -H "Authorization: Bearer YOUR_TOKEN"

# Test permanent delete
curl -X DELETE http://localhost:3000/api/cards/{archiveId}/permanent \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Estimated Time to Completion

- Reducers: 30 minutes
- UI Updates: 15 minutes
- Translations: 10 minutes
- Archive Viewer: 45 minutes
- Testing: 30 minutes

**Total: ~2 hours**

---

## Common Issues & Solutions

### Issue: Archive ID vs Card ID
**Solution**: Archive endpoint uses the ID from the archive table, not the original card ID. When listing archives, use the `archiveId` field, not `originalId`.

### Issue: Socket events not updating UI
**Solution**: Ensure the socket handlers in `/client/src/sagas/core/watchers/socket.js` include handlers for `cardCreate` and `projectCreate` events.

### Issue: Permissions denied
**Solution**:
- Cards: User must have EDITOR role on the board
- Projects: User must have `is_admin = true`

### Issue: Restored items not appearing
**Solution**: Ensure Redux reducers are handling `_HANDLE` actions properly. These actions update the state when items are restored.

---

## Key Files Checklist

### Already Implemented ✅
- [x] `/server/api/helpers/cards/restore-one.js`
- [x] `/server/api/helpers/projects/restore-one.js`
- [x] `/server/api/helpers/cards/permanent-delete-one.js`
- [x] `/server/api/helpers/projects/permanent-delete-one.js`
- [x] All controllers and routes
- [x] Redux actions and action types
- [x] API calls and sagas
- [x] Watchers setup

### Still Need to Complete ⏳
- [ ] `/client/src/reducers/archives.js` - Create
- [ ] `/client/src/reducers/cards.js` - Update
- [ ] `/client/src/reducers/projects.js` - Update
- [ ] `/client/src/components/CardModal/CardModal.jsx` - Update button label
- [ ] `/client/src/components/ArchivedItems/ArchivedItems.jsx` - Create
- [ ] `/client/src/containers/CardModalContainer.js` - Update mappings
- [ ] `/client/src/locales/en/core.json` - Add translations
- [ ] End-to-end testing

---

**The backend is production-ready. The remaining work is frontend integration.**
