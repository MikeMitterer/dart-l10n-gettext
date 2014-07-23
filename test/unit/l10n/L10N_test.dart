part of unit.test;

class Name implements Translatable {
    final String firstname;

    Name(this.firstname);

    L10N get l10n {
        return new L10NImpl("test.name","My name is {{firstname}}",{ "firstname" : firstname} );
    }
}

testL10N() {
    final Logger logger = new Logger("test.L10NMessage");

    final String jsonToTest = "{\n" +
        "   \"key\" : \"test.message\",\n" +
        "   \"defaultmessage\" : \"Hallo {{name}}, du bist jetzt {{age}} Jahre alt\",\n" +
        "   \"variables\" :\n" +
        "      {\n" +
        "         \"name\" : \"Mike\",\n" +
        "         \"age\" : 47\n" +
        "      }\n" +
        "}";

    final String jsonToTestOhneVars = "{\n" +
    "   \"key\" : \"test.message\",\n" +
    "   \"defaultmessage\" : \"Hallo {{name}}, du bist jetzt {{age}} Jahre alt\"\n" +
    "}";

    group('L10NMessage', () {
        setUp(() {
        });

        test('> Creation', () {
            final L10N message = l10n("test.message","Hallo Mike");
            expect(message,isNotNull);

            expect(message.key,"test.message");
            expect(message.message,"Hallo Mike");
        }); // end of 'Creation' test

        test('> const Creation', () {
            const L10N message = const L10N("test.message","Hallo Mike");
            expect(message,isNotNull);

            expect(message.key,"test.message");
            expect(message.message,"Hallo Mike");
        }); // end of 'const Creation' test

        test('> Creation with vars', () {
            final L10N message = l10n("test.message","Hallo {{name}}, du bist jetzt {{age}} Jahre alt",{ "name" : "Mike", "age" : 47});
            expect(message,isNotNull);

            //logger.info(message.toString());

            expect(message.key,"test.message");
            expect(message.message,"Hallo Mike, du bist jetzt 47 Jahre alt");

        }); // end of 'Creation with vars' test

        test('> from Json', () {
            final L10N message = new L10NImpl.fromJson(jsonToTest);

            expect(message,isNotNull);

            expect(message.key,"test.message");
            expect(message.message,"Hallo Mike, du bist jetzt 47 Jahre alt");

            expect(message.variables.length,2);
            expect(message.variables["name"],"Mike");
            expect(message.variables["age"],47);
        }); // end of 'from Json' test

        test('> from Json ohne Vars', () {
            final L10N message = new L10NImpl.fromJson(jsonToTestOhneVars);

            expect(message,isNotNull);

            expect(message.key,"test.message");
            expect(message.message,"Hallo {{name}}, du bist jetzt {{age}} Jahre alt");

            expect(message.variables.length,0);
        }); // end of 'from Json ohne Vars' test

        test('> Translatable', () {
            final Name name = new Name("Mike");

            expect(name,new isInstanceOf<Translatable>() );
            expect(name.l10n.message,"My name is Mike");
        }); // end of 'Translatable' test

        test('> Translate', () {
            final L10N message = l10n("test.key","Hallo {{message}}",{
                "message" : TRANSLATOR(l10n("test.nokey","Mike + {{name}}", { "name" : "Sarah" })
                )
            });

            expect(message.message,"Hallo Mike + Sarah");
        }); // end of 'Translate' test

        test('> Translate with Table', () {
            final L10NTranslate translator = new L10NTranslate.withMap({ "test.key" : "Willkommen {{message}}", "test.nokey" : "in Australien {{name}}"});

            final L10N message = l10n("test.key","Hallo {{message}}",{
                "message" : translator( l10n("test.nokey","Mike + {{name}}", { "name" : "Sarah" })
                )}
            );

            expect(translator( l10n("test.nokey","Mike + {{name}}", { "name" : "Sarah" })),"in Australien Sarah");
            expect(translator(message),"Willkommen in Australien Sarah");
        }); // end of 'Translate with Table' test

    });
    // end 'L10NMessage' group
}

//------------------------------------------------------------------------------------------------
// Helper
//------------------------------------------------------------------------------------------------
