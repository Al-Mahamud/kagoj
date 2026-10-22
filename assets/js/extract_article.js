// Runs inside the ePaper WebView. Returns a JSON string with the article that is
// currently visible in "text view", or null when the page is not an article.
// Per-paper selectors are injected beforehand as window.__kagojSelectors;
// when they are missing or don't match, a generic "biggest visible block of <p>" heuristic is used.
// TODO: if a paper renders its text view inside an iframe, run this script inside that frame.
(function () {
  var cfg = window.__kagojSelectors || {};

  function visible(el) {
    return !!el && el.offsetParent !== null && el.getClientRects().length > 0;
  }

  function text(el) {
    return el ? (el.innerText || '').replace(/\s+/g, ' ').trim() : '';
  }

  if (cfg.articleUrlPattern && !new RegExp(cfg.articleUrlPattern).test(location.href)) {
    return null;
  }

  var root = cfg.container ? document.querySelector(cfg.container) : null;
  if (!visible(root)) {
    root = null;
    var best = 0;
    document.querySelectorAll('article, main, section, div').forEach(function (el) {
      if (!visible(el)) return;
      var len = 0;
      el.querySelectorAll(':scope > p').forEach(function (p) {
        len += text(p).length;
      });
      if (len > best) {
        best = len;
        root = el;
      }
    });
    if (best < 300) return null;
  }

  var paragraphs = Array.prototype.map
    .call(root.querySelectorAll('p'), text)
    .filter(function (t) { return t.length > 0; });
  if (paragraphs.length === 0) return null;

  var titleEl =
    (cfg.title && document.querySelector(cfg.title)) ||
    root.querySelector('h1, h2, h3') ||
    document.querySelector('h1');
  var bylineEl = cfg.byline ? document.querySelector(cfg.byline) : null;

  return JSON.stringify({
    title: text(titleEl) || document.title,
    byline: text(bylineEl) || null,
    paragraphs: paragraphs,
  });
})();
