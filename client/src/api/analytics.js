import { fetch } from 'whatwg-fetch';
import Config from '../constants/Config';

// eslint-disable-next-line import/prefer-default-export
export function getAnalytics() {
  const accessToken = document.cookie
    .split('; ')
    .find((row) => row.startsWith(`${Config.ACCESS_TOKEN_KEY}=`))
    ?.split('=')[1];

  if (!accessToken) {
    return Promise.reject(new Error('Access token not found'));
  }

  return fetch(`${Config.SERVER_BASE_URL}/api/analytics`, {
    method: 'GET',
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
    credentials: 'include',
  })
    .then((response) =>
      response.json().then((body) => ({
        body,
        isError: response.status !== 200,
      })),
    )
    .then(({ body, isError }) => {
      if (isError) {
        throw body;
      }

      return body;
    });
}
