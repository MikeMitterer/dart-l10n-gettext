part of l10n;

abstract class L10N {
    /// Key for Translation
    String get msgid;

    /// Vars for KEY
    Map<String, dynamic> get vars;

    /// Untranslated msgid but vars set
    String get message;

    const factory L10N(final String msgid,[ final Map<String, dynamic> vars ]) = L10NImpl;

    factory L10N.fromJson(final data) = L10NImpl.fromJson;

    /// Can be serialized to Json
    Map<String, dynamic> toJson();

    String toString();

    String toPrettyString();
}

/// Interface für alle Klassen die übersetzt werden können
abstract class Translatable {
    L10N get l10n;
}

/// Basisklasse / Interface für den Translator.
/// call wird gleich hier implementiert.
///
///     final L10NTranslate _translator = new L10NTranslate.withTranslations( <String,Map<String,String>> {
///         "en" : {
///             "Could not find Job-ID: {{jobid}}" : "Could not find Job-ID: {{jobid}}"
///         },
///
///         "de" : {
///             "Could not find Job-ID: {{jobid}}" : "Konnte die JOB-ID {{jobid}} nicht finden..."
///         }
///     });
///
///     class SampleModule extends di.Module {
///         SampleModule() {
///             bind(Translator, toValue: _translator);
///         }
///     }
@di.injectable
abstract class Translator {
    String translate(final L10N l10n);

    String call(final L10N l10n) {
        return translate(l10n);
    }
}

abstract class TranslationProvider {

}
