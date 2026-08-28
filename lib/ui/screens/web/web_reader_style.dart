/// Injects a compact "reader" stylesheet into whatever HTML the WebView loaded.
///
/// The idea is very simple: our support and privacy pages are hosted on a
/// site that we don't fully control, so we can't guarantee the theme (some
/// themes ship dark backgrounds or fancy hero images that clash with the
/// rest of the app). By forcing a plain black-on-white reader look, the
/// content is legible on every OS-level appearance setting.
library;

/// A single-line JavaScript snippet that appends a `<style>` element to the
/// document. Kept as an ES5-friendly IIFE so it works on the older WebViews
/// still shipped on some Android devices.
///
/// The stylesheet:
///   * paints backgrounds white and text black on every element,
///   * uses the platform system font at a readable size,
///   * gives inputs and buttons a consistent rounded look,
///   * ensures images and containers stay within the viewport.
const String readerStyleScript = '''
(function () {
  var style = document.createElement('style');
  style.innerHTML = [
    'html,body{background:#ffffff !important;color:#000000 !important;}',
    'body{-webkit-text-size-adjust:100%;padding:14px 16px 40px !important;',
    'font-family:-apple-system,Segoe UI,Roboto,Arial,sans-serif;line-height:1.6;}',
    'h1,h2,h3,h4,h5,h6,p,li,span,div,td,th,label,strong,em,b{color:#000000 !important;}',
    'a{color:#0e4429 !important;}',
    'input,textarea,select{background:#ffffff !important;color:#000000 !important;',
    'border:1px solid #cccccc !important;border-radius:10px !important;',
    'padding:10px 12px !important;font-size:16px !important;width:100% !important;',
    'box-sizing:border-box !important;margin:6px 0 12px !important;}',
    'button,input[type=submit]{background:#0e4429 !important;color:#ffffff !important;',
    'border:none !important;border-radius:10px !important;padding:12px 18px !important;',
    'font-size:16px !important;font-weight:600 !important;width:100% !important;}',
    'img{max-width:100% !important;height:auto !important;}',
    '*{max-width:100% !important;box-sizing:border-box;}'
  ].join('');
  document.head.appendChild(style);
})();
''';
