import React, { useCallback } from 'react';
import PropTypes from 'prop-types';
import { useTranslation } from 'react-i18next';
import { Button, Icon, Item } from 'semantic-ui-react';

import styles from './ArchivedItemCard.module.scss';

const ArchivedItemCard = React.memo(({ item, type, onRestore, onPermanentDelete }) => {
  const [t] = useTranslation();

  const handleRestoreClick = useCallback(() => {
    onRestore(item.id);
  }, [item.id, onRestore]);

  const handleDeleteClick = useCallback(() => {
    onPermanentDelete(item.id);
  }, [item.id, onPermanentDelete]);

  const getItemTitle = () => {
    return item.name || item.title || t('common.untitled');
  };

  const getItemDescription = () => {
    if (type === 'card') {
      return `${t('common.list')}: ${item.listName || t('common.unknown')}`;
    }
    if (type === 'project') {
      return `${t('common.boards')}: ${item.boardCount || 0}`;
    }
    return '';
  };

  return (
    <Item className={styles.itemCard}>
      <Item.Content>
        <Item.Header>{getItemTitle()}</Item.Header>
        <Item.Meta>{getItemDescription()}</Item.Meta>
        <Item.Description>
          {t('common.archived')}: {new Date(item.createdAt).toLocaleDateString()}
        </Item.Description>
        <Item.Extra>
          <Button
            size="small"
            basic
            color="green"
            onClick={handleRestoreClick}
            className={styles.actionButton}
          >
            <Icon name="undo" />
            {t('action.restore')}
          </Button>
          <Button
            size="small"
            basic
            color="red"
            onClick={handleDeleteClick}
            className={styles.actionButton}
          >
            <Icon name="trash" />
            {t('action.delete')}
          </Button>
        </Item.Extra>
      </Item.Content>
    </Item>
  );
});

ArchivedItemCard.propTypes = {
  // eslint-disable-next-line react/forbid-prop-types
  item: PropTypes.object.isRequired,
  type: PropTypes.oneOf(['card', 'project']).isRequired,
  onRestore: PropTypes.func.isRequired,
  onPermanentDelete: PropTypes.func.isRequired,
};

export default ArchivedItemCard;
