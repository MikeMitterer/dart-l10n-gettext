import 'dart:async';
import 'dart:html' as dom;
import 'package:intl/date_symbol_data_local.dart';

// Include this if you run your app in the browser
import 'package:intl/intl_browser.dart';

import 'package:l10n/l10n.dart';
import 'package:browser_example/_l10n/messages_all.dart';

Future main() async {
    // Determine your locale
    final String locale = await findSystemLocale();
    final String shortLocale = Intl.shortLocale(Uri.base.queryParameters['lang'] ?? locale);

    // Avoids error message:
    //      LocaleDataException: Locale data has not been initialized,
    //      call initializeDateFormatting(<locale>).
    await initializeDateFormatting(locale);

    // Initialize translation-table
    await initializeMessages(shortLocale);

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
