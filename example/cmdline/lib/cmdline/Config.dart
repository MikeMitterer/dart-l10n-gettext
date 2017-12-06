part of cmdline;

/**
 * Defines default-configurations.
 * Most of these configs can be overwritten by commandline args.
 */
class Config {
    final Logger _logger = new Logger("cmdline.Config");

    static const String _CONFIG_FOLDER     = ".cmdline";

    final ArgResults _argResults;
    final Map<String,dynamic> _settings = new Map<String,dynamic>();

    final String _systemLocale;

    Config(this._argResults,this._systemLocale) {

        _settings[Options._ARG_LOGLEVEL]            = 'info';
        _settings[Options._ARG_LOCALE]              = Intl.shortLocale(_systemLocale);

        _overwriteSettingsWithConfigFile();
        _overwriteSettingsWithArgResults();
    }


    String get configfolder => _CONFIG_FOLDER;

    String get configfile => "config.yaml";

    String get loglevel => _settings[Options._ARG_LOGLEVEL];

    String get locale => _settings[Options._ARG_LOCALE];

    List<String> get dirstoscan => _argResults.rest;

    Map<String,String> get settings {
        final Map<String,String> settings = new Map<String,String>();

        // Everything within l10n(...) will be in your .po File
        settings[translate(l10n("loglevel"))]              = loglevel;

        // 'translate' will translate your ID/String
        settings[translate(l10n("Config folder"))]         = configfolder;
        settings[translate(l10n('Config file'))]           = configfile;
        settings[translate(l10n("Locale"))]                = locale;

        if(dirstoscan.length > 0) {
            settings[translate(l10n("Dirs to scan"))]      = dirstoscan.join(", ");
        }

        return settings;
    }

    void printSettings() {

        int getMaxKeyLength() {
            int length = 0;
            settings.keys.forEach((final String key) => length = max(length,key.length));
            return length;
        }

        final int maxKeyLeght = getMaxKeyLength();

        String prepareKey(final String key) {
            return "${key[0].toUpperCase()}${key.substring(1)}:".padRight(maxKeyLeght + 1);
        }

        print("Settings:");
        settings.forEach((final String key,final String value) {
            print("    ${prepareKey(key)} $value");
        });
    }

    // -- private -------------------------------------------------------------

    void _overwriteSettingsWithArgResults() {
        if(_argResults.wasParsed(Options._ARG_LOGLEVEL)) {
            _settings[Options._ARG_LOGLEVEL] = _argResults[Options._ARG_LOGLEVEL];
        }

        if(_argResults.wasParsed(Options._ARG_LOCALE)) {
            _settings[Options._ARG_LOCALE] = _argResults[Options._ARG_LOCALE];
        }

    }

    void _overwriteSettingsWithConfigFile() {
        final File file = new File("${configfolder}/${configfile}");
        if(!file.existsSync()) {
            return;
        }
        final yaml.YamlMap map = yaml.loadYaml(file.readAsStringSync());
        _settings.keys.forEach((final String key) {
            if(map != null && map.containsKey(key)) {
                _settings[key] = map[key];
                //print("Found $key in $configfile: ${map[key]}");
            }
        });
    }
}