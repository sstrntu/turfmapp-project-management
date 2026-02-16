const path = require('path');
const dotenv = require('dotenv');
const _ = require('lodash');

dotenv.config({
  path: path.resolve(__dirname, '../.env'),
});

function buildSSLConfig() {
  // Always allow for Supabase connection
  return {
    rejectUnauthorized: false,
  };
}

module.exports = {
  client: 'pg',
  connection: {
    connectionString: process.env.DATABASE_URL,
    ssl: buildSSLConfig(),
  },
  searchPath: ['project_management_tool', 'public'],
  migrations: {
    tableName: 'migration',
    directory: path.join(__dirname, 'migrations'),
    schemaName: 'project_management_tool',
  },
  seeds: {
    directory: path.join(__dirname, 'seeds'),
  },
  wrapIdentifier: (value, origImpl) => origImpl(_.snakeCase(value)),
};
