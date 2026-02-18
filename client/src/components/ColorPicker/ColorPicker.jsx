import React, { useCallback } from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';

import styles from './ColorPicker.module.scss';

const COLORS = [
  { name: 'Blue', value: '#4A90E2' },
  { name: 'Green', value: '#7ED321' },
  { name: 'Red', value: '#D0021B' },
  { name: 'Yellow', value: '#F8E71C' },
  { name: 'Orange', value: '#F5A623' },
  { name: 'Purple', value: '#9013FE' },
  { name: 'Pink', value: '#FF6B9D' },
  { name: 'Teal', value: '#50E3C2' },
  { name: 'Gray', value: '#9B9B9B' },
  { name: 'Light Gray', value: '#DFE3E6' },
];

const ColorPicker = React.memo(({ value, onSelect }) => {
  const handleColorClick = useCallback(
    (color) => {
      onSelect(color);
    },
    [onSelect],
  );

  return (
    <div className={styles.wrapper}>
      {COLORS.map((color) => (
        <button
          key={color.value}
          type="button"
          className={classNames(styles.colorButton, {
            [styles.colorButtonActive]: value === color.value,
          })}
          style={{ backgroundColor: color.value }}
          onClick={() => handleColorClick(color.value)}
          title={color.name}
        >
          {value === color.value && <span className={styles.checkmark}>✓</span>}
        </button>
      ))}
    </div>
  );
});

ColorPicker.propTypes = {
  value: PropTypes.string,
  onSelect: PropTypes.func.isRequired,
};

ColorPicker.defaultProps = {
  value: null,
};

export default ColorPicker;
