const THEME_DARK = 'dark';
const THEME_LIGHT = 'light';

const getTimeBasedTheme = (date = new Date()) => {
  const hour = date.getHours();

  return hour >= 19 || hour < 6 ? THEME_DARK : THEME_LIGHT;
};

const getPreferredTheme = () => {
  if (typeof window === 'undefined' || typeof window.matchMedia !== 'function') {
    return getTimeBasedTheme();
  }

  const darkQuery = window.matchMedia('(prefers-color-scheme: dark)');
  const lightQuery = window.matchMedia('(prefers-color-scheme: light)');
  const supportsColorScheme = darkQuery.media !== 'not all' || lightQuery.media !== 'not all';

  if (supportsColorScheme) {
    return darkQuery.matches ? THEME_DARK : THEME_LIGHT;
  }

  return getTimeBasedTheme();
};

const applyTheme = (theme) => {
  document.documentElement.dataset.theme = theme;
  document.documentElement.style.colorScheme = theme;
};

const initializeAutoTheme = () => {
  if (typeof document === 'undefined') {
    return () => {};
  }

  const setAutoTheme = () => applyTheme(getPreferredTheme());

  setAutoTheme();

  if (typeof window === 'undefined') {
    return () => {};
  }

  if (typeof window.matchMedia !== 'function') {
    const intervalId = window.setInterval(setAutoTheme, 60 * 1000);

    return () => window.clearInterval(intervalId);
  }

  const darkQuery = window.matchMedia('(prefers-color-scheme: dark)');
  const lightQuery = window.matchMedia('(prefers-color-scheme: light)');
  const supportsColorScheme = darkQuery.media !== 'not all' || lightQuery.media !== 'not all';

  if (supportsColorScheme) {
    const handleChange = () => setAutoTheme();

    if (typeof darkQuery.addEventListener === 'function') {
      darkQuery.addEventListener('change', handleChange);
      return () => darkQuery.removeEventListener('change', handleChange);
    }

    darkQuery.addListener(handleChange);
    return () => darkQuery.removeListener(handleChange);
  }

  const intervalId = window.setInterval(setAutoTheme, 60 * 1000);

  return () => window.clearInterval(intervalId);
};

export default initializeAutoTheme;
