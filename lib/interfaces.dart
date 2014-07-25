part of l10n;

abstract class L10N {
    /// Key for Translation
    String get msgid;

    /// Vars for KEY
    Map<String, dynamic> get vars;

    /// Untranslated msgid but vars set
    String get message;

    const factory L10N(final String msgid,[ final Map<String, dynamic> vars ]) = L10NImpl;
}

/// Interface für alle Klassen die übersetzt werden können
abstract class Translatable {
    L10N get l10n;
}

abstract class TranslationProvider {

}
