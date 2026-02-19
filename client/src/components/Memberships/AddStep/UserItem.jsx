import React from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';

import User from '../../User';

import styles from './UserItem.module.scss';

const UserItem = React.memo(({ name, avatarUrl, skills, isActive, onSelect }) => {
  const skillsText = Array.isArray(skills) && skills.length > 0 ? skills.join(', ') : null;

  return (
    <button type="button" disabled={isActive} className={styles.menuItem} onClick={onSelect}>
      <span className={styles.user}>
        <User name={name} avatarUrl={avatarUrl} />
      </span>
      <div className={classNames(styles.menuItemText, isActive && styles.menuItemTextActive)}>
        <div className={styles.primaryText}>{name}</div>
        {skillsText && <div className={styles.skillsText}>{skillsText}</div>}
      </div>
    </button>
  );
});

UserItem.propTypes = {
  name: PropTypes.string.isRequired,
  avatarUrl: PropTypes.string,
  skills: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  isActive: PropTypes.bool.isRequired,
  onSelect: PropTypes.func.isRequired,
};

UserItem.defaultProps = {
  avatarUrl: undefined,
  skills: undefined,
};

export default UserItem;
