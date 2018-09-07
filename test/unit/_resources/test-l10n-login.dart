/*
 * Copyright (c) 2017, Michael Mitterer (office@mikemitterer.at),
 * IT-Consulting and Development Limited.
 *
 * All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:html' as dom;
import 'package:l10n/l10n.dart';

//@Component
class LoginDialog /* extends MaterialDialog*/ {

    static const String _DEFAULT_SUBMIT_BUTTON = "Submit";
    static const String _DEFAULT_CANCEL_BUTTON = "Cancel";

    String title = "";
    String yesButton = _DEFAULT_SUBMIT_BUTTON;
    String noButton = _DEFAULT_CANCEL_BUTTON;

    final String username = '';
    final String password = '';

    /// Zeigt den LoginDialog an
    ///
    /// Wenn [undoPossible] auf true gesetzt ist kann der User
    /// den Dialog beenden und kehrt zu seinem vorhergehenden Login zurück
    /// [undoPossible] wird eingeschaltet wenn der User eingeloggt ist
    LoginDialog({final bool undoPossible: false });

    LoginDialog call({ final String title: "",
                         final String yesButton: _DEFAULT_SUBMIT_BUTTON,
                         final String noButton: _DEFAULT_CANCEL_BUTTON }) {

        this.title = title;
        this.yesButton = yesButton;
        this.noButton = noButton;

        return this;
    }

    bool get hasTitle => (title != null && title.isNotEmpty);

    // - EventHandler -----------------------------------------------------------------------------

    void onLogin(final dom.Event event) {
        event.preventDefault();
        //close(MdlDialogStatus.OK);

        print(l10n("Test 1"));

        // Params-Test
        print(l10n("Test 2 - Plural Name: {name}",{ "name" : "Mike" }));

        /// Dart Kommentar II
        print(l10n( "Test 3" ));

        /* Dart Kommentar III */
        print(l10n("Test \"4\""));

        print(l10n("Test (5)"));

        print("Hallo ${l10n('Test 6')} --!");

        // Doesn't create a Intl.Message
        final objL10n = L10N("Call my name!");
        print(objL10n.message);

        final message = l10n("I wish you a nice day!");
        print(message);
    }

    // Must not appear in scan
    String tr(final String value) => l10n(value);

    // - private ----------------------------------------------------------------------------------

    // - template ----------------------------------------------------------------------------------

    //@override
    String template = """
        <div class="mdl-dialog login-dialog1">
            <form method="post" class="right mdl-form mdl-form-registration demo-registration">
                <h5 class="mdl-form__title" translate='yes'>
                <!-- Multi line
                    HTML Kommentar -->
                tr('Test 7')</h5>
                <div class="mdl-form__content">
                    <div class="mdl-textfield">
                        <input class="mdl-textfield__input" type="email" id="email" mdl-model="username" required autofocus>
                        <label class="mdl-textfield__label" for="email" translate='yes'>_('Test 8')</label>
                        <span class="mdl-textfield__error" translate='yes'>_('Test 9: This is not a valid eMail-Address')</span>
                    </div>
                    <div class="mdl-textfield">
                        <input class="mdl-textfield__input" type=password id="password" mdl-model="password"
                               pattern="((?=.*\\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[@#\$%?]).{8,15})" required>
                               
                            <label class="mdl-textfield__label" for="password" translate='yes'>_('Test 10: Password')</label>
                            <span class="mdl-textfield__error" translate='yes'>
                                <!-- HTML-Kommentar -->
                                _('Test 11: 12345678aA16#')
                            </span>    
                    </div>
                    <div class="mdl-form__hint">
                        <a href="#" target="_blank" translate='yes'>_('Test 12: Forgot your password?')</a>
                    </div>
                </div>
                <div class="mdl-form__actions">
                    <button id="submit" class="mdl-button mdl-button--submit
                        mdl-button--raised mdl-button--primary"
                        data-mdl-click="onLogin(\$event)" translate='yes'>
                        _('Test 13: Sign in')
                    </button>
                </div>
            </form>
        </div>
        """;
}