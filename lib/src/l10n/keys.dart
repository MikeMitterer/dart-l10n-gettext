part of l10n;

/**
 * Damit werden die Keys für die L10NMessages erzeugt
 */

/// Jede Klasse kann damit ihren eigenen Scope definieren
class L10NScope {
    final String name; const L10NScope(this.name);

    /// Sample: websocketservice.ticker
    String call(final String subkey) {
        Validate.notBlank(subkey);
        return "${name}.${subkey}";
    }
}

///// Sample: upload.resterror.error.404.0.resource-not-found
//String keyRestError(final RestError error) {
//    Validate.notNull(error);
//    return "resterror.${error.getData().messageid.toString()}";
//}

/// Sample: upload.resterror.404
String keyRestStatus(final int status) {
    return "resterror.$status";
}

/// Smaple: statuscode.404 -> Server nicht gefunden
String keyStatusCode(final int status) {
    return "statuscode.$status";
}


