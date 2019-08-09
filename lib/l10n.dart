library l10n;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import "package:validate/validate.dart";

export 'package:intl/intl.dart';

part "interfaces.dart";

part 'l10n/L10NImpl.dart';

/// Shortcut to get a L10N object
///
/// All \n, \r and more than one spaces will be stripped.
String l10n(final String msgid, [final Map<String, dynamic> vars = const {} ]) {
    return L10N(msgid,vars).message;
}

/// Shortcut to get a L10N object
String gettext(final String msgid, [final Map<String, dynamic> vars = const {} ]) {
    return l10n(msgid,vars);
}

/// Shortcut to get a L10N object
String tr(final String msgid, [final Map<String, dynamic> vars = const {} ]) {
    return l10n(msgid,vars);
}

/// Initialize the Intl-Framework
///
///     // Include this if you run your app in the browser
///     import 'package:intl/intl_browser.dart';
///
///     import 'package:l10n/l10n.dart';
///     import 'package:browser_example/_l10n/messages_all.dart';
///
///     Future main() async {
///         final String locale = await initLanguageSettings(
///                 () => findSystemLocale(),
///                 (final String locale) => initializeMessages(locale)
///         );
///         ...
///     }
///
Future<String> initLanguageSettings(
    Future<String> findLocale(),
    Future<bool> initMessages(final String locale)) async {

    // Determine your locale
    final String locale = await findLocale(); // Calls platform specific "findSystemLocale"
    final String shortLocale = Intl.shortLocale(Uri.base.queryParameters['lang'] ?? locale);

    // Important - otherwise the Browser doesn't show the right language!
    Intl.systemLocale = shortLocale;

    // Avoids error message:
    //      LocaleDataException: Locale data has not been initialized,
    //      call initializeDateFormatting(<locale>).
    await initializeDateFormatting(shortLocale);

    // Initialize translation-table
    // calls back into application specific part
    await initMessages(shortLocale);

    return shortLocale;
}
