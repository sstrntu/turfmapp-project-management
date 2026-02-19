module.exports.up = async (knex) => {
  await knex.schema.table('user_account', (table) => {
    table.jsonb('skills').notNullable().defaultTo(knex.raw("'[]'::jsonb"));
  });
};

module.exports.down = (knex) =>
  knex.schema.table('user_account', (table) => {
    table.dropColumn('skills');
  });
