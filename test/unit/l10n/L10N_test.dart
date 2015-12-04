@TestOn("content-shell")
import 'package:test/test.dart';

import 'package:l10n/l10n.dart';

class Name implements Translatable {
    final String firstname;

    Name(this.firstname);

    L10N get l10n {
        return new L10NImpl("My name is {{firstname}}",{ "firstname" : firstname} );
    }
}

main() {
    final String jsonToTest = "{\n" +
        "   \"msgid\" : \"Hallo {{name}}, du bist jetzt {{age}} Jahre alt\",\n" +
        "   \"vars\" :\n" +
        "      {\n" +
        "         \"name\" : \"Mike\",\n" +
        "         \"age\" : 47\n" +
        "      }\n" +
        "}";

    final String jsonToTestOhneVars = "{\n" +
        "   \"msgid\" : \"Hallo {{name}}, du bist jetzt {{age}} Jahre alt\"\n" +
        "}";


    group('L10NMessage', () {
        setUp(() {
        });

        test('> Creation', () {
            final L10N l10n = new L10N("Hallo Mike");
            expect(l10n,isNotNull);

            expect(l10n.msgid,"Hallo Mike");
            expect(l10n.message,"Hallo Mike");
        }); // end of 'Creation' test

        test('> const Creation', () {
            const L10N l10n = const L10N("Hallo Mike II");
            expect(l10n,isNotNull);

            expect(l10n.msgid,"Hallo Mike II");
            expect(l10n.message,"Hallo Mike II");
        }); // end of 'const Creation' test

        test('> Create with l10n-function', () {

            final L10N _l10n = l10n("Hallo {{?}}",{ "?" : "Welt" });
            expect(_l10n,isNotNull);

            expect(_l10n.msgid,"Hallo {{?}}");
            expect(_l10n.message,"Hallo Welt");

        }); // end of 'Create with l10n-function' test

        test('> l10n function', () {
            expect(l10n("Hello {{what}}",{ "what" : "World" }).message, "Hello World");
        }); // end of 'l10n function' test

        test('> Creation with vars', () {
            final L10N l10n = const L10N("Hallo {{name}}, du bist jetzt {{age}} Jahre alt",const { "name" : "Mike", "age" : 47} );
            expect(l10n,isNotNull);

            //logger.info(l10n.toString());

            expect(l10n.message,"Hallo Mike, du bist jetzt 47 Jahre alt");

        }); // end of 'Creation with vars' test

        test('> from Json', () {
            final L10N l10n = new L10NImpl.fromJson(jsonToTest);

            expect(l10n,isNotNull);

            expect(l10n.msgid,"Hallo {{name}}, du bist jetzt {{age}} Jahre alt");
            expect(l10n.message,"Hallo Mike, du bist jetzt 47 Jahre alt");

            expect(l10n.vars.length,2);
            expect(l10n.vars["name"],"Mike");
            expect(l10n.vars["age"],47);
        }); // end of 'from Json' test

        test('> from Json ohne Vars', () {
            final L10N l10n = new L10NImpl.fromJson(jsonToTestOhneVars);

            expect(l10n,isNotNull);

            expect(l10n.msgid,"Hallo {{name}}, du bist jetzt {{age}} Jahre alt");

            expect(l10n.vars.length,0);
        }); // end of 'from Json ohne Vars' test

        test('> toJson (L10N)', () {
            final L10N l10n = new L10N.fromJson(jsonToTestOhneVars);

            expect(l10n,isNotNull);

            expect(l10n.msgid,"Hallo {{name}}, du bist jetzt {{age}} Jahre alt");

            expect(l10n.vars.length,0);
        }); // end of 'toJson (L10N)' test

        test('> Translatable', () {
            final Name name = new Name("Mike");

            expect(name,new isInstanceOf<Translatable>() );
            expect(name.l10n.message,"My name is Mike");
        }); // end of 'Translatable' test

    });
    // end 'L10NMessage' group
}
