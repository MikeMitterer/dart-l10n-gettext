part of l10n.app;

/**
 * Defines default-configurations.
 * Most of these configs can be overwritten by commandline args.
 */
class Config {
    final Logger _logger = new Logger("mkl10llocale.Config");

    static const String _KEY_LOCALE_DIR                 = "localeDir";
    static const String _KEY_TEMPLATES_DIR              = "templatesDir";
    static const String _KEY_HEADER_TEMPLATE            = "headertemplate";
    static const String _KEY_POT_DIR                    = "potdir";
    static const String _KEY_POT_FILENAME               = "potfile";
    static const String _KEY_PO_FILENAME                = "pofile";
    static const String _KEY_JSON_FILENAME              = "jsonfilename";
    static const String _KEY_DART_FILENAME              = "dartfilename";
    static const String _KEY_LIB_PREFIX                 = "libprefix";
    static const String _KEY_LOGLEVEL                   = "loglevel";
    static const String _KEY_LOCALES                    = "locales";
//    static const String _KEY_DART_PATH                  = "dartpath";
    static const String _KEY_SYSTEM_LOCALE              = "systemlocale";
    static const String _KEY_EXCLUDE_DIRS               = Options._ARG_EXCLUDE;

    static const String _KEY_SUPPRESS_WARNINGS          = Options._ARG_SUPPRESS_WARNINGS;
    static const String _KEY_OUTPUT_DIR                 = Options._ARG_OUTPUT_DIR;
    static const String _KEY_OUTPUT_FILE                = 'output_file';
    static const String _KEY_USE_DEFERRED_LOADING       = 'use-deferred-loading';
    static const String _KEY_CODEGEN_MODE               = Options._ARG_CODEGEN_MODE;
    static const String _KEY_CODEGEN_DIR                = Options._ARG_CODEGEN_DIR;
    static const String _KEY_FORCE                      = Options._ARG_FORCE;


    final ArgResults _argResults;
    final _settings = new Map<String,String>();

    Config(this._argResults,final String systemLocale) {

        _settings[_KEY_LOCALE_DIR]              = 'locale';
        _settings[_KEY_TEMPLATES_DIR]           = 'templates';
        _settings[_KEY_HEADER_TEMPLATE]         = 'potheader.tpl';
        _settings[_KEY_POT_DIR]                 = 'templates/LC_MESSAGES';

        _settings[_KEY_POT_FILENAME]            = 'messages.pot';
        _settings[_KEY_PO_FILENAME]             = 'messages.po';

        _settings[_KEY_JSON_FILENAME]           = 'messages.json';
        _settings[_KEY_DART_FILENAME]           = 'messages.dart';

        _settings[_KEY_LIB_PREFIX]              = 'l10n';
        _settings[_KEY_LOGLEVEL]                = 'info';


//        _settings[_KEY_DART_PATH]               = 'lib';

        _settings[_KEY_LOCALES]                 = Intl.shortLocale(systemLocale);
        _settings[_KEY_SYSTEM_LOCALE]           = systemLocale;

        _settings[_KEY_EXCLUDE_DIRS]            = 'test';

        _settings[_KEY_SUPPRESS_WARNINGS]       = 'false';
        _settings[_KEY_OUTPUT_DIR]              = 'l10n';
        _settings[_KEY_OUTPUT_FILE]             = 'intl_messages.arb';
        _settings[_KEY_USE_DEFERRED_LOADING]    = 'true';
        _settings[_KEY_CODEGEN_MODE]            = 'debug';
        _settings[_KEY_CODEGEN_DIR]             = path.join("lib",'_l10n');
        _settings[_KEY_USE_DEFERRED_LOADING]    = 'true';
        _settings[_KEY_FORCE]                   = 'false';

        initializeDateFormatting(_settings[_KEY_SYSTEM_LOCALE],null);

        _overwriteSettingsWithConfigFile();
        _overwriteSettingsWithArgResults();
    }

    List<String> get dirstoscan => _argResults.rest;

    /// Something like: locale/templates/LC_MESSAGES
    String get potdir => "${_settings[_KEY_LOCALE_DIR]}/${_settings[_KEY_POT_DIR]}";

    /// Where the pot-header-template is stored
    String get templatesdir => "${_settings[_KEY_LOCALE_DIR]}/${_settings[_KEY_TEMPLATES_DIR]}";

