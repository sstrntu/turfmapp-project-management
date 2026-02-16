const bcrypt = require('bcrypt');

const buildData = () => {
  const data = {
    isAdmin: true,
    isSso: false,
  };

  if (process.env.DEFAULT_ADMIN_PASSWORD) {
    data.password = bcrypt.hashSync(process.env.DEFAULT_ADMIN_PASSWORD, 10);
  }
  if (process.env.DEFAULT_ADMIN_NAME) {
    data.name = process.env.DEFAULT_ADMIN_NAME;
  }
  if (process.env.DEFAULT_ADMIN_USERNAME) {
    data.username = process.env.DEFAULT_ADMIN_USERNAME.toLowerCase();
  }

  return data;
};

exports.seed = async (knex) => {
  if (!process.env.DEFAULT_ADMIN_EMAIL) {
    return;
  }

  const email = process.env.DEFAULT_ADMIN_EMAIL.toLowerCase();
  const username = process.env.DEFAULT_ADMIN_USERNAME?.toLowerCase() || 'admin';
  const data = buildData();

  try {
    // Check if user already exists by email or username
    const existing = await knex('user_account')
      .where('email', email)
      .orWhere('username', username)
      .first();

    if (!existing) {
      // Only insert if user doesn't exist
      await knex('user_account').insert({
        ...data,
        email,
        subscribeToOwnCards: false,
        createdAt: new Date().toISOString(),
      });
    } else {
      // Update existing user with default admin data
      await knex('user_account').update(data).where('email', email);
    }
  } catch (error) {
    // Silently catch errors - user might already exist
    console.warn('Seed error:', error.message);
  }
};
