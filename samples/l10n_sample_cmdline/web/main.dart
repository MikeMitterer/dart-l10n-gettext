import 'dart:async';

import 'package:intl/intl.dart';

// This file was generated in two steps, using the Dart intl tools. With the
// app's root directory (the one that contains pubspec.yaml) as the current
// directory:
//
// flutter pub get
// flutter pub pub run intl_translation:extract_to_arb --output-dir=lib/l10n lib/main.dart
// flutter pub pub run intl_translation:generate_from_arb --output-dir=lib/l10n --no-use-deferred-loading lib/main.dart lib/l10n/intl_*.arb
//
// The second command generates intl_messages.arb and the third generates
// messages_all.dart. There's more about this process in
// https://pub.dartlang.org/packages/intl.
import 'package:l10n_sample_cmdline/_l10n/messages_all.dart';

Future main() async {
    Intl.defaultLocale = "en";
    await initializeMessages(Intl.defaultLocale);

    String message() => Intl.message("abc");
    print(message());

    String message2(final String name) => Intl.message("Hallo ${name}",name: "message0", args: [name]);
    String sayHello() => message2("Mike1");
    print(sayHello());

    
}