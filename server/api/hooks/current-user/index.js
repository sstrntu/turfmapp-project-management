/**
 * current-user hook
 *
 * @description :: A hook definition. Extends Sails by adding shadow routes, implicit actions,
 *                 and/or initialization logic.
 * @docs        :: https://sailsjs.com/docs/concepts/extending-sails/hooks
 */

module.exports = function defineCurrentUserHook(sails) {
  const TOKEN_PATTERN = /^Bearer /;

  const getSessionAndUser = async (accessToken, httpOnlyToken) => {
    let payload;
    try {
      payload = sails.helpers.utils.verifyJwtToken(accessToken);
      sails.log.info(`[JWT] Verified token, subject: ${payload.subject}`);
    } catch (error) {
      sails.log.error(`[JWT] Verification failed: ${error.message}`);
      return null;
    }

    sails.log.info(`[SESSION] Looking for session with token: ${accessToken.substring(0, 20)}...`);
    const session = await Session.findOne({
      accessToken,
      deletedAt: null,
    });

    if (!session) {
      sails.log.warn(`[SESSION] No session found for token`);
      return null;
    }

    sails.log.info(`[SESSION] Found session: ${session.id}`);

    // If session has httpOnlyToken, only require it if httpOnlyToken was provided
    // (i.e., allow Bearer token access even if httpOnlyToken is required for cookie-based auth)
    if (session.httpOnlyToken && httpOnlyToken && httpOnlyToken !== session.httpOnlyToken) {
      sails.log.warn(`[SESSION] httpOnlyToken mismatch`);
      return null;
    }

    sails.log.info(`[USER] Getting user for ID: ${payload.subject}`);
    const user = await sails.helpers.users.getOne(payload.subject);

    if (!user) {
      sails.log.warn(`[USER] User not found`);
      return null;
    }

    if (user.passwordChangedAt > payload.issuedAt) {
      sails.log.warn(`[USER] Password changed after token issued`);
      return null;
    }

    sails.log.info(`[AUTH] Successfully authenticated user: ${user.email}`);
    return {
      session,
      user,
    };
  };

  return {
    /**
     * Runs when this Sails app loads/lifts.
     */

    async initialize() {
      sails.log.info('Initializing custom hook (`current-user`)');
    },

    routes: {
      before: {
        '/api/*': {
          async fn(req, res, next) {
            const { authorization: authorizationHeader } = req.headers;

            if (authorizationHeader && TOKEN_PATTERN.test(authorizationHeader)) {
              const accessToken = authorizationHeader.replace(TOKEN_PATTERN, '');
              const { httpOnlyToken } = req.cookies;

              const sessionAndUser = await getSessionAndUser(accessToken, httpOnlyToken);

              if (sessionAndUser) {
                const { session, user } = sessionAndUser;

                Object.assign(req, {
                  currentSession: session,
                  currentUser: user,
                });

                if (req.isSocket) {
                  sails.sockets.join(req, `@accessToken:${session.accessToken}`);
                  sails.sockets.join(req, `@user:${user.id}`);
                }
              }
            }

            return next();
          },
        },
        '/attachments/*': {
          async fn(req, res, next) {
            const { accessToken: cookieAccessToken, httpOnlyToken } = req.cookies;
            const { authorization: authorizationHeader } = req.headers;

            sails.log.info(`[ATTACH-AUTH] Path: ${req.path}, Cookie token: ${cookieAccessToken ? 'yes' : 'no'}, Auth header: ${authorizationHeader ? 'yes' : 'no'}, Headers: ${JSON.stringify(req.headers)}`);

            // Try to get accessToken from cookie first, then from Authorization header
            let accessToken = cookieAccessToken;
            if (!accessToken && authorizationHeader && TOKEN_PATTERN.test(authorizationHeader)) {
              accessToken = authorizationHeader.replace(TOKEN_PATTERN, '');
              sails.log.info(`[ATTACH-AUTH] Using Bearer token: ${accessToken.substring(0, 20)}...`);
            }

            if (accessToken) {
              sails.log.info(`[ATTACH-AUTH] Verifying session for token: ${accessToken.substring(0, 20)}...`);
              const sessionAndUser = await getSessionAndUser(accessToken, httpOnlyToken);

              if (sessionAndUser) {
                const { session, user } = sessionAndUser;
                sails.log.info(`[ATTACH-AUTH] Found user: ${user.email}`);

                Object.assign(req, {
                  currentSession: session,
                  currentUser: user,
                });
              } else {
                sails.log.warn(`[ATTACH-AUTH] No session/user found for token`);
              }
            } else {
              sails.log.warn(`[ATTACH-AUTH] No access token found`);
            }

            return next();
          },
        },
      },
    },
  };
};
