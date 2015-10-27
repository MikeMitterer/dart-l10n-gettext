// ----------------------------------------------------------------------------
// Start der Tests mit:
//      pub run test -p content-shell test/unit/test.dart
//

@TestOn("content-shell")

library unit.test;


//-----------------------------------------------------------------------------
// Notwendige externe includes

import 'package:test/test.dart';
import 'package:intl/intl.dart';

//-----------------------------------------------------------------------------
// Logging

import 'package:logging/logging.dart';
import 'package:logging_handlers/logging_handlers_shared.dart';

//---------------------------------------------------------
// Extra packages (piepag) (http_utils, validate, signer)
//---------------------------------------------------------

import 'package:l10n/l10n.dart';
import 'package:l10n/locale/messages.dart';

//---------------------------------------------------------
// WebApp-Basis (piwab) - webapp_base_dart
//---------------------------------------------------------

//---------------------------------------------------------
// UI-Basis (pibui) - webapp_base_ui
//---------------------------------------------------------

// __ interfaces
// __ tools
//   __ conroller
//   __ decorators
//   __ services
//   __ component

//---------------------------------------------------------
// MobiAd UI (pimui) - mobiad_rest_ui
//---------------------------------------------------------

// __ interfaces
// __ tools
//   __ conroller
//   __ decorators
//   __ services
//   __ component

//---------------------------------------------------------
// Testimports (nur bei Unit-Tests)
//

part "l10n/L10N_test.dart";
part "l10n/L10NTranslation_test.dart";
part "regexp/RegExp_test.dart";

// Mehr Infos: http://www.dartlang.org/articles/dart-unit-tests/
void main() {
    final Logger logger = new Logger("test");

    configLogging();

    testL10N();
    testL10NTranslation();

    testRegExp();
}

// Weitere Infos: https://github.com/chrisbu/logging_handlers#quick-reference

void configLogging() {
    hierarchicalLoggingEnabled = false; // set this to true - its part of Logging SDK

    // now control the logging.
    // Turn off all logging first
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen(new LogPrintHandler());
}
