import upperFirst from 'lodash/upperFirst';
import camelCase from 'lodash/camelCase';
import React, { useCallback, useMemo } from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';
import { useTranslation } from 'react-i18next';
import { Link, useNavigate } from 'react-router-dom';
import { Container, Grid, Icon } from 'semantic-ui-react';

import Paths from '../../constants/Paths';
import { ProjectBackgroundTypes } from '../../constants/Enums';
import { ReactComponent as PlusIcon } from '../../assets/images/plus-icon.svg';

import styles from './Projects.module.scss';
import globalStyles from '../../styles.module.scss';

const Projects = React.memo(({ items, canAdd, isAdmin, onAdd, onEditProject }) => {
  const [t] = useTranslation();
  const navigate = useNavigate();
  const today = useMemo(() => new Date(), []);

  const calendarData = useMemo(() => {
    const year = today.getFullYear();
    const month = today.getMonth();
    const firstDay = new Date(year, month, 1).getDay();
    const totalDays = new Date(year, month + 1, 0).getDate();
    const cells = Array(firstDay).fill(null);

    for (let day = 1; day <= totalDays; day += 1) {
      cells.push(day);
    }

    return {
      monthLabel: new Intl.DateTimeFormat(undefined, {
        month: 'long',
        year: 'numeric',
      }).format(today),
      weekDays: Array.from({ length: 7 }, (_, dayIndex) =>
        new Intl.DateTimeFormat(undefined, { weekday: 'short' }).format(
          new Date(2026, 1, 15 + dayIndex),
        ),
      ),
      cells,
      todayDay: today.getDate(),
    };
  }, [today]);

  const handleEditClick = useCallback(
    (e, item) => {
      e.preventDefault();
      e.stopPropagation();
      // Navigate to the project and open settings
      const projectPath = item.firstBoardId
        ? Paths.BOARDS.replace(':id', item.firstBoardId)
        : Paths.PROJECTS.replace(':id', item.id);
      navigate(projectPath);
      // Open the project settings modal
      onEditProject();
    },
    [navigate, onEditProject],
  );

  return (
    <Container className={styles.cardsWrapper}>
      <Grid className={styles.gridFix}>
        {items.map((item) => (
          <Grid.Column key={item.id} mobile={8} computer={4}>
            <Link
              to={
                item.firstBoardId
                  ? Paths.BOARDS.replace(':id', item.firstBoardId)
                  : Paths.PROJECTS.replace(':id', item.id)
              }
            >
              <div
                className={classNames(
                  styles.card,
                  styles.open,
                  item.background &&
                    item.background.type === ProjectBackgroundTypes.GRADIENT &&
                    globalStyles[`background${upperFirst(camelCase(item.background.name))}`],
                )}
                style={{
                  background:
                    item.background &&
                    item.background.type === 'image' &&
                    `url("${item.backgroundImage.coverUrl}") center / cover`,
                }}
              >
                {item.notificationsTotal > 0 && (
                  <span className={styles.notification}>{item.notificationsTotal}</span>
                )}
                <div className={styles.pastelTint} />
                <div className={styles.cardOverlay} />
                {isAdmin && (
                  <button
                    type="button"
                    className={styles.editButton}
                    onClick={(e) => handleEditClick(e, item)}
                    title={t('action.archiveProject', { context: 'title' })}
                  >
                    <Icon fitted name="pencil" className={styles.editIcon} />
                  </button>
                )}
                <div className={styles.openTitle}>{item.name}</div>
              </div>
            </Link>
          </Grid.Column>
        ))}
        {canAdd && (
          <Grid.Column mobile={8} computer={4}>
            <button type="button" className={classNames(styles.card, styles.add)} onClick={onAdd}>
              <div className={styles.addTitleWrapper}>
                <div className={styles.addTitle}>
                  <PlusIcon className={styles.addGridIcon} />
                  {t('action.createProject')}
                </div>
              </div>
            </button>
          </Grid.Column>
        )}
      </Grid>
      <section className={styles.teamCalendar} aria-label="Team calendar">
        <div className={styles.calendarHeader}>
          <h2 className={styles.calendarTitle}>Team Calendar</h2>
          <span className={styles.calendarMonth}>{calendarData.monthLabel}</span>
        </div>
        <div className={styles.calendarGrid} role="grid">
          {calendarData.weekDays.map((weekDay) => (
            <div key={weekDay} className={styles.weekDay}>
              {weekDay}
            </div>
          ))}
          {calendarData.cells.map((day, index) => {
            const key = day || `empty-${index}`;
            const isToday = day === calendarData.todayDay;

            return (
              <div key={key} className={classNames(styles.calendarCell, isToday && styles.today)}>
                {day ? <span>{day}</span> : null}
              </div>
            );
          })}
        </div>
        <p className={styles.calendarNote}>Shared monthly view for everyone on the team.</p>
      </section>
    </Container>
  );
});

Projects.propTypes = {
  items: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  canAdd: PropTypes.bool.isRequired,
  isAdmin: PropTypes.bool.isRequired,
  onAdd: PropTypes.func.isRequired,
  onEditProject: PropTypes.func.isRequired,
};

export default Projects;
