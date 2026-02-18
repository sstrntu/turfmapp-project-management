module.exports.up = async (knex) => {
  await knex.schema.table('list', (table) => {
    /* Columns */

    table.string('color', 7).defaultTo('#dfe3e6'); // Hex color code
  });
};

module.exports.down = (knex) =>
  knex.schema.table('list', (table) => {
    table.dropColumn('color');
  });
