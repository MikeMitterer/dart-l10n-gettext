part of l10n;

/**
 * Basis für Übersetzungen.
 * Macht zur Zeit im Prinzip nur einen String-Replace
 */
class L10NTranslate extends Translator {
    final Logger _logger = new Logger("l10n.L10NTranslate");

    static const String _DEFAULT_LOCALE = "en";
    final RegExp _regexpLocale = new RegExp("^[a-z]{2}(?:(?:-|_)[A-Z]{2})*\$");

    final Map<String,Map<String,String>> _translations = new Map<String,SplayTreeMap<String,String>>();

    String _locale = _DEFAULT_LOCALE;

    L10NTranslate.withTranslation(final Map<String,String> translation,{ final String locale: _DEFAULT_LOCALE } ) {
        Validate.notEmpty(translation);
        Validate.notBlank(locale);

        setTranslation(translation,locale: locale);
    }

    L10NTranslate.withTranslations(final Map<String,Map<String,String>> translations) {
        Validate.notEmpty(translations);

        translations.forEach((final String key,final Map<String,String> translation) {
            setTranslation(translation,locale: key);
        });
    }

    L10NTranslate();

    void setTranslation(final Map<String,String> translation,{ final String locale: _DEFAULT_LOCALE } ) {
        Validate.notEmpty(translation);
        Validate.notBlank(locale);
        Validate.matchesPattern(locale,_regexpLocale);

        _translations[locale] = new SplayTreeMap<String,String>.from(translation);
    }

    void remove(final String locale) {
        Validate.notBlank(locale);

        if(_translations.containsKey(locale)) {
            _translations.remove(locale);
        } else {
            _logger.warning("Translation-Map for $locale is not available");
        }
    }

    /// Wenn es einen Eintrag für message.key in der _locale Tabelle gibt wir
    /// ein String.replaceAll auf die Variablen in der message ausgeführt
    String translate(final L10N l10n) {
        Validate.notNull(l10n);

        String _replaceVarsInMessage(final Map<String,dynamic> vars,final String msgid) {
            String translated = msgid;

            vars.forEach((final String key,final value) {
                translated = translated.replaceAll("{{$key}}",value.toString());
            });
            return translated;
        }

        String message = _getMessage(l10n.msgid);
        message = _replaceVarsInMessage(l10n.vars,message);

        // maybe _replaceVarsInMessage produced a new msgid...
        // could be: Der Server meldet {{statuscode-400}} bei der API-Key Anforderung.
        // If so - try to translate again!
        if(message.contains(new RegExp("{{.*}}"))) {
            message = _getMessage(message);
        }

        return message;
    }

    String get locale => _locale;

    void set locale(final String locale) {
        Validate.notBlank(locale);
        Validate.matchesPattern(locale,_regexpLocale,"Locale must be something like 'de' or en_US - but was $locale");

        _locale = locale;
    }

    String call(final L10N l10n) {
        return translate(l10n);
    }

    String translateStatusCode(final int status) {
        final L10NImpl message = new L10NImpl (
            "({{statuscode}})",
            { "statuscode" : status }
        );
        return translate(message);
    }

    // -- private -------------------------------------------------------------

    /**
     * Looks for the current locale and the message-id first in the locale specific subtable
     * (_translations[<current locale>] if it finds an entry it returns it, otherwise
     * it tries various fallbacks - for example ( de_DE -> de -> en (as default locale))
     */
    String _getMessage(final String msgid) {
        Validate.notBlank(msgid);

        bool _isKeyInTranslationTable(final String msgid,final String locale) {
            if(_translations.containsKey(locale)) {
                if(_translations[locale] != null && _translations[locale].containsKey(msgid) && _translations[locale][msgid].isNotEmpty) {
                    return true;
                }
            }
            return false;
        }

        String message;
        try {
            Intl.verifiedLocale(locale,(final String testLocale) {
                if(_isKeyInTranslationTable(msgid,testLocale)) {
                    message = _translations[testLocale][msgid];
                    return true;
                }
                return false;
            });
        } on ArgumentError {
            if(_isKeyInTranslationTable(msgid,_DEFAULT_LOCALE)) {
                message = _translations[_DEFAULT_LOCALE][msgid];
            } else {
                message = msgid;
            }
        }

        return message;
    }
}
