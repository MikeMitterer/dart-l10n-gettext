l10n / (gettext-oriented) PO-File Generator
-------------------------------------------
> Helps to localize your application

Before your start:
   - [A Quick Gettext Tutorial](http://www.labri.fr/perso/fleury/posts/programming/a-quick-gettext-tutorial.html)

#### Install 
```bash
$ pub global activate l10n
```

### System requirements
Install the following cmdline-Applications:
* xgettext
* msginit
* msgmerge

To verify it they are on your system type:
```bash
    mkl10n -s 
```
If you get an error message - do the following:
```bash
    $ brew install gettext
    # on Linux: apt-get install gettext
```

### How to use it
[![Screenshot][1])](https://youtu.be/qj4W-iPKP7s)  
(You have to watch it in 1080p - sorry! Better screencast will follow)

   - Download the example from `samples/cmdline`
   - Run `pub update`
   - Run `mkl10n .`  
   Generates the required .po,.pot files and the lib/locale/messages.dart
   - Translate the generated .po-File (`locale/<your localr>/messages.po`)
   - Run `mkl10n .` again
   
Run `dart bin/cmdline.dart -s` - you should see the translated strings

Play with `dart bin/cmdline.dart -l de -s` and `dart bin/cmdline.dart -l en -s`   

**This is the most important code-part:**  
_cmdline/Config.dart_

```dart
    Map<String,String> get settings {
        final Map<String,String> settings = new Map<String,String>();

        // Everything within l10n(...) will be in your .po File
        settings[translate(l10n("loglevel"))]              = loglevel;

        // 'translate' will translate your ID/String 
        settings[translate(l10n("Config folder"))]         = configfolder;
        settings[translate(l10n("Config file"))]           = configfile;
        settings[translate(l10n("Locale"))]                = locale;


        if(dirstoscan.length > 0) {
            settings[translate(l10n("Dirs to scan"))]      = dirstoscan.join(", ");
        }

        return settings;
    }

```

### How to use it with Material Design 4 Dart

Check out this sample on GitHub:  
   - [mdld_translate](https://github.com/MikeMitterer/dart-material-design-lite-site/tree/master/samples/mdld_translate)
   
This sample also shows the usage with Dice - the dependency injection framework
   
HTML-Translation: (_index.html_)
```html
    <!-- /* Comment added from HTML-File */ -->
    <span translate>_('Translate me')</span>
```

#### Sub-Translations
Since 0.11.0 Sub-Translations are possible - here is the explanation:
 
```
locale/de/.../messages.po: 
    msgid: "Servermessage {{statuscode-400}}."
    msgstr: "Fehlerhafte Anfrage"
    
locale/en/.../messages.po: 
    msgid: "Servermessage {{statuscode-400}}."
    msgstr: ""
    
```

```dart
    final int major = 400;
    
    // This produces a msgid "Servermessage {{status}}." in your PO-File.
    // You can translate it as usual 
    final L10N l = new L10N( "Servermessage {{status}}.", { "status"  : "{{statuscode-${major}}}" });
    expect(l.message,"Servermessage {{statuscode-400}}.");

    // No translation for en - so fallback to msgid
    expect(translate(l),"Servermessage {{statuscode-400}}.");

    // But what we really want is what I call Sub-Translation
    translate.locale = "de";
    expect(translate(l),"Fehlerhafte Anfrage");
    
    /* 
    Internal way of sub-translation: 
      Replace vars in L10N message -> Servermessage {{statuscode-400}}.
      Check if there is a translation - return it, if not, return the msgid
    */
```

<b>Drawback</b><br>
You have to add the msgid "Servermessage {{statuscode-400}}." by hand to your <strong>POT</strong>-File.<br>
The rest is done be the nice merging-feature of l10n/msgmerge 


### If you have problems
* [Issues][2]

## Links
   - [GNU gettext utilities](https://www.gnu.org/software/gettext/manual/gettext.html)
   
### License

    Copyright 2017 Michael Mitterer (office@mikemitterer.at), 
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
    
    
If this plugin is helpful for you - please [(Circle)](http://gplus.mikemitterer.at/) me.

[1]: https://raw.githubusercontent.com/MikeMitterer/dart-l10n-gettext/master/doc/_resources/screenshot.png
[2]: https://github.com/MikeMitterer/dart-l10n-gettext/issues

