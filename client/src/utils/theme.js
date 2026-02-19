const THEME_DARK = 'dark';
const THEME_LIGHT = 'light';
const THEME_STORAGE_KEY = 'turfmapp-theme';

const getStoredTheme = () => {
  if (typeof window === 'undefined') {
    return null;
  }

  try {
    const value = window.localStorage.getItem(THEME_STORAGE_KEY);

    if (value === THEME_DARK || value === THEME_LIGHT) {
      return value;
    }
  } catch (error) {
    return null;
  }

  return null;
};

const getPreferredTheme = () => getStoredTheme() || THEME_LIGHT;

const applyTheme = (theme) => {
  const normalizedTheme = theme === THEME_DARK ? THEME_DARK : THEME_LIGHT;

  document.documentElement.dataset.theme = normalizedTheme;
  document.documentElement.style.colorScheme = normalizedTheme;
};

const initializeAutoTheme = () => {
  if (typeof document === 'undefined') {
    return () => {};
  }

  if (typeof window === 'undefined') {
    applyTheme(THEME_LIGHT);
    return () => {};
  }

  const syncTheme = () => applyTheme(getPreferredTheme());
  const handleStorageChange = (event) => {
    if (!event || event.key === THEME_STORAGE_KEY) {
      syncTheme();
    }
  };

  syncTheme();
  window.addEventListener('storage', handleStorageChange);

  return () => {
    window.removeEventListener('storage', handleStorageChange);
  };
};

export default initializeAutoTheme;
