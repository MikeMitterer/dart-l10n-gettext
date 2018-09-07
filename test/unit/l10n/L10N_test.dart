import 'package:test/test.dart';

import 'package:intl/intl_standalone.dart';
import 'package:l10n/l10n.dart';

import '../_resources/messages_all.dart';

main() async {
    await findSystemLocale();
    await initializeMessages('de');

    group('L10NMessage', () {
        setUp(() {

        });

//        test('> Creation', () {
//            final L10N l10n = new L10N("Hallo Mike");
//            expect(l10n,isNotNull);
//
//            expect(l10n.msgid,"Hallo Mike");
//            expect(l10n.message,"Hallo Mike");
//        }); // end of 'Creation' test
//

        test('> Use Intl.message', () {
            message1() => Intl.message("Hi Kotlin!");
//
            expect(message1(),"Servus Kotlin!");
        }); // end of 'Creation' test


        test('> const Creation', () {
            const L10N l10n = const L10N("Hallo Mike II");
            expect(l10n,isNotNull);

            expect(l10n.msgid,"Hallo Mike II");
            expect(l10n.message,"Hallo Mike II");
        }); // end of 'const Creation' test

        test('> Create with l10n-function', () {

            final message = l10n("Hallo {?}-",{ "?" : "Welt" });
            expect(message,"Guten Morgen Welt-");

        }); // end of 'Create with l10n-function' test

        test('> l10n function', () {
            expect(l10n("Hello \{\\name}-",{ "\\name" : "Mike" }), "Servus Mike");
            expect(l10n("Your are [age] years old",{ "age" : 99 }), "Du bist 99 Jahre alt!");
        }); // end of 'l10n function' test

//        test('> Creation with vars', () {
//            final L10N l10n = const L10N("Hallo {name}, du bist jetzt {age} Jahre alt",const { "name" : "Mike", "age" : 47} );
//            expect(l10n,isNotNull);
//
//            //logger.info(l10n.toString());
//
//            expect(l10n.message,"Hallo Mike, du bist jetzt 47 Jahre alt");
//
//        }); // end of 'Creation with vars' test
//
//        test('> from Json', () {
//            final L10N l10n = new L10NImpl.fromJson(jsonToTest);
//
//            expect(l10n,isNotNull);
//
//            expect(l10n.msgid,"Hallo {name}, du bist jetzt {age} Jahre alt");
//            expect(l10n.message,"Hallo Mike, du bist jetzt 47 Jahre alt");
//
//            expect(l10n.vars.length,2);
//            expect(l10n.vars["name"],"Mike");
//            expect(l10n.vars["age"],47);
//        }); // end of 'from Json' test
//
//        test('> from Json ohne Vars', () {
//            final L10N l10n = new L10NImpl.fromJson(jsonToTestOhneVars);
//
//            expect(l10n,isNotNull);
//
//            expect(l10n.msgid,"Hallo {name}, du bist jetzt {age} Jahre alt");
//
//            expect(l10n.vars.length,0);
//        }); // end of 'from Json ohne Vars' test
//
//        test('> toJson (L10N)', () {
//            final L10N l10n = new L10N.fromJson(jsonToTestOhneVars);
//
//            expect(l10n,isNotNull);
//
//            expect(l10n.msgid,"Hallo {name}, du bist jetzt {age} Jahre alt");
//
//            expect(l10n.vars.length,0);
//        }); // end of 'toJson (L10N)' test


    });
    // end 'L10NMessage' group
}
