import 'package:intl/intl.dart';

// Include this if you run your app on the cmdline
import 'package:intl/intl_standalone.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:l10n/l10n.dart';

import 'package:l10n_exsample_cmdline/_l10n/messages_all.dart';

void main(List<String> arguments) {

    // Determine your locale
    findSystemLocale().then((final String locale) async {
        String shortLocale = Intl.shortLocale(locale);

        // Avoids error message:
        //      LocaleDataException: Locale data has not been initialized,
        //      call initializeDateFormatting(<locale>).
        await initializeDateFormatting(locale);

        // Initialize translation-table
        await initializeMessages(shortLocale);

        String message() => Intl.message("First test");
        print(message());
        print(l10n("Second test"));

        [ "Mike", "Gerda", "Sarh"].forEach((name) {
            print(l10n("Good morning [name]",{ "name" : name }));
        });

    });
}