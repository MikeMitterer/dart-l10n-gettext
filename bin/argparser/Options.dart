part of l10n.app;

/// Commandline params for this [Application]
class Options {
    static const _ARG_LOCALES                   = 'locales';
    static const _ARG_HELP                      = 'help';
    static const _ARG_LOGLEVEL                  = 'loglevel';
    static const _ARG_SETTINGS                  = 'settings';
    static const _ARG_SUPPRESS_WARNINGS         = 'suppress-warnings';
    static const _ARG_LIB_PREFIX                = 'libprefix';
    static const _ARG_LOCALE_DIR                = 'localedir';
    static const _ARG_OUTPUT_DIR                = 'output-dir';
//    static const _ARG_DART_PATH                 = 'dartpath';
    static const _ARG_EXCLUDE                   = 'exclude';
    static const _ARG_CODEGEN_MODE              = 'codegen-mode';
    static const _ARG_CODEGEN_DIR               = 'codegen-dir';
    static const _ARG_IGNORE_EXCLUDED           = 'ignore-exclude';
    static const _ARG_FORCE                     = 'force';

    final ArgParser _parser;

    Options() : _parser = Options._createOptions();

    ArgResults parse(final List<String> args) {
        Validate.notNull(args);
        return _parser.parse(args);
    }

    void showUsage() {
        print(l10n("Usage: mkl10n [options] <dir(s) to scan>"));
        _parser.usage.split("\n").forEach((final String line) {
            print("    $line");
        });

        print("");
        print(l10n("Example:"));
        print("    " + l10n("mkl10n . - Generates lib/locale/messages.dart"));
        print("    " + l10n("mkl10n -l en,de . - Generates translation for en + de"));
        print("");
    }

    // -- private -------------------------------------------------------------

    static ArgParser _createOptions() {
        final ArgParser parser = new ArgParser()

            ..addFlag(_ARG_HELP,            abbr: 'h', negatable: false, help: l10n("Shows this message"))
            ..addFlag(_ARG_SETTINGS,        abbr: 's', negatable: false, help: l10n("Prints settings"))

            ..addOption(_ARG_LOCALES,       abbr: 'l', help: l10n("locales - separated by colon, Sample: --locales en,de,es"))
            ..addOption(_ARG_LOGLEVEL,      abbr: 'v', help: "[ finer | debug | info | warning ]")
            ..addOption(_ARG_LIB_PREFIX,    abbr: 'p', help: l10n("Libprefix for generated DART-File (library <prefix>.locale;)"))
            ..addOption(_ARG_LOCALE_DIR,    abbr: 'd', help: l10n("Defines where to place your locale-Dir"))
            ..addOption(_ARG_OUTPUT_DIR,    abbr: 'a', help: l10n("Folder where .ARB-Files gets stored"))
//            ..addOption(_ARG_DART_PATH,     abbr: 'a', help: l10n("Where should the DART-File go? (<path>/locale/messages.dart)"))
            ..addOption(_ARG_EXCLUDE,       abbr: 'x', help: l10n("Exclude folders from scaning"))

            ..addFlag(_ARG_SUPPRESS_WARNINGS, negatable: true, defaultsTo: true,
                help: l10n("Suppress printing of warnings"))

            ..addOption(_ARG_CODEGEN_MODE,  abbr: 'm', allowed: ['release', 'debug'], defaultsTo: 'debug',
                help: l10n("Mode to run the code generator in. Either release or debug"))

            ..addOption(_ARG_CODEGEN_DIR,  abbr: 'g',
                help: l10n("File where you want to store the generated Dart-Files (Usually inside lib)"))

            ..addFlag(_ARG_IGNORE_EXCLUDED,  abbr: 'i', negatable: false, help: l10n("Ignore excluded folders"))

            ..addFlag(_ARG_FORCE,           abbr: 'f', negatable: false, help: l10n("Overwrites intl_<local> if it exists"))
        ;

        return parser;
    }

}