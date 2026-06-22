/* ============================================================
   KakoBuy Spreadsheet — Theme Toggle (Dark Mode)
   ============================================================ */
(function () {
  'use strict';

  const STORAGE_KEY = 'kakobuy-theme';
  const DARK_CLASS = 'dark-theme';

  function applyTheme(theme) {
    if (theme === 'dark') {
      document.documentElement.classList.add(DARK_CLASS);
    } else {
      document.documentElement.classList.remove(DARK_CLASS);
    }
  }

  function getStoredTheme() {
    try {
      return localStorage.getItem(STORAGE_KEY);
    } catch (e) {
      return null;
    }
  }

  function storeTheme(theme) {
    try {
      localStorage.setItem(STORAGE_KEY, theme);
    } catch (e) {
      // storage unavailable
    }
  }

  // Detect system preference
  function getSystemTheme() {
    if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
      return 'dark';
    }
    return 'light';
  }

  // Initialize
  var stored = getStoredTheme();
  var theme = stored || getSystemTheme();
  applyTheme(theme);

  // Toggle button
  var toggleBtn = document.getElementById('themeToggle');
  if (toggleBtn) {
    toggleBtn.addEventListener('click', function () {
      var current = document.documentElement.classList.contains(DARK_CLASS) ? 'dark' : 'light';
      var next = current === 'dark' ? 'light' : 'dark';
      applyTheme(next);
      storeTheme(next);
      updateToggleLabel(next);
    });

    // Listen for system changes (only when no user override)
    if (window.matchMedia) {
      window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function (e) {
        if (getStoredTheme() === null) {
          applyTheme(e.matches ? 'dark' : 'light');
        }
      });
    }
  }

  function updateToggleLabel(theme) {
    if (!toggleBtn) return;
    toggleBtn.setAttribute('aria-label', theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode');
    toggleBtn.textContent = theme === 'dark' ? '\u2600\uFE0F' : '\uD83C\uDF19';
  }

  // Set initial label
  updateToggleLabel(theme);
})();
