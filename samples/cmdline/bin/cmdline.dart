import 'package:intl/intl.dart';

// Include this if you run your app on the cmdline
import 'package:intl/intl_standalone.dart';
import 'package:l10n/l10n.dart';

import '../lib/_l10n/messages_all.dart';

/// You can change the language on the cmdline like this:
///
///     dart bin/cmdline.dart en
///     dart bin/cmdline.dart de
///
void main(List<String> arguments) async {
    await initLanguageSettings(
        () => findSystemLocale(),
        (final String locale) => initializeMessages(
            arguments.isNotEmpty ? arguments.first : locale)
    );

    String message() => Intl.message("First test");
    print(message());
    print(l10n("Second test"));

    [ "Mike", "Gerda", "Sarh"].forEach((name) {
        print(l10n("Good morning [name]",{ "name" : name }));
    });

}