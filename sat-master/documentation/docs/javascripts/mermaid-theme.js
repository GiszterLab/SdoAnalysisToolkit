document.addEventListener("DOMContentLoaded", function () {
  const updateMermaidTheme = (isDark) => {
    mermaid.initialize({
      startOnLoad: true,
      theme: isDark ? 'dark' : 'default'
    });
    mermaid.init();
  };

  // Initial theme detection on page load
  const isDark = document.documentElement.getAttribute('data-md-color-scheme') === 'slate';
  updateMermaidTheme(isDark);

  // Detect and respond to theme toggle
  const observer = new MutationObserver((mutations) => {
    mutations.forEach((mutation) => {
      if (mutation.attributeName === 'data-md-color-scheme') {
        const newIsDark = document.documentElement.getAttribute('data-md-color-scheme') === 'slate';
        updateMermaidTheme(newIsDark);
      }
    });
  });

  observer.observe(document.documentElement, { attributes: true });
});
