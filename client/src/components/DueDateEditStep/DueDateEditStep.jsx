import React, { useCallback, useEffect, useMemo, useRef } from 'react';
import PropTypes from 'prop-types';
import { useTranslation } from 'react-i18next';
import DatePicker from 'react-datepicker';
import { Button, Form, Dropdown } from 'semantic-ui-react';
import { useDidUpdate, useToggle } from '../../lib/hooks';
import { Input, Popup } from '../../lib/custom-ui';

import { useForm } from '../../hooks';
import parseTime from '../../utils/parse-time';

import styles from './DueDateEditStep.module.scss';

const DueDateEditStep = React.memo(
  ({ defaultValue, defaultReminder, onUpdate, onBack, onClose }) => {
  const [t] = useTranslation();

  const [data, handleFieldChange, setData] = useForm(() => {
    const date = defaultValue || new Date().setHours(12, 0, 0, 0);

    return {
      date: t('format:date', {
        postProcess: 'formatDate',
        value: date,
      }),
      time: t('format:time', {
        postProcess: 'formatDate',
        value: date,
      }),
      reminder: defaultReminder !== undefined && defaultReminder !== null ? String(defaultReminder) : '1440',
    };
  });

  const [selectTimeFieldState, selectTimeField] = useToggle();

  const dateField = useRef(null);
  const timeField = useRef(null);

  const nullableDate = useMemo(() => {
    const date = t('format:date', {
      postProcess: 'parseDate',
      value: data.date,
    });

    if (Number.isNaN(date.getTime())) {
      return null;
    }

    return date;
  }, [data.date, t]);

  const handleDatePickerChange = useCallback(
    (date) => {
      setData((prevData) => ({
        ...prevData,
        date: t('format:date', {
          postProcess: 'formatDate',
          value: date,
        }),
      }));
      selectTimeField();
    },
    [setData, selectTimeField, t],
  );

  const handleSubmit = useCallback(() => {
    if (!nullableDate) {
      dateField.current.select();
      return;
    }

    let value = t('format:dateTime', {
      postProcess: 'parseDate',
      value: `${data.date} ${data.time}`,
    });

    if (Number.isNaN(value.getTime())) {
      value = parseTime(data.time, nullableDate);

      if (Number.isNaN(value.getTime())) {
        timeField.current.select();
        return;
      }
    }

    const reminderMinutes = data.reminder === 'null' ? null : parseInt(data.reminder, 10);

    const dateChanged = !defaultValue || value.getTime() !== defaultValue.getTime();
    const reminderChanged = reminderMinutes !== defaultReminder;

    if (dateChanged || reminderChanged) {
      onUpdate(value, reminderMinutes);
    }

    onClose();
  }, [defaultValue, defaultReminder, onUpdate, onClose, data, nullableDate, t]);

  const handleClearClick = useCallback(() => {
    if (defaultValue) {
      onUpdate(null);
    }

    onClose();
  }, [defaultValue, onUpdate, onClose]);

  useEffect(() => {
    dateField.current.select();
  }, []);

  useDidUpdate(() => {
    timeField.current.select();
  }, [selectTimeFieldState]);

  return (
    <>
      <Popup.Header onBack={onBack}>
        {t('common.editDueDate', {
          context: 'title',
        })}
      </Popup.Header>
      <Popup.Content>
        <Form onSubmit={handleSubmit}>
          <div className={styles.fieldWrapper}>
            <div className={styles.fieldBox}>
              <div className={styles.text}>{t('common.date')}</div>
              <Input ref={dateField} name="date" value={data.date} onChange={handleFieldChange} />
            </div>
            <div className={styles.fieldBox}>
              <div className={styles.text}>{t('common.time')}</div>
              <Input ref={timeField} name="time" value={data.time} onChange={handleFieldChange} />
            </div>
          </div>
          <DatePicker
            inline
            disabledKeyboardNavigation
            selected={nullableDate}
            onChange={handleDatePickerChange}
          />
          <div className={styles.fieldWrapper}>
            <div className={styles.text}>{t('common.reminder')}</div>
            <Dropdown
              fluid
              selection
              name="reminder"
              value={data.reminder}
              options={[
                { key: 'null', value: 'null', text: t('common.none') },
                { key: '15', value: '15', text: t('common.minutesBefore', { count: 15 }) },
                { key: '60', value: '60', text: t('common.hoursBefore', { count: 1 }) },
                { key: '1440', value: '1440', text: t('common.hoursBefore', { count: 24 }) },
                { key: '2880', value: '2880', text: t('common.daysBefore', { count: 2 }) },
                { key: '10080', value: '10080', text: t('common.weeksBefore', { count: 1 }) },
              ]}
              onChange={(e, { value }) => handleFieldChange({ target: { name: 'reminder', value } })}
            />
          </div>
          <Button positive content={t('action.save')} />
        </Form>
        <Button
          negative
          content={t('action.remove')}
          className={styles.deleteButton}
          onClick={handleClearClick}
        />
      </Popup.Content>
    </>
  );
  },
);

DueDateEditStep.propTypes = {
  defaultValue: PropTypes.instanceOf(Date),
  defaultReminder: PropTypes.number,
  onUpdate: PropTypes.func.isRequired,
  onBack: PropTypes.func,
  onClose: PropTypes.func.isRequired,
};

DueDateEditStep.defaultProps = {
  defaultValue: undefined,
  defaultReminder: 1440,
  onBack: undefined,
};

export default DueDateEditStep;
