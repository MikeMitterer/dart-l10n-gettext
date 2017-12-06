import 'package:test/test.dart';

import 'package:logging/logging.dart';
import 'package:logging_handlers/logging_handlers_shared.dart';

import 'package:l10n/l10n.dart';
import 'package:l10n/locale/messages.dart';

main() {
    // final Logger _logger = new Logger("unit.test.L10NTranslation");
    configLogging();

    final Map<String,Map<String,String>> translationTable = {
        "en" : {
            "Hallo, dies ist ein {{what}}" :
                "Hello, this is a {{what}}",
        },

        "de" : {
            "Hallo, dies ist ein {{what}}" :
                "Hallo,\n dies ist ein {{what}}",
        }
    };

    String backupLocale = "";

    group('L10NTranslation', () {
        setUp(() {
            backupLocale = translate.locale;
        });

        tearDown(() {
            translate.locale = backupLocale;
        });

        test('> Translation', () {
            final L10NTranslate translator = new L10NTranslate.withTranslation(
                {
                    "Hallo {{name}}" : "{{name}}, Welcome in ..."
                });

            expect(translator.translate(l10n("Hallo {{name}}",{ "name" : "Mike"})), "Mike, Welcome in ...");
        }); // end of 'Translation' test

        test('> Translation mit Translator', () {
            final Translator translator = new L10NTranslate.withTranslation(
                {
                    "Hallo {{name}}" : "{{name}}, Welcome in ..."
                });

            expect(translator.translate(l10n("Hallo {{name}}",{ "name" : "Mike"})), "Mike, Welcome in ...");
        }); // end of 'Translation mit Translator' test

        test('> Translate with call-function', () {
            final L10NTranslate translate = new L10NTranslate.withTranslation(
                {
                    "Hallo {{name}}" : "{{name}}, Welcome in ..."
                });

            expect(translate(l10n("Hallo {{name}}",{ "name" : "Mike"})), "Mike, Welcome in ...");

        }); // end of 'Translate with call-function' test

        test('> Translate (partial)', () {
            final L10N l10n = new L10N("Hallo {{l10n}}" , {
                "l10n" : TRANSLATOR(const L10N("Mike + {{name}}",const { "name" : "Sarah" })
                )
            });

            expect(l10n.message,"Hallo Mike + Sarah");
        }); // end of 'Translate' test

        test('> Translate with Table', () {
            final L10NTranslate translator = new L10NTranslate.withTranslation(
                {
                    "Hallo {{l10n}}" : "Willkommen {{l10n}}",
                    "Mike + {{name}}" : "in Australien {{name}}"
                });

            final L10N l10n = new L10N("Hallo {{l10n}}",{
                "l10n" : translator( const L10N("Mike + {{name}}",const { "name" : "Sarah" })
                )}
            );

            expect(translator( const L10N("Mike + {{name}}",const { "name" : "Sarah" })),"in Australien Sarah");
            expect(translator(l10n),"Willkommen in Australien Sarah");
        }); // end of 'Translate with Table' test

//        test('> Locale', () {
//            final Intl intl = new Intl();
//            _logger.info(intl.locale);
//            _logger.info(Intl.shortLocale(intl.locale));
//
//            String result;
//
//            try {
//                result = Intl.verifiedLocale('ysdex',(final String testLocale) {
//                    _logger.info("VL: $testLocale");
//                    return false;
//                });
//            } on ArgumentError {
//                result = "en";
//            }
//
//
//        }, skip: "Nur für Output interessant"); // end of 'Locale' test

        test('> With external table', () {
            final L10NTranslate translate = new L10NTranslate.withTranslation(translationTable["en"]);

            expect(translate(l10n("Hallo, dies ist ein {{what}}",{ "what" : "Test"})),"Hello, this is a Test");
        }); // end of 'With external table' test

        test('> Switch locale', () {
            final L10NTranslate translate = new L10NTranslate.withTranslations(translationTable);

            // default locale is en
            expect(translate(l10n("Hallo, dies ist ein {{what}}",{ "what" : "Test"})),"Hello, this is a Test");

            translate.locale = "de";
            // Im deutschen wird bei der Übersetzung ein \n eingefügt.
            // Ob der Key (msgid) ein \n enthält oder nicht ist egal
            expect(translate(l10n("Hallo,\n dies ist ein {{what}}",{ "what" : "Test"})),"Hallo,\n dies ist ein Test");

            // does not exist
            translate.locale = "ru";

            // - Fallback to EN
            expect(translate(l10n("Hallo, dies ist ein {{what}}",{ "what" : "Test"})),"Hello, this is a Test");

            // Does not exist at all - brings back default message
            expect(translate(l10n("Hallo, {{name}}",{ "name" : "Mike"})),"Hallo, Mike");
        }); // end of 'Switch locale' test

        test('> for mkl10nlocale', () {
            expect((l10n("Test1").message),"Test1");
        }); // end of 'for mkl10nlocale' test

        test('> Translate with locale/messages.dart', () {
            translate.locale = "de";
            expect(translate(l10n("Prints settings")),"Zeigt die Settings an");
        }); // end of 'Translate with locale/messages.dart' test

        test('> SubTranslation', () {
            final int major = 400;
            final L10N l = new L10N(
                """
                    Der Server meldet {{status}} bei der API-Key Anforderung.
                    """, {
                    "status"     : "{{statuscode-${major}}}"
                });

            expect(l.message, "Der Server meldet {{statuscode-400}} bei der API-Key Anforderung.");
            expect(translate(l),"Der Server meldet {{statuscode-400}} bei der API-Key Anforderung.");

            translate.locale = "de";
            expect(translate(l),"Fehlerhafte Anfrage (400) bei der API-Key Anforderung!");

        }, skip: "Sub-Translation is not supported since lexer/parser upgrade "); // end of 'SubTranslation' test

        test('> MessageID with newline', () {
            expect(l10n("Hallo\nTest").msgid, "HalloTest");
        }); // end of 'MessageID with newline' test

    });
    // end 'L10NTranslation' group
}

void configLogging() {
    hierarchicalLoggingEnabled = false;
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen(new LogPrintHandler());
}
