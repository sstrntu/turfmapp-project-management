import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';

import ModalTypes from '../constants/ModalTypes';
import entryActions from '../entry-actions';
import selectors from '../selectors';
import ArchivedItems from '../components/ArchivedItems';

const mapStateToProps = (state) => {
  const currentModal = selectors.selectCurrentModal(state);
  const archivedCards = selectors.selectArchivedCards(state);
  const archivedProjects = selectors.selectArchivedProjects(state);
  const { isFetching } = state.archives || { isFetching: false };

  return {
    isOpen: currentModal === ModalTypes.ARCHIVED_ITEMS,
    isFetching,
    archivedCards: archivedCards || [],
    archivedProjects: archivedProjects || [],
  };
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      onClose: entryActions.closeArchivedItemsModal,
      onFetch: entryActions.fetchArchivedItems,
      onRestoreCard: entryActions.restoreCard,
      onRestoreProject: entryActions.restoreProject,
      onPermanentDeleteCard: entryActions.permanentDeleteCard,
      onPermanentDeleteProject: entryActions.permanentDeleteProject,
    },
    dispatch,
  );

export default connect(mapStateToProps, mapDispatchToProps)(ArchivedItems);
