part of l10n.app;

/**
 * Defines default-configurations.
 * Most of these configs can be overwritten by commandline args.
 */
class Config {
    // final Logger _logger = new Logger("mkl10llocale.Config");

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

        settings[l10n("libprefix (${Config._KEY_LIB_PREFIX})")]       = libprefix;
        settings[l10n("loglevel")]                                    = loglevel;
        settings[l10n("locales")]                                     = locales;
        settings[l10n("System-Locale")]                               = systemLocale;
        settings[l10n("Suppress Warnings")]                           = suppressWarnings ? l10n('yes') : l10n('no');
        settings[l10n("Output dir for .ARB-Files")]                   = outputDir;
        settings[l10n("Output file")]                                 = outputFile;
        settings[l10n("Use deferred loading")]                        = useDeferredLoading ? l10n('yes') : l10n('no');
        settings[l10n("Code generation mode")]                        = codegenMode;
        settings[l10n("Code generation dir")]                         = codegenDir;
        settings[l10n("Code generation mode")]                        = codegenMode;
        settings[l10n("Ignore excluded folders")]                     = ignoreExclude ? l10n('yes') : l10n('no');
        settings[l10n("Overwrite intl_<locale>")]                     = overwriteLocaleFile ? l10n('yes') : l10n('no');

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

        if(_argResults[Options._ARG_LOCALES] != null) {
            _settings[_KEY_LOCALES] = _argResults[Options._ARG_LOCALES];
        }

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
                print(l10n("Found '[key]' in [file]: [value]",
                    {"key" : key, "file" : configfile, "value" : map[key] }));

                foundSetting = true;
            }
        });
        if(foundSetting) {
            print("");
        }
    }


}