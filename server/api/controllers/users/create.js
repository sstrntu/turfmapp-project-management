const zxcvbn = require('zxcvbn');

const Errors = {
  NOT_ENOUGH_RIGHTS: {
    notEnoughRights: 'Not enough rights',
  },
  EMAIL_ALREADY_IN_USE: {
    emailAlreadyInUse: 'Email already in use',
  },
  USERNAME_ALREADY_IN_USE: {
    usernameAlreadyInUse: 'Username already in use',
  },
};

const passwordValidator = (value) => zxcvbn(value).score >= 2; // TODO: move to config
const MAX_SKILLS = 25;
const MAX_SKILL_LENGTH = 64;

const normalizeSkills = (skills) => {
  if (!_.isArray(skills)) {
    return [];
  }

  const unique = new Set();

  return skills.reduce((result, skillValue) => {
    const skill = String(skillValue || '').trim();

    if (!skill) {
      return result;
    }

    const key = skill.toLowerCase();

    if (unique.has(key)) {
      return result;
    }

    unique.add(key);
    result.push(skill);

    return result;
  }, []);
};

const skillsValidator = (value) =>
  _.isNull(value) ||
  (_.isArray(value) &&
    value.length <= MAX_SKILLS &&
    value.every(
      (skill) =>
        _.isString(skill) && skill.trim().length > 0 && skill.trim().length <= MAX_SKILL_LENGTH,
    ));

module.exports = {
  inputs: {
    email: {
      type: 'string',
      isEmail: true,
      required: true,
    },
    password: {
      type: 'string',
      custom: passwordValidator,
      required: true,
    },
    name: {
      type: 'string',
      required: true,
    },
    username: {
      type: 'string',
      isNotEmptyString: true,
      minLength: 3,
      maxLength: 16,
      regex: /^[a-zA-Z0-9]+((_|\.)?[a-zA-Z0-9])*$/,
      allowNull: true,
    },
    phone: {
      type: 'string',
      isNotEmptyString: true,
      allowNull: true,
    },
    organization: {
      type: 'string',
      isNotEmptyString: true,
      allowNull: true,
    },
    skills: {
      type: 'json',
      custom: skillsValidator,
    },
    language: {
      type: 'string',
      isIn: User.LANGUAGES,
      allowNull: true,
    },
    subscribeToOwnCards: {
      type: 'boolean',
    },
  },

  exits: {
    notEnoughRights: {
      responseType: 'forbidden',
    },
    emailAlreadyInUse: {
      responseType: 'conflict',
    },
    usernameAlreadyInUse: {
      responseType: 'conflict',
    },
  },

  async fn(inputs) {
    const { currentUser } = this.req;

    if (sails.config.custom.oidcEnforced) {
      throw Errors.NOT_ENOUGH_RIGHTS;
    }

    const values = _.pick(inputs, [
      'email',
      'password',
      'name',
      'username',
      'phone',
      'organization',
      'language',
      'subscribeToOwnCards',
    ]);

    if (!_.isUndefined(inputs.skills)) {
      values.skills = normalizeSkills(inputs.skills);
    }

    const user = await sails.helpers.users.createOne
      .with({
        values,
        actorUser: currentUser,
        request: this.req,
      })
      .intercept('emailAlreadyInUse', () => Errors.EMAIL_ALREADY_IN_USE)
      .intercept('usernameAlreadyInUse', () => Errors.USERNAME_ALREADY_IN_USE);

    return {
      item: user,
    };
  },
};
