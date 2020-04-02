import 'dart:async';
import 'dart:html' as dom;

// Include this if you run your app in the browser
import 'package:intl/intl_browser.dart';

import 'package:l10n/l10n.dart';
import 'package:browser_example/_l10n/messages_all.dart';

Future main() async {
    // initLanguageSettings checks the browser url if it finds
    // a "lang" query param and sets the locale accordingly
    final String locale = await initLanguageSettings(
            () => findSystemLocale(),
            (final String locale) => initializeMessages(locale)
    );

    // Set "lang" in the DOM
    (dom.querySelector("head") as dom.HeadElement).lang = locale;

    dom.querySelectorAll('.translate')
        .map((final dom.Element element) => element as dom.HtmlElement)
        .forEach((final dom.HtmlElement element) {
            element.text = element.text.replaceAllMapped(RegExp(r'_\("(.*)"\)', multiLine: true),
                    (final Match match) {
                    return l10n(match.group(1));
                });
    });

    dom.querySelector("body").classes.remove("loading");
}

