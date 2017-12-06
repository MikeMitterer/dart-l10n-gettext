part of cmdline;

/// Commandline options
class Options {
    static const APPNAME                    = 'cmdline';

    static const _ARG_HELP                  = 'help';
    static const _ARG_LOGLEVEL              = 'loglevel';
    static const _ARG_SETTINGS              = 'settings';

    static const _ARG_LOCALE                = 'locale';

    final ArgParser _parser;

    Options() : _parser = Options._createParser();

    ArgResults parse(final List<String> args) {
        Validate.notNull(args);
        return _parser.parse(args);
    }

    void showUsage() {
        print(translate(l10n("Usage: cmdline [options]")));
        _parser.usage.split("\n").forEach((final String line) {
            print("    $line");
        });

        print("");
        print(translate(l10n("Sample:")));
        print("");
        print("    " + translate(l10n("Generates the static site in your 'web-folder':")).padRight(50)
            + "'$APPNAME -g'");

        print("    " + translate(l10n("Tests the loglevel-translation:")).padRight(50)
            + "'$APPNAME -h'");
            
        print("");
    }

    // -- private -------------------------------------------------------------

    static ArgParser _createParser() {
        final ArgParser parser = new ArgParser()

            ..addFlag(_ARG_SETTINGS,         abbr: 's', negatable: false,
                help: translate(l10n("Prints settings")))

            ..addOption(_ARG_LOCALE,         abbr: 'l', help: "Set locale")

            ..addFlag(_ARG_HELP,             abbr: 'h', negatable: false, help: "Shows this message")

            ..addOption(_ARG_LOGLEVEL,       abbr: 'v', help: "Sets the appropriate loglevel", allowed: ['info', 'debug', 'warning'])

        ;

        return parser;
    }
}
