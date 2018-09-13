/*
 * Copyright (c) 2018, Michael Mitterer (office@mikemitterer.at),
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

part of l10n.extractor;

class HTMLExtraction {

    /// An arbitrary string describing where the source code came from. Most
    /// obviously, this could be a file path. We use this when reporting
    /// invalid messages.
    String origin;

    /// In case of scanning a Dart-File we extract only the HTML-Section
    /// that starts with [startTag]
    String startTag = r'<template>';

    /// In case of scanning a Dart-File we extract only the HTML-Section
    /// that ends with [startTag]
    String endTag = r'</template>';

    /// Parse the source of the Dart program file [file] and return a Map from
    /// message names to [IntlMessage] instances.
    ///
    /// If [transformer] is true, assume the transformer will supply any "name"
    /// and "args" parameters required in Intl.message calls.
    Map<String, MainMessage> parseFile(final File file) {
        // This [RegExp] extracts the HTML-Part from Dart-File
        // [\\s\\S] matches anything including newline
        final regExp = RegExp("${startTag}[\\s\\S]*${endTag}", multiLine: true, caseSensitive: false);

        // Optimization to avoid parsing files we're sure don't contain any messages.
        String contents = file.readAsStringSync();

        origin = file.path;
        if (!(contents.contains("l10n(") || contents.contains("_("))) {
            return {};
        }
        if(path.extension(file.path).toLowerCase() == ".dart") {
            if(!regExp.hasMatch(contents)) {
                return {};
            }
            contents = regExp.firstMatch(contents).group(0);
            if(!(contents.contains("l10n(") || contents.contains("_("))) {
                return {};
            }
        }

        final List<l10n.Statement> ast = _parseCompilationUnit(contents, origin);
        final visitor = L10NStatementVisitor(origin);

        ast.where((final l10n.Statement statement) => statement is l10n.L10NStatement)
            .toList().forEach((final l10n.Statement statement) => statement.accept(visitor));

        return visitor.messages;
    }

    // - private -----------------------------------------------------------------------------------

    List<l10n.Statement> _parseCompilationUnit(final String contents, final String origin) {
        final lexer = l10n.Lexer();
        final parser = l10n.Parser();

        final List<l10n.Token> tokens = lexer.scan(contents);
        return parser.parse(origin, tokens);
    }
}

class L10NStatementVisitor extends l10n.Visitor {
    final Logger _logger = new Logger("l10n.extractor.L10NStatementVisitor");

  final String filename;

  /// Accumulates the messages we have found, keyed by name.
  final Map<String, MainMessage> messages = new Map<String, MainMessage>();

  L10NStatementVisitor(this.filename);

  @override
  void visitL10n(final l10n.L10NStatement statement) {
      _logger.fine("  visitL10n ${statement}");

      messages.putIfAbsent(statement.msgid, () {
          final message = new MainMessage();

          message.sourcePosition = statement.line;
          message.endPosition = statement.line;
          message.arguments = [];
          message.name = statement.msgid;

          message.addPieces([ statement.msgid ]);

          return message;
      });
  }
}