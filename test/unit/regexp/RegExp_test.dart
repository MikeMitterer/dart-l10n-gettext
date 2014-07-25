part of unit.test;

testRegExp() {
    final Logger _logger = new Logger("unit.test.RegExp");

    group('RegExp', () {
        setUp(() {
        });

        test('> Locale', () {
            final RegExp regexp = new RegExp("^[a-z]{2}(?:(?:-|_)[A-Z]{2})*\$");
            expect(regexp.hasMatch("de"), isTrue);
            expect(regexp.hasMatch("de_DE"), isTrue);
            expect(regexp.hasMatch("de_AT"), isTrue);
            expect(regexp.hasMatch("en"), isTrue);

            expect(regexp.hasMatch("1de_DE"), isFalse);

        }); // end of 'Locale' test


    });
    // end 'RegExp' group
}

//------------------------------------------------------------------------------------------------
// Helper
//------------------------------------------------------------------------------------------------
