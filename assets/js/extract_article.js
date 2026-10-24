// Runs inside the ePaper WebView. Returns a JSON string with the article that is
// currently visible in "text view", or null when the page is not an article.
// Per-paper selectors are injected beforehand as window.__kagojSelectors;
// when they are missing or don't match, a generic "biggest visible block of <p>" heuristic is used.
// TODO: if a paper renders its text view inside an iframe, run this script inside that frame.
(function () {
  var cfg = window.__kagojSelectors || {};

  // First line of a part that continues an article from an earlier page,
  // e.g. "প্রথম পৃষ্ঠার পর" or "(Continued from page 1)".
  var CONTINUED_FROM =
    /^\s*\(?\s*(?:(?:\S+\s+){0,2}পৃষ্ঠার\s+পর|(?:continued|cont'?d\.?)\s+from\s+(?:page|p\.?)\s*[^\s)]+)\s*\)?[\s:.-]*/i;

  // A short paragraph that only points to where the article goes on,
  // e.g. "বাকি অংশ ৪ পৃষ্ঠায়", "পৃষ্ঠা ২ কলাম ৫" or "Continued on page 4".
  var JUMP_LINE =
    /^\s*\(?\s*(?:(?:বাকি|শেষাংশ|এরপর)\s.{0,30}পৃষ্ঠা\S*(?:\s*কলাম\s*\S+)?|পৃষ্ঠা\s*[০-৯\d]+(?:\s*কলাম\s*[০-৯\d]+)?|(?:continued|cont'?d\.?)\s+on\s+(?:page|p\.?)\s*\S+|see\s+page\s*\S+)\s*\)?[\s.]*$/i;

  function visible(el) {
    return !!el && el.offsetParent !== null && el.getClientRects().length > 0;
  }

  function text(el) {
    return el ? (el.innerText || '').replace(/\s+/g, ' ').trim() : '';
  }

  function paragraphsOf(el) {
    return Array.prototype.map
      .call(el.querySelectorAll('p'), text)
      .filter(function (t) { return t.length > 0; });
  }

  if (cfg.articleUrlPattern && !new RegExp(cfg.articleUrlPattern).test(location.href)) {
    return null;
  }

  // An article can be split over several blocks, such as the front-page part
  // and its continuation from an inside page, so the container selector may
  // match more than one element.
  var roots = [];
  if (cfg.container) {
    document.querySelectorAll(cfg.container).forEach(function (el) {
      if (visible(el) && paragraphsOf(el).length > 0) roots.push(el);
    });
  }
  if (roots.length === 0) {
    var root = null;
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
    roots.push(root);
  }

  // A continuation goes after the part it continues, whatever the page order.
  var parts = roots.map(function (el) {
    var paragraphs = paragraphsOf(el);
    var continued = CONTINUED_FROM.test(paragraphs[0]);
    if (continued) {
      paragraphs[0] = paragraphs[0].replace(CONTINUED_FROM, '');
      if (paragraphs[0].length === 0) paragraphs.shift();
    }
    return { paragraphs: paragraphs, continued: continued };
  });
  parts = parts
    .filter(function (part) { return !part.continued; })
    .concat(parts.filter(function (part) { return part.continued; }));

  var paragraphs = [];
  parts.forEach(function (part) {
    part.paragraphs.forEach(function (p) {
      if (p.length > 60 || !JUMP_LINE.test(p)) paragraphs.push(p);
    });
  });
  if (paragraphs.length === 0) return null;

  var titleEl =
    (cfg.title && document.querySelector(cfg.title)) ||
    roots[0].querySelector('h1, h2, h3') ||
    document.querySelector('h1');
  var bylineEl = cfg.byline ? document.querySelector(cfg.byline) : null;

  return JSON.stringify({
    title: text(titleEl) || document.title,
    byline: text(bylineEl) || null,
    paragraphs: paragraphs,
  });
})();
