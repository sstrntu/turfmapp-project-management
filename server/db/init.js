const initKnex = require('knex');

const knexfile = require('./knexfile');

const knex = initKnex(knexfile);

(async () => {
  try {
    // Set search_path for the connection
    await knex.raw('SET search_path = project_management_tool, public;');

    await knex.migrate.latest();
    await knex.seed.run();
  } catch (error) {
    process.exitCode = 1;

    throw error;
  } finally {
    knex.destroy();
  }
})();
