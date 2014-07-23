library l10n.interfaces;

abstract class L10N {
    String get key;
    String get message;
    Map<String, dynamic> get variables;
}

/// Interface für alle Klassen die übersetzt werden können
abstract class Translatable {
    L10N get l10n;
}

