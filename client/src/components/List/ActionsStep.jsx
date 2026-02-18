import React, { useCallback } from 'react';
import PropTypes from 'prop-types';
import { useTranslation } from 'react-i18next';
import { Menu } from 'semantic-ui-react';
import { Popup } from '../../lib/custom-ui';

import { useSteps } from '../../hooks';
import ListSortStep from '../ListSortStep';
import ColorPicker from '../ColorPicker';
import DeleteStep from '../DeleteStep';

import styles from './ActionsStep.module.scss';

const StepTypes = {
  DELETE: 'DELETE',
  SORT: 'SORT',
  COLOR: 'COLOR',
};

const ActionsStep = React.memo(
  ({ color, onNameEdit, onCardAdd, onSort, onColorUpdate, onDelete, onClose }) => {
  const [t] = useTranslation();
  const [step, openStep, handleBack] = useSteps();

  const handleEditNameClick = useCallback(() => {
    onNameEdit();
    onClose();
  }, [onNameEdit, onClose]);

  const handleAddCardClick = useCallback(() => {
    onCardAdd();
    onClose();
  }, [onCardAdd, onClose]);

  const handleSortClick = useCallback(() => {
    openStep(StepTypes.SORT);
  }, [openStep]);

  const handleColorClick = useCallback(() => {
    openStep(StepTypes.COLOR);
  }, [openStep]);

  const handleColorSelect = useCallback(
    (selectedColor) => {
      onColorUpdate(selectedColor);
      onClose();
    },
    [onColorUpdate, onClose],
  );

  const handleDeleteClick = useCallback(() => {
    openStep(StepTypes.DELETE);
  }, [openStep]);

  const handleSortTypeSelect = useCallback(
    (type) => {
      onSort({
        type,
      });

      onClose();
    },
    [onSort, onClose],
  );

  if (step && step.type) {
    switch (step.type) {
      case StepTypes.SORT:
        return <ListSortStep onTypeSelect={handleSortTypeSelect} onBack={handleBack} />;
      case StepTypes.COLOR:
        return (
          <>
            <Popup.Header onBack={handleBack}>
              {t('common.selectColor', { context: 'title' })}
            </Popup.Header>
            <Popup.Content>
              <ColorPicker value={color} onSelect={handleColorSelect} />
            </Popup.Content>
          </>
        );
      case StepTypes.DELETE:
        return (
          <DeleteStep
            title="common.deleteList"
            content="common.areYouSureYouWantToDeleteThisList"
            buttonContent="action.deleteList"
            onConfirm={onDelete}
            onBack={handleBack}
          />
        );
      default:
    }
  }

  return (
    <>
      <Popup.Header>
        {t('common.listActions', {
          context: 'title',
        })}
      </Popup.Header>
      <Popup.Content>
        <Menu secondary vertical className={styles.menu}>
          <Menu.Item className={styles.menuItem} onClick={handleEditNameClick}>
            {t('action.editTitle', {
              context: 'title',
            })}
          </Menu.Item>
          <Menu.Item className={styles.menuItem} onClick={handleAddCardClick}>
            {t('action.addCard', {
              context: 'title',
            })}
          </Menu.Item>
          <Menu.Item className={styles.menuItem} onClick={handleSortClick}>
            {t('action.sortList', {
              context: 'title',
            })}
          </Menu.Item>
          <Menu.Item className={styles.menuItem} onClick={handleColorClick}>
            {t('common.color', {
              context: 'title',
            })}
          </Menu.Item>
          <Menu.Item className={styles.menuItem} onClick={handleDeleteClick}>
            {t('action.deleteList', {
              context: 'title',
            })}
          </Menu.Item>
        </Menu>
      </Popup.Content>
    </>
  );
});

    ActionsStep.propTypes = {
      color: PropTypes.string,
      onNameEdit: PropTypes.func.isRequired,
      onCardAdd: PropTypes.func.isRequired,
      onDelete: PropTypes.func.isRequired,
      onSort: PropTypes.func.isRequired,
      onColorUpdate: PropTypes.func.isRequired,
      onClose: PropTypes.func.isRequired,
    };

    ActionsStep.defaultProps = {
      color: null,
    };

    export default ActionsStep;
