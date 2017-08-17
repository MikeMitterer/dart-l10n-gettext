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

part of l10n.app;

abstract class ShellCommand {
    /// Command name
    final String name;

    /// Full path to command
    String _exeCache;

    ShellCommand(this.name) {
        Validate.notBlank(name);
    }

    String get executable {
        if (_exeCache == null) {
            _exeCache = whichSync(name);
        }
        return _exeCache;
    }

    Future<ProcessResult> run(List<String> arguments,
        {String workingDirectory,
            Map<String, String> environment,
            bool includeParentEnvironment: true,
            bool runInShell: false,
            Encoding stdoutEncoding: SYSTEM_ENCODING,
            Encoding stderrEncoding: SYSTEM_ENCODING}) =>
            Process.run(executable, arguments,
                workingDirectory: workingDirectory,
                includeParentEnvironment: includeParentEnvironment,
                runInShell: runInShell,
                stdoutEncoding: stdoutEncoding,
                stderrEncoding: stderrEncoding);

    runSync(List<String> arguments,
        {String workingDirectory,
            Map<String, String> environment,
            bool includeParentEnvironment: true,
            bool runInShell: false,
            Encoding stdoutEncoding: SYSTEM_ENCODING,
            Encoding stderrEncoding: SYSTEM_ENCODING}) =>
            Process.runSync(executable, arguments,
                workingDirectory: workingDirectory,
                includeParentEnvironment: includeParentEnvironment,
                runInShell: runInShell,
                stdoutEncoding: stdoutEncoding,
                stderrEncoding: stderrEncoding);

    // - private -------------------------------------------------------------------------------------------------------

}
