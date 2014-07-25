library unit.test;

import 'package:unittest/html_enhanced_config.dart';

//-----------------------------------------------------------------------------
// Notwendige externe includes

import 'package:unittest/unittest.dart';
import 'package:intl/intl.dart';

//-----------------------------------------------------------------------------
// Logging

import 'package:logging/logging.dart';

//---------------------------------------------------------
// Extra packages (piepag) (http_utils, validate, signer)
//---------------------------------------------------------
import 'package:console_log_handler/console_log_handler.dart';
import 'package:l10n/l10n.dart';

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

    useHtmlEnhancedConfiguration();
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
    Logger.root.onRecord.listen(new LogConsoleHandler());
}
