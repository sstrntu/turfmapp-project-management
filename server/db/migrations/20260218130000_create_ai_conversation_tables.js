module.exports.up = (knex) =>
  knex.schema
    .createTable('ai_session', (table) => {
      /* Columns */

      table.bigInteger('id').primary().defaultTo(knex.raw('next_id()'));

      table.text('public_id').notNullable();
      table.bigInteger('user_id').notNullable();
      table.text('channel').notNullable();
      table.jsonb('context');

      table.timestamp('created_at', true);
      table.timestamp('updated_at', true);

      /* Indexes */

      table.unique('public_id');
      table.index('user_id');
      table.index('channel');
      table.index(['user_id', 'channel']);
    })
    .createTable('ai_message', (table) => {
      /* Columns */

      table.bigInteger('id').primary().defaultTo(knex.raw('next_id()'));

      table.bigInteger('ai_session_id').notNullable();
      table.text('role').notNullable();
      table.text('content').notNullable();
      table.jsonb('metadata').notNullable().defaultTo('{}');

      table.timestamp('created_at', true);
      table.timestamp('updated_at', true);

      /* Indexes */

      table.index('ai_session_id');
      table.index(['ai_session_id', 'id']);
    })
    .createTable('ai_plan', (table) => {
      /* Columns */

      table.bigInteger('id').primary().defaultTo(knex.raw('next_id()'));

      table.text('public_id').notNullable();
      table.bigInteger('ai_session_id').notNullable();
      table.bigInteger('user_id').notNullable();
      table.text('channel').notNullable();
      table.text('message');
      table.jsonb('actions').notNullable();
      table.jsonb('context');
      table.text('status').notNullable().defaultTo('pending');
      table.jsonb('execution_results');

      table.timestamp('created_at', true);
      table.timestamp('updated_at', true);

      /* Indexes */

      table.unique('public_id');
      table.index('ai_session_id');
      table.index('user_id');
      table.index('status');
      table.index(['ai_session_id', 'status']);
    });

module.exports.down = (knex) =>
  knex.schema.dropTable('ai_plan').dropTable('ai_message').dropTable('ai_session');
