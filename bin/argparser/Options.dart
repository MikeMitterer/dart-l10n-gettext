part of l10n.app;

/// Commandline params for this [Application]
class Options {
    static const _ARG_LOCALES       = 'locales';
    static const _ARG_HELP          = 'help';
    static const _ARG_LOGLEVEL      = 'loglevel';
    static const _ARG_SETTINGS      = 'settings';
    static const _ARG_LIB_PREFIX    = 'libprefix';
    static const _ARG_LOCALE_DIR    = 'localedir';
    static const _ARG_DART_PATH     = 'dartpath';
    static const _ARG_EXCLUDE       = 'exclude';

    final ArgParser _parser;

    Options() : _parser = Options._createOptions();

    ArgResults parse(final List<String> args) {
        Validate.notNull(args);
        return _parser.parse(args);
    }

    void showUsage() {
        print(translate(l10n("Usage: mkl10n [options] <dir(s) to scan>")));
        _parser.usage.split("\n").forEach((final String line) {
            print("    $line");
        });

        print("");
        print(translate(l10n("Example:")));
        print("    " + translate(l10n("mkl10n . - Generates lib/locale/messages.dart")));
        print("    " + translate(l10n("mkl10n -l en,de . - Generates translation for en + de")));
        print("");
    }

    // -- private -------------------------------------------------------------

    static ArgParser _createOptions() {
        final ArgParser parser = new ArgParser()

            ..addFlag(_ARG_HELP,            abbr: 'h', negatable: false, help: translate(l10n("Shows this message")))
            ..addFlag(_ARG_SETTINGS,        abbr: 's', negatable: false, help: translate(l10n("Prints settings")))

            ..addOption(_ARG_LOCALES,       abbr: 'l', help: translate(l10n("locales - separated by colon, Sample: --locales en,de,es")))
            ..addOption(_ARG_LOGLEVEL,      abbr: 'v', help: "[ finer | debug | info | warning ]")
            ..addOption(_ARG_LIB_PREFIX,    abbr: 'p', help: translate(l10n("Libprefix for generated DART-File (library <prefix>.locale;)")))
            ..addOption(_ARG_LOCALE_DIR,    abbr: 'd', help: translate(l10n("Defines where to place your locale-Dir")))
            ..addOption(_ARG_DART_PATH,     abbr: 'a', help: translate(l10n("Where should the DART-File go? (<path>/locale/messages.dart)")))
            ..addOption(_ARG_EXCLUDE,       abbr: 'x', help: translate(l10n("Exclude folders from scaning")))
        ;

        return parser;
    }

}