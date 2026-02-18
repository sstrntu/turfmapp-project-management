module.exports.up = async (knex) => {
  await knex.schema.table('card', (table) => {
    /* Columns */

    table.string('color', 7); // Hex color code, nullable (null = default white)
  });
};

module.exports.down = (knex) =>
  knex.schema.table('card', (table) => {
    table.dropColumn('color');
  });
