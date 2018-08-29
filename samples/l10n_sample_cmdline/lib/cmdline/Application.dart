part of cmdline;

class Application {
    final Logger _logger = new Logger("cmdline.Application");

    /// Commandline options
    final Options options;

    Application() : options = new Options();

    void run(List<String> args,final String locale) {

        try {
            final ArgResults argResults = options.parse(args);
            final Config config = new Config(argResults,locale);

            configLogging(show: Level.INFO);

            if (argResults.wasParsed(Options._ARG_LOCALE)) {
                TRANSLATOR.locale = config.locale;
            }

            if (argResults.wasParsed(Options._ARG_HELP) || (config.dirstoscan.length == 0 && args.length == 0)) {
                options.showUsage();
                return;
            }

            if (argResults.wasParsed(Options._ARG_SETTINGS)) {
                config.printSettings();
                return;
            }

            bool foundOptionToWorkWith = false;
            if (!foundOptionToWorkWith) {
                options.showUsage();
            }
        }

        on FormatException
        catch (error) {
            _logger.shout(error);
            options.showUsage();
        }
    }



    // -- private -------------------------------------------------------------

}