    /// Filename for Header-Template
    String get headerTemplateFile => "$templatesdir/${_settings[_KEY_HEADER_TEMPLATE]}";

    /// Something like: locale/templates/LC_MESSAGES/messages.pot
    String get potfile => "$potdir/${_settings[_KEY_POT_FILENAME]}";

    /// Something like: locale/en/LC_MESSAGES/messages.po
    String getPOFile(final String locale) => "${_settings[_KEY_LOCALE_DIR]}/$locale/LC_MESSAGES/${_settings[_KEY_PO_FILENAME]}";

    /// Something like: locale/messages.json
    String get jsonfile => "${_settings[_KEY_LOCALE_DIR]}/${_settings[_KEY_JSON_FILENAME]}";

    // Something like: locale/messages.dart
    //String get dartfile => "${_settings[_KEY_DART_PATH]}/${_settings[_KEY_LOCALE_DIR]}/${_settings[_KEY_DART_FILENAME]}";

    String get libprefix => _settings[_KEY_LIB_PREFIX];

    String get loglevel => _settings[_KEY_LOGLEVEL];

    String get locales => _settings[_KEY_LOCALES];

    String get systemLocale => _settings[_KEY_SYSTEM_LOCALE];

    List<String> get excludeDirs => ignoreExclude ? [] : _settings[_KEY_EXCLUDE_DIRS].split(new RegExp(r",\s*"));

    String get configfile => ".mkl10n.yaml";

    bool get suppressWarnings => _settings[_KEY_SUPPRESS_WARNINGS].toLowerCase() == 'true';

    String get outputDir => _settings[_KEY_OUTPUT_DIR];
    String get outputFile => _settings[_KEY_OUTPUT_FILE];

    bool get useDeferredLoading => _settings[_KEY_USE_DEFERRED_LOADING].toLowerCase() == 'true';

    String get codegenMode => _settings[_KEY_CODEGEN_MODE];

    String get codegenDir => _settings[_KEY_CODEGEN_DIR];

    bool get ignoreExclude => _argResults[Options._ARG_IGNORE_EXCLUDED] != null
        && _argResults[Options._ARG_IGNORE_EXCLUDED];

    bool get overwriteLocaleFile => _settings[_KEY_FORCE].toLowerCase() == 'true';

    Map<String,String> get settings {
        final Map<String,String> settings = new Map<String,String>();

        //message() = Intl.message("Code generation dir");
        
        settings[l10n("Config-File")]  = configfile;

        settings["POT-File"]                                    = potfile;
        settings["Header-Template"]                             = headerTemplateFile;
        settings["PO-File"]                                     = getPOFile("<locale>");
        settings["JSON-File"]                                   = jsonfile;
        //settings["DART-File"]                                   = dartfile;
        settings["libprefix (${Config._KEY_LIB_PREFIX})"]       = libprefix;
        settings["loglevel"]                                    = loglevel;
        settings["locales"]                                     = locales;
        settings["System-Locale"]                               = systemLocale;
        settings["Suppress Warnings"]                           = suppressWarnings.toString();
        settings["Output dir for .ARB-Files"]                   = outputDir;
        settings["Output file"]                                 = outputFile;
        settings["Use deferred loading"]                        = useDeferredLoading ? 'yes' : 'no';
        settings["Code generation mode"]                        = codegenMode;
        settings[Intl.message("Code generation dir")]           = codegenDir;
        settings["Code generation mode"]                        = codegenMode;
        settings["Ignore excluded folders"]                     = ignoreExclude ? 'yes' : 'no';
        settings["Overwrite intl_<locale>"]                     = overwriteLocaleFile ? 'yes' : 'no';

        if(dirstoscan.length > 0) {
            settings[(Intl.message("Dirs to scan"))] = dirstoscan.join(", ");
        }
        settings[l10n("Dirs to exclude")
            + " (${Config._KEY_EXCLUDE_DIRS})"]  = excludeDirs.join(", ");

        return settings;
    }

