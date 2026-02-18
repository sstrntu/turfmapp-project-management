module.exports = function defineDueDateReminderHook(sails) {
  const checkDueDateReminders = async () => {
    try {
      // Query cards that need due date reminders
      const cards = await Card.find({
        dueDate: { '!=': null },
        isDueDateCompleted: [false, null],
        isDueDateReminderSent: false,
        dueDateReminderMinutes: { '!=': null },
      });

      const now = new Date();

      for (const card of cards) {
        // Calculate when the reminder should be sent
        const dueDate = new Date(card.dueDate);
        const reminderTime = new Date(dueDate.getTime() - card.dueDateReminderMinutes * 60 * 1000);

        // Check if it's time to send the reminder and the due date hasn't passed
        if (now >= reminderTime && now < dueDate) {
          try {
            // Get card path (board, list, project)
            const path = await sails.helpers.cards.getProjectPath(card.id);
            if (!path) {
              continue;
            }

            const { board, list, project } = path;

            // Get card members
            const cardMemberships = await CardMembership.find({
              cardId: card.id,
            });

            const cardMemberUserIds = cardMemberships.map((membership) => membership.userId);

            // Get board members (potential watchers)
            const boardMemberships = await BoardMembership.find({
              boardId: board.id,
            });

            const boardMemberUserIds = boardMemberships.map((membership) => membership.userId);

            // Combine card members and board members, remove duplicates
            const notifiableUserIds = [...new Set([...cardMemberUserIds, ...boardMemberUserIds])];

            if (notifiableUserIds.length === 0) {
              continue;
            }

            // Use first user as the "actor" for the action (system notification)
            const systemUser = await User.findOne({ id: notifiableUserIds[0] });
            if (!systemUser) {
              continue;
            }

            // Create action for the reminder
            const action = await Action.create({
              cardId: card.id,
              userId: systemUser.id,
              type: Action.Types.DUE_DATE_REMINDER,
              data: {
                dueDate: card.dueDate,
              },
            }).fetch();

            // Create notifications for all relevant users
            for (const userId of notifiableUserIds) {
              const user = await User.findOne({ id: userId });
              if (!user) {
                continue;
              }

              await sails.helpers.notifications.createOne.with({
                values: {
                  user,
                  action,
                },
                project,
                board,
                list,
                card,
                actorUser: systemUser,
              });
            }

            // Mark reminder as sent
            await Card.updateOne({ id: card.id }).set({
              isDueDateReminderSent: true,
            });

            sails.log.info(`Due date reminder sent for card ${card.id}`);
          } catch (error) {
            sails.log.error(`Failed to send due date reminder for card ${card.id}:`, error);
          }
        }
      }
    } catch (error) {
      sails.log.error('Error in checkDueDateReminders:', error);
    }
  };

  return {
    async initialize() {
      sails.log.info('Initializing custom hook (`due-date-reminder`)');

      // Run every 60 seconds
      setInterval(checkDueDateReminders, 60 * 1000);

      // Run immediately on startup
      checkDueDateReminders();
    },
  };
};
