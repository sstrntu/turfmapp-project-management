import React, { useEffect, useMemo } from 'react';
import PropTypes from 'prop-types';
import { useTranslation } from 'react-i18next';
import { Item, Modal, Tab, Message, Button, Icon } from 'semantic-ui-react';

import ArchivedItemCard from './ArchivedItemCard';
import styles from './ArchivedItems.module.scss';

const ArchivedItems = React.memo(
  ({
    isOpen,
    archivedCards,
    archivedProjects,
    isFetching,
    onClose,
    onRestoreCard,
    onRestoreProject,
    onPermanentDeleteCard,
    onPermanentDeleteProject,
    onFetch,
  }) => {
    const [t] = useTranslation();

    useEffect(() => {
      if (isOpen && onFetch) {
        onFetch();
      }
    }, [isOpen, onFetch]);

    const cardsPane = useMemo(
      () => ({
        menuItem: t('common.archivedCards'),
        render: () => (
          <Tab.Pane>
            <div className={styles.tabContent}>
              {archivedCards.length === 0 ? (
                <Message info>{t('common.noArchivedItems')}</Message>
              ) : (
                <Item.Group divided>
                  {archivedCards.map((card) => (
                    <ArchivedItemCard
                      key={card.id}
                      item={card}
                      type="card"
                      onRestore={onRestoreCard}
                      onPermanentDelete={onPermanentDeleteCard}
                    />
                  ))}
                </Item.Group>
              )}
            </div>
          </Tab.Pane>
        ),
      }),
      [archivedCards, t, onRestoreCard, onPermanentDeleteCard],
    );

    const projectsPane = useMemo(
      () => ({
        menuItem: t('common.archivedProjects'),
        render: () => (
          <Tab.Pane>
            <div className={styles.tabContent}>
              {archivedProjects.length === 0 ? (
                <Message info>{t('common.noArchivedItems')}</Message>
              ) : (
                <Item.Group divided>
                  {archivedProjects.map((project) => (
                    <ArchivedItemCard
                      key={project.id}
                      item={project}
                      type="project"
                      onRestore={onRestoreProject}
                      onPermanentDelete={onPermanentDeleteProject}
                    />
                  ))}
                </Item.Group>
              )}
            </div>
          </Tab.Pane>
        ),
      }),
      [archivedProjects, t, onRestoreProject, onPermanentDeleteProject],
    );

    const panes = [projectsPane, cardsPane];

    return (
      <Modal open={isOpen} onClose={onClose} size="large" className={styles.wrapper}>
        <Modal.Header className={styles.header}>
          <Icon name="archive" />
          {t('common.archivedItems')}
        </Modal.Header>
        <Modal.Content scrolling>
          {isFetching && (
            <Message info loading>
              {t('common.loading')}
            </Message>
          )}
          {!isFetching && <Tab panes={panes} />}
        </Modal.Content>
        <Modal.Actions>
          <Button onClick={onClose}>{t('common.close')}</Button>
        </Modal.Actions>
      </Modal>
    );
  },
);

ArchivedItems.propTypes = {
  isOpen: PropTypes.bool.isRequired,
  // eslint-disable-next-line react/forbid-prop-types
  archivedCards: PropTypes.arrayOf(PropTypes.object).isRequired,
  // eslint-disable-next-line react/forbid-prop-types
  archivedProjects: PropTypes.arrayOf(PropTypes.object).isRequired,
  isFetching: PropTypes.bool.isRequired,
  onClose: PropTypes.func.isRequired,
  onRestoreCard: PropTypes.func.isRequired,
  onRestoreProject: PropTypes.func.isRequired,
  onPermanentDeleteCard: PropTypes.func.isRequired,
  onPermanentDeleteProject: PropTypes.func.isRequired,
  onFetch: PropTypes.func,
};

ArchivedItems.defaultProps = {
  onFetch: null,
};

export default ArchivedItems;