    void printSettings(final Map<String,String> settings) {
        Validate.notEmpty(settings);

        int getMaxKeyLength() {
            int length = 0;
            settings.keys.forEach((final String key) => length = max(length,key.length));
            return length;
        }

        final int maxKeyLength = getMaxKeyLength();

        String prepareKey(final String key) {
            return "${key[0].toUpperCase()}${key.substring(1)}:".padRight(maxKeyLength + 1);
        }

        print(l10n("Settings:"));
        settings.forEach((final String key,final String value) {
            print("    ${prepareKey(key)} $value");
        });

        print("");

        // You will see this comment in the .po/.pot-File
        print(l10n("External commands:"));
        [ xgettext, msginit, msgmerge ].forEach((final ShellCommand command) async {
            String exe = l10n("not installed!");
            try {
                exe = await command.executable;

            } on StateError catch(_) {}

            print("    ${(command.name + ':').padRight(maxKeyLength + 1)} ${exe}");
        });
    }

    // -- private -------------------------------------------------------------

    _overwriteSettingsWithArgResults() {

        /// Makes sure that path does not end with a /
        String checkPath(final String arg) {
            String path = arg;
            if(path.endsWith("/")) {
                path = path.replaceFirst(new RegExp("/\$"),"");
            }
            return path;
        }

        if(_argResults[Options._ARG_LOGLEVEL] != null) {
            _settings[_KEY_LOGLEVEL] = _argResults[Options._ARG_LOGLEVEL];
        }

        if(_argResults[Options._ARG_LIB_PREFIX] != null) {
            _settings[_KEY_LIB_PREFIX] = _argResults[Options._ARG_LIB_PREFIX];
        }

        if(_argResults[Options._ARG_LOCALE_DIR] != null) {
            _settings[_KEY_LOCALE_DIR] = "${checkPath(_argResults[Options._ARG_LOCALE_DIR])}/${_settings[_KEY_LOCALE_DIR]}";
        }

        if(_argResults[Options._ARG_LOCALES] != null) {
            _settings[_KEY_LOCALES] = _argResults[Options._ARG_LOCALES];
        }

//        if(_argResults[Options._ARG_DART_PATH] != null) {
//            _settings[_KEY_DART_PATH] = checkPath(_argResults[Options._ARG_DART_PATH]);
//        }
//
//        if(_argResults[Options._ARG_DART_PATH] != null) {
//            _settings[_KEY_DART_PATH] = checkPath(_argResults[Options._ARG_DART_PATH]);
//        }

        if(_argResults[Options._ARG_EXCLUDE] != null) {
            _settings[_KEY_EXCLUDE_DIRS] = checkPath(_argResults[Options._ARG_EXCLUDE]);
        }

        if(_argResults[Options._ARG_SUPPRESS_WARNINGS] != null) {
            _settings[_KEY_SUPPRESS_WARNINGS] = (_argResults[Options._ARG_SUPPRESS_WARNINGS] as bool) ? 'true' : 'false';
        }

        if(_argResults[Options._ARG_CODEGEN_MODE] != null) {
            _settings[_KEY_CODEGEN_MODE] = _argResults[Options._ARG_CODEGEN_MODE];
        }

        if(_argResults[Options._ARG_OUTPUT_DIR] != null) {
            _settings[_KEY_OUTPUT_DIR] = _argResults[Options._ARG_OUTPUT_DIR];
        }

        if(_argResults[Options._ARG_CODEGEN_DIR] != null) {
            _settings[_KEY_CODEGEN_DIR] = _argResults[Options._ARG_CODEGEN_DIR];
        }

        if(_argResults[Options._ARG_FORCE] != null) {
            _settings[_KEY_FORCE] = (_argResults[Options._ARG_FORCE] as bool) ? 'true' : 'false';
        }
    }

    void _overwriteSettingsWithConfigFile() {
        final File file = new File(configfile);
        if(!file.existsSync()) {
            return;
        }
        final yaml.YamlMap map = yaml.loadYaml(file.readAsStringSync());
        bool foundSetting = false;

        //map.keys.forEach((final key) => print("KK $key"));

        _settings.keys.forEach((final String key) {
            // print("K $key");
            if(map != null && map.containsKey(key)) {
                if(map[key] is bool) {
                    _settings[key] = map[key] ? 'true' : 'false';
                }
                if(map[key] is List) {
                    _settings[key] = (map[key] as List).join(", ");
                }
                else {
                    _settings[key] = map[key].toString();
                }
                print("Found $key in $configfile: ${map[key]}");
                foundSetting = true;
            }
        });
        if(foundSetting) {
            print("");
        }
    }


}