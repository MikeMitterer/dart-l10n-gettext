@TestOn("content-shell")
import 'package:test/test.dart';

import '../config.dart';

main() {
    // final Logger _logger = new Logger("unit.test.RegExp");
    configLogging();

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

        test('> Packages', () {
            final RegExp regexp = new RegExp("^/*packages/*");

            expect(regexp.hasMatch("/packages/noch/ein"),isTrue);
            expect(regexp.hasMatch("packages/noch/ein"),isTrue);
            expect(regexp.hasMatch("/packages/test.dart"),isTrue);
            expect(regexp.hasMatch("packages/test.dart"),isTrue);

            expect(regexp.hasMatch("hallo/packages/test.dart"),isFalse);
            expect(regexp.hasMatch("/hallo/packages"),isFalse);


        }); // end of 'Packages' test

    });
    // end 'RegExp' group
}
