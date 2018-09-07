# ARB Format

    # Generate intl_messages.arb (Project root)
    dart bin/mkl10n.dart .
    
    # Übersetzung erstellen
    cp -f intl_messages.arb intl_de.arb
    
    pub run intl_translation:generate_from_arb --output-dir=lib/l10n \
       --no-use-deferred-loading web/main.dart intl_*.arb
       
## Testing

    # Creates .arb-files for Tests
    #   -a Folder for generated .ARB-Files
    #   -g Folder for generated .dart-Files
    #   -i Inore excluded Folders (by default 'test' is excluded!)       
    #   test/unit/l10n/ - This folder get's scanned
    mkl10n -a test/unit/_resources/l10n -g test/unit/_resources -i test/unit/l10n/            
    
### Links

   - [ARB Specs](https://github.com/googlei18n/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)
   - [Localize Flutter](https://proandroiddev.com/flutter-localization-step-by-step-30f95d06018d)    
   - [Application Resource Bundle Specification](https://github.com/googlei18n/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)
   - [Gen from ARB](https://github.com/dart-lang/intl_translation/blob/master/bin/generate_from_arb.dart)
   - [Extract to ARB](https://github.com/dart-lang/intl_translation/blob/master/bin/extract_to_arb.dart)