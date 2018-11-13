# l10n 
> Easy to use generator for .arb-Files   
> Helps if you want to translate your application

## l10n >= v2.x
This is a complete rewrite. **l10n** now fully supports `Intl.message` and .ARB-Files

## Usage

   - First install l10n with `pub global activate l10n`
   
Now `mkl10n` should be available on the command-line.

Go to the package you want to translate.

```bash
    mkl10n -l de .
```

*Yes - that's it!*

Your .arb-Files are in `l10n`. You should see `intl_messages.arb` and `intl_de.arb`

*Translate `intl_de.arb`*

```bash
    # Run this command again
    mkl10n -l de .
```

Your generated dart-Files are in `lib/_l10`. You should see `messages_all.dart` and `messages_de.dart`

Import `messages_all.dart` in your app.

```dart
// Include this if you run your app in the browser
import 'package:intl/intl_browser.dart';

// Include this if you run your app on the cmdline
import 'package:intl/intl_standalone.dart';

import 'package:l10n/l10n.dart';
import 'package:<your package>/_l10n/messages_all.dart';

void main() async {
    // Init section
    final shortLocale = await initLanguageSettings(
        () => findSystemLocale(),
        (final String locale) => initializeMessages(locale)
    );    

    // App specific code
    // ...
    String message() => Intl.message("First test");
    print(message());
    print(l10n("Second test"));

    [ "Mike", "Gerda", "Sarh"].forEach((name) {
        print(l10n("Good morning [name]",{ "name" : name }));
    });
    
    // ...
}
```

On [GitHub](https://github.com/MikeMitterer/dart-l10n-gettext/tree/master/example) you can find a
cmdline-example and a browser-example.

[Browser-Example Live-Version](http://l10n4dart.example.mikemitterer.at/)
This is the most simple version of a translated HTML-page I could think of...

## More details
As mentioned above `Intl.message` is fully supported. More infos can be found on [pub](https://pub.dartlang.org/packages/intl#messages)

### Hey but there is more!
In my opinion `Intl.message` is to complex for most situations so I also support my own `l10n` syntax.

```dart
    // Yup - this prints 'Second test'
    // And after you have translated the intl_de.arb to German it prints 'Zweiter Test' 
    print(l10n("Second test"));
```

Check out the source on [GitHub](https://github.com/MikeMitterer/dart-l10n-gettext/blob/master/example/cmdline/bin/cmdline.dart)  

But hey - we also have `HTML-Files`...

Sure!
```html 
<main class="cols">
   <div>
       <div class="translate">_("Hi Mike")</div>
       <div class="translate">_("My cat's name is 'Pebbles'")</div>
   </div>
</main>
```
That's how it works in HTML. Wrap the string you want to translate with `_(...)` 
You can also wrap it with `l10n(...)` but I prefer `_(...)`

It get's even better - if you have a dart-File with [HTML-Included](https://github.com/MikeMitterer/dart-l10n-gettext/blob/master/test/unit/_resources/test-l10n-login.dart#L93-L130) like [so](https://github.com/MikeMitterer/dart-l10n-gettext/blob/master/test/unit/_resources/test-l10n-login.dart#L93-L130)  
it's also fully scanned by `mkl10n` 

## Flutter
This *should* seamlessly work with Flutter. *Should* because I haven't tested it with Flutter  
If it fails please write file an issue report.   

## If you have problems
* [Issues](https://github.com/MikeMitterer/dart-l10n-gettext/issues)

### License

    Copyright 2018 Michael Mitterer (office@mikemitterer.at), 
    IT-Consulting and Development Limited, Austrian Branch

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, 
    software distributed under the License is distributed on an 
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
    either express or implied. See the License for the specific language 
    governing permissions and limitations under the License.
    
    
### Links

   - [ARB Specs](https://github.com/googlei18n/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)
   - [Localize Flutter](https://proandroiddev.com/flutter-localization-step-by-step-30f95d06018d)    
   - [Application Resource Bundle Specification](https://github.com/googlei18n/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)
   - [Gen from ARB](https://github.com/dart-lang/intl_translation/blob/master/bin/generate_from_arb.dart)
   - [Extract to ARB](https://github.com/dart-lang/intl_translation/blob/master/bin/extract_to_arb.dart)
   

