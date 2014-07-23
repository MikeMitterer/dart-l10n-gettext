part of l10n;

abstract class L10N {
    String get key;
    String get message;
    Map<String, dynamic> get variables;

    const factory L10N(final String key,final String defaultMessage,[ final Map<String, dynamic> variables ]) = L10NImpl;
}

/// Interface für alle Klassen die übersetzt werden können
abstract class Translatable {
    L10N get l10n;
}

