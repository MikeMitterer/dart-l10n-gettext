define(['dart_sdk', 'packages/intl/intl_browser', 'packages/intl/intl', 'packages/intl/date_symbol_data_local', 'packages/web/_l10n/messages_all', 'packages/l10n/l10n'], function(dart_sdk, intl_browser, intl, date_symbol_data_local, messages_all, l10n) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const intl_browser$ = intl_browser.intl_browser;
  const intl$ = intl.intl;
  const date_symbol_data_local$ = date_symbol_data_local.date_symbol_data_local;
  const _l10n__messages_all = messages_all._l10n__messages_all;
  const l10n$ = l10n.l10n;
  const _root = Object.create(null);
  const main = Object.create(_root);
  const $_get = dartx._get;
  const $text = dartx.text;
  const $replaceAllMapped = dartx.replaceAllMapped;
  const $forEach = dartx.forEach;
  const $classes = dartx.classes;
  let MatchToString = () => (MatchToString = dart.constFn(dart.fnType(core.String, [core.Match])))();
  let HtmlElementToNull = () => (HtmlElementToNull = dart.constFn(dart.fnType(core.Null, [html.HtmlElement])))();
  let ElementToHtmlElement = () => (ElementToHtmlElement = dart.constFn(dart.fnType(html.HtmlElement, [html.Element])))();
  main.main = function() {
    return async.async(dart.dynamic, function* main() {
      let locale = (yield intl_browser$.findSystemLocale());
      let shortLocale = intl$.Intl.shortLocale((() => {
        let l = core.Uri.base.queryParameters[$_get]("lang");
        return l != null ? l : locale;
      })());
      yield date_symbol_data_local$.initializeDateFormatting(locale);
      yield _l10n__messages_all.initializeMessages(shortLocale);
      html.querySelectorAll(html.Element, ".translate").map(html.HtmlElement, dart.fn(element => html.HtmlElement.as(element), ElementToHtmlElement()))[$forEach](dart.fn(element => {
        element[$text] = element[$text][$replaceAllMapped](core.RegExp.new("_\\(\"(.*)\"\\)", {multiLine: true}), dart.fn(match => l10n$.l10n(match.group(1)), MatchToString()));
      }, HtmlElementToNull()));
      html.querySelector("body")[$classes].remove("loading");
    });
  };
  dart.trackLibraries("web/main.ddc", {
    "main.dart": main
  }, '{"version":3,"sourceRoot":"","sources":["main.dart"],"names":[],"mappings":";;;;;;;;;;;;;;;;;;;;;;;AAUc;AAEV,UAAa,UAAS,MAAM,8BAAgB;AAC5C,UAAa,cAAc,UAAI,YAAY;gBAAC,QAAG,KAAK,gBAAgB,QAAC;+BAAW,MAAM;;AAKtF,YAAM,gDAAwB,CAAC,MAAM;AAGrC,YAAM,sCAAkB,CAAC,WAAW;AAEpC,MAAI,qBAAgB,eAAC,iBACb,mBAAC,QAAC,OAAyB,wBAAK,OAAO,qCACnC,CAAC,QAAC,OAA6B;AACnC,eAAO,OAAK,GAAG,OAAO,OAAK,mBAAiB,CAAC,eAAM,CAAC,+BAA2B,QACvE,QAAC,KAAiB,IACX,UAAI,CAAC,KAAK,MAAM,CAAC;;AAIxC,MAAI,kBAAa,CAAC,iBAAe,OAAO,CAAC;IAC7C","file":"main.ddc.js"}');
  // Exports:
  return {
    main: main
  };
});

//# sourceMappingURL=main.ddc.js.map
