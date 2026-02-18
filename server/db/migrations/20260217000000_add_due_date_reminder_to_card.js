module.exports.up = async (knex) => {
  await knex.schema.table('card', (table) => {
    /* Columns */

    table.integer('due_date_reminder_minutes').defaultTo(1440);
    table.boolean('is_due_date_reminder_sent').defaultTo(false);
  });
};

module.exports.down = (knex) =>
  knex.schema.table('card', (table) => {
    table.dropColumn('due_date_reminder_minutes');
    table.dropColumn('is_due_date_reminder_sent');
  });
