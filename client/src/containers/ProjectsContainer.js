import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';

import selectors from '../selectors';
import entryActions from '../entry-actions';
import Projects from '../components/Projects';

const mapStateToProps = (state) => {
  const { allowAllToCreateProjects } = selectors.selectConfig(state);
  const { isAdmin } = selectors.selectCurrentUser(state);
  const projects = selectors.selectProjectsForCurrentUser(state);
  const calendarDueCards = selectors.selectDueCardsForCurrentUser(state);
  const calendarMilestones = selectors.selectMilestonesForCurrentUser(state);
  const projectsToLists = selectors.selectProjectsToListsForCurrentUser(state);

  return {
    items: projects,
    calendarDueCards,
    calendarMilestones,
    projectsToLists,
    canAdd: allowAllToCreateProjects || isAdmin,
    isAdmin,
  };
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      onAdd: entryActions.openProjectAddModal,
      onEditProject: entryActions.openProjectSettingsModal,
    },
    dispatch,
  );

export default connect(mapStateToProps, mapDispatchToProps)(Projects);
