/// Builds a one-shot script that paints a legal page in a readable ink-on-paper
/// palette after the WebView finishes loading.
///
/// The script is assembled from Dart tokens so the payload is not a single
/// copy-pasted CSS blob. Injection uses `textContent` and a named node rather
/// than `innerHTML` + an anonymous `<style>` tag.
library;

/// CSS custom-property sheet applied to privacy / support documents.
const Map<String, String> _inkTokens = <String, String>{
  '--hy-paper': '#fbfaf4',
  '--hy-ink': '#141814',
  '--hy-link': '#1b5c38',
  '--hy-field': '#ffffff',
  '--hy-line': '#d2d6c8',
  '--hy-accent': '#1b5c38',
  '--hy-on-accent': '#f7fff8',
};

String _tokenBlock() {
  final buf = StringBuffer(':root{');
  _inkTokens.forEach((key, value) {
    buf.write('$key:$value;');
  });
  buf.write('}');
  return buf.toString();
}

String _sheetRules() {
  return [
    _tokenBlock(),
    'html,body{background:var(--hy-paper);color:var(--hy-ink);}',
    'body{margin:0;padding:18px 20px 52px;line-height:1.65;font-size:16px;',
    '-webkit-text-size-adjust:100%;font-family:ui-sans-serif,system-ui,sans-serif;}',
    'h1,h2,h3,h4,p,li,td,th,label{color:var(--hy-ink);}',
    'a{color:var(--hy-link);}',
    'input,textarea,select{background:var(--hy-field);color:var(--hy-ink);',
    'border:1px solid var(--hy-line);border-radius:12px;padding:11px 13px;',
    'font-size:16px;width:100%;box-sizing:border-box;margin:8px 0 14px;}',
    'button,input[type=submit]{background:var(--hy-accent);color:var(--hy-on-accent);',
    'border:0;border-radius:12px;padding:13px 18px;font-size:16px;font-weight:600;width:100%;}',
    'img{max-width:100%;height:auto;}',
  ].join();
}

/// JavaScript that upserts the reader stylesheet under a stable node id.
String buildReaderInkScript() {
  final rules = _sheetRules().replaceAll("'", r"\'");
  return """
(function (nodeId, cssText) {
  var node = document.getElementById(nodeId);
  if (!node) {
    node = document.createElement('style');
    node.id = nodeId;
    (document.head || document.documentElement).appendChild(node);
  }
  node.textContent = cssText;
})('hy-reader-ink', '$rules');
""";
}
