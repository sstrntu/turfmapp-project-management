import isEmail from 'validator/lib/isEmail';
import React, { useCallback, useEffect, useMemo, useRef } from 'react';
import PropTypes from 'prop-types';
import { useTranslation } from 'react-i18next';
import { Button, Form, Message } from 'semantic-ui-react';
import { useDidUpdate, usePrevious, useToggle } from '../../lib/hooks';
import { Input } from '../../lib/custom-ui';

import { useForm } from '../../hooks';
import { isUsername } from '../../utils/validator';

import styles from './Login.module.scss';

const createMessage = (error) => {
  if (!error) {
    return error;
  }

  switch (error.message) {
    case 'Invalid credentials':
      return {
        type: 'error',
        content: 'common.invalidCredentials',
      };
    case 'Invalid email or username':
      return {
        type: 'error',
        content: 'common.invalidEmailOrUsername',
      };
    case 'Invalid password':
      return {
        type: 'error',
        content: 'common.invalidPassword',
      };
    case 'Use single sign-on':
      return {
        type: 'error',
        content: 'common.useSingleSignOn',
      };
    case 'Email already in use':
      return {
        type: 'error',
        content: 'common.emailAlreadyInUse',
      };
    case 'Username already in use':
      return {
        type: 'error',
        content: 'common.usernameAlreadyInUse',
      };
    case 'Failed to fetch':
      return {
        type: 'warning',
        content: 'common.noInternetConnection',
      };
    case 'Network request failed':
      return {
        type: 'warning',
        content: 'common.serverConnectionFailed',
      };
    default:
      return {
        type: 'warning',
        content: 'common.unknownError',
      };
  }
};

const Login = React.memo(
  ({
    defaultData,
    isSubmitting,
    isSubmittingUsingOidc,
    error,
    withOidc,
    isOidcEnforced,
    onAuthenticate,
    onAuthenticateUsingOidc,
    onMessageDismiss,
  }) => {
    const [t] = useTranslation();
    const wasSubmitting = usePrevious(isSubmitting);

    const [data, handleFieldChange, setData] = useForm(() => ({
      emailOrUsername: '',
      password: '',
      ...defaultData,
    }));

    const message = useMemo(() => createMessage(error), [error]);
    const [focusPasswordFieldState, focusPasswordField] = useToggle();

    const emailOrUsernameField = useRef(null);
    const passwordField = useRef(null);

    const handleSubmit = useCallback(() => {
      const cleanData = {
        ...data,
        emailOrUsername: data.emailOrUsername.trim(),
      };

      if (!isEmail(cleanData.emailOrUsername) && !isUsername(cleanData.emailOrUsername)) {
        emailOrUsernameField.current.select();
        return;
      }

      if (!cleanData.password) {
        passwordField.current.focus();
        return;
      }

      onAuthenticate(cleanData);
    }, [onAuthenticate, data]);

    useEffect(() => {
      if (!isOidcEnforced) {
        emailOrUsernameField.current.focus();
      }
    }, [isOidcEnforced]);

    useEffect(() => {
      if (wasSubmitting && !isSubmitting && error) {
        switch (error.message) {
          case 'Invalid credentials':
          case 'Invalid email or username':
            emailOrUsernameField.current.select();

            break;
          case 'Invalid password':
            setData((prevData) => ({
              ...prevData,
              password: '',
            }));
            focusPasswordField();

            break;
          default:
        }
      }
    }, [isSubmitting, wasSubmitting, error, setData, focusPasswordField]);

    useDidUpdate(() => {
      passwordField.current.focus();
    }, [focusPasswordFieldState]);

    return (
      <div className={styles.pageWrapper}>
        <div className={styles.loginContainer}>
          <div className={styles.brandSection}>
            <img src="/turfmapp-logo.png" alt="TURFMAPP" className={styles.logo} />
            <p className={styles.tagline}>PROJECT MANAGEMENT TOOL</p>
          </div>
          <div className={styles.loginWrapper}>
            {message && (
              <Message
                // eslint-disable-next-line react/jsx-props-no-spreading
                {...{
                  [message.type]: true,
                }}
                visible
                content={t(message.content)}
                onDismiss={onMessageDismiss}
              />
            )}
            {!isOidcEnforced && (
              <Form size="large" onSubmit={handleSubmit}>
                <div className={styles.inputWrapper}>
                  <div className={styles.inputLabel}>{t('common.emailOrUsername')}</div>
                  <Input
                    fluid
                    ref={emailOrUsernameField}
                    name="emailOrUsername"
                    value={data.emailOrUsername}
                    readOnly={isSubmitting}
                    className={styles.input}
                    onChange={handleFieldChange}
                  />
                </div>
                <div className={styles.inputWrapper}>
                  <div className={styles.inputLabel}>{t('common.password')}</div>
                  <Input.Password
                    fluid
                    ref={passwordField}
                    name="password"
                    value={data.password}
                    readOnly={isSubmitting}
                    className={styles.input}
                    onChange={handleFieldChange}
                  />
                </div>
                <div className={styles.buttonWrapper}>
                  <Form.Button
                    primary
                    size="large"
                    icon="right arrow"
                    labelPosition="right"
                    content={t('action.logIn')}
                    loading={isSubmitting}
                    disabled={isSubmitting || isSubmittingUsingOidc}
                  />
                </div>
              </Form>
            )}
            {withOidc && (
              <Button
                type="button"
                fluid={isOidcEnforced}
                primary={isOidcEnforced}
                size={isOidcEnforced ? 'large' : undefined}
                icon={isOidcEnforced ? 'right arrow' : undefined}
                labelPosition={isOidcEnforced ? 'right' : undefined}
                content={t('action.logInWithSSO')}
                loading={isSubmittingUsingOidc}
                disabled={isSubmitting || isSubmittingUsingOidc}
                onClick={onAuthenticateUsingOidc}
              />
            )}
          </div>
        </div>
      </div>
    );
  },
);

Login.propTypes = {
  /* eslint-disable react/forbid-prop-types */
  defaultData: PropTypes.object.isRequired,
  /* eslint-enable react/forbid-prop-types */
  isSubmitting: PropTypes.bool.isRequired,
  isSubmittingUsingOidc: PropTypes.bool.isRequired,
  error: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  withOidc: PropTypes.bool.isRequired,
  isOidcEnforced: PropTypes.bool.isRequired,
  onAuthenticate: PropTypes.func.isRequired,
  onAuthenticateUsingOidc: PropTypes.func.isRequired,
  onMessageDismiss: PropTypes.func.isRequired,
};

Login.defaultProps = {
  error: undefined,
};

export default Login;
