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

/// A function that takes a message and does something useful with it.
typedef void OnMessage(String message);

/// A particular message extraction run.
///
///  This encapsulates all the state required for message extraction so that
///  it can be run inside a persistent process.
class L10NMessageExtraction {
    final Logger _logger = new Logger("l10n.extractor.L10NMessageExtraction");

    /// If this is true, print warnings for skipped messages. Otherwise, warnings
    /// are suppressed.
    bool suppressWarnings = false;

    /// If this is true, then treat all warnings as errors.
    bool warningsAreErrors = false;

    /// This accumulates a list of all warnings/errors we have found. These are
    /// saved as strings right now, so all that can really be done is print and
    /// count them.
    List<String> warnings = [];

    /// Were there any warnings or errors in extracting messages.
    bool get hasWarnings => warnings.isNotEmpty;

    /// The root of the compilation unit, and the first node we visit. We hold
    /// on to this for error reporting, as it can give us line numbers of other
    /// nodes.
    CompilationUnit root;

    /// An arbitrary string describing where the source code came from. Most
    /// obviously, this could be a file path. We use this when reporting
    /// invalid messages.
    String origin;

    /// Parse the source of the Dart program file [file] and return a Map from
    /// message names to [IntlMessage] instances.
    ///
    /// If [transformer] is true, assume the transformer will supply any "name"
    /// and "args" parameters required in Intl.message calls.
    Map<String, MainMessage> parseFile(final File file) {
        // Optimization to avoid parsing files we're sure don't contain any messages.
        final contents = file.readAsStringSync();

        origin = file.path;
        if (contents.contains("l10n(")) {
            root = _parseCompilationUnit(contents, origin);
        }
        else { return {}; }

        final visitor = new L10NFindingVisitor(this);
        root.accept(visitor);


        return visitor.messages;
    }

    // - private -----------------------------------------------------------------------------------

    CompilationUnit _parseCompilationUnit(final String contents, final String origin) {
        try {
            return parseCompilationUnit(contents);
        }
        on AnalyzerErrorGroup {
            print("Error in parsing $origin, no messages extracted.");
            rethrow;
        }
    }

    String _reportErrorLocation(final AstNode node) {
        final result = new StringBuffer();
        if (origin != null) result.write("    from $origin");

        final info = root.lineInfo;
        if (info != null) {
            var line = info.getLocation(node.offset);
            result.write("    line: ${line.lineNumber}, column: ${line.columnNumber}");
        }
        return result.toString();
    }

    /// Either just log the warning or throws [L10NMessageExtractionException]
    /// depends on [suppressWarnings] and [warningsAreErrors]-Settings
    ///
    void _makeWarning(final String message) {
        if(!suppressWarnings) {
            _logger.warning(message);
        }
        if(warningsAreErrors) {
            throw L10NMessageExtractionException(message);
        }
    }
}

/// This visits the program source nodes looking for Intl.message uses
/// that conform to its pattern and then creating the corresponding
/// IntlMessage objects. We have to find both the enclosing function, and
/// the Intl.message invocation.
class L10NFindingVisitor extends GeneralizingAstVisitor {
    final Logger _logger = new Logger("l10n.extractor.L10NFindingVisitor");

    L10NFindingVisitor(this.extraction);

    /// The message extraction in which we are running.
    final L10NMessageExtraction extraction;

    /// Accumulates the messages we have found, keyed by name.
    final Map<String, MainMessage> messages = new Map<String, MainMessage>();

    /// Examine method invocations to see if they look like calls to l10n.
    /// If we've found one, stop recursing. This is important because we can have
    /// Intl.message(...Intl.plural...) and we don't want to treat the inner
    /// plural as if it was an outermost message.
    @override
    void visitMethodInvocation(MethodInvocation node) {
        _logger.info("  visitMethodInvocation ${node}");
        if (!_createMessage(node)) {
            super.visitMethodInvocation(node);
        }
    }

    /// Return true if [node] matches the pattern we expect for l10n()
    bool _looksLikeL10NFunction(final MethodInvocation node) {
        if (node.methodName.name != "l10n") {
            return false;
        }

        final arguments = node.argumentList.arguments;
        if(arguments.length < 1 || arguments.length > 2) {
            return false;
        }

        if(arguments.first is! SimpleStringLiteral) {
            return false;
        }

        // e.g. l10n("Test 2 - Plural Name: {name}",{ "name" : "Mike" });
        if(arguments.length == 2 && arguments.last is! MapLiteral) {
            return false;
        }

        return true;
    }



    /// Check that the node looks like an Intl.message invocation, and create
    /// the [IntlMessage] object from it and store it in [messages]. Return true
    /// if we successfully extracted a message and should stop looking. Return
    /// false if we didn't, so should continue recursing.
    bool _createMessage(final MethodInvocation node) {
        if (!_looksLikeL10NFunction(node)) return false;

        try {
            final MainMessage message = _messageFromNode(node);
            _addMessage(message);

            // We found a message, valid or not (hmmm - it should be valid??). Stop recursing.
            return true;

        } on L10NMessageExtractionException catch(e) {

            final err = new StringBuffer()
                ..write("Skipping invalid Intl.message invocation\n    <$node>\n")
                ..writeAll(
                    ["    reason: ${e.message}\n", extraction._reportErrorLocation(node)]);

            extraction._makeWarning(err.toString());
        } catch(e,s) {
            _logger.shout("Unexpected exception: $e, $s");
            throw L10NMessageExtractionException("Unexpected exception: $e, $s");
        }
        
        return false;
    }


    /// Perform any post-construction validations on the message and
    /// ensure that it's not a duplicate.
    void _addMessage(final MainMessage message) {
        message.validate();

        final existing = messages[message.name];
        if (existing != null) {
            final existingCode =
                existing.toOriginalCode(includeDesc: false, includeExamples: false);

            final messageCode =
                message.toOriginalCode(includeDesc: false, includeExamples: false);
            
            if (existingCode != messageCode) {
                extraction._makeWarning("WARNING: Duplicate message name:\n"
                    "'${message.name}' occurs more than once in ${extraction.origin}");
            }
        }
        else {
            if (!message.skip) {
                messages[message.name] = message;
            }
        }
    }

    /// Create a MainMessage from [node] using the name and
    /// parameters of the last function/method declaration we encountered,
    /// and the values we get by calling [extract].
    MainMessage _messageFromNode(final MethodInvocation node) {
        final message = new MainMessage();

        message.sourcePosition = node.offset;
        message.endPosition = node.end;
        //message.arguments = parameters.parameters.map((x) => x.identifier.name).toList();
        //message.arguments = node.argumentList.arguments.map((final Expression x) => x.n)
        message.arguments = [ /*node.argumentList.arguments.first.toString()*/ ];
        final arguments = node.argumentList.arguments;
        final iv = InterpolationVisitor(message);
        arguments.first.accept(iv);
        if(iv.pieces.isNotEmpty) {
            message.addPieces(iv.pieces);
            //message.addPieces([ arguments.first. ]);
        }

        _logger.info("    Node-Name: ${node.methodName.name}, Args: ${arguments.join(", ")}");

        // We only rewrite messages with parameters, otherwise we use the literal
        // string as the name and no arguments are necessary.
        if (!message.hasName) {
            _logger.info("      Message: $message without a name");
            if (arguments.first is SimpleStringLiteral || arguments.first is AdjacentStrings) {

                // _logger.info("${arguments.first}:${arguments.first.runtimeType}");

                // If there's no name, and the message text is a simple string, compute
                // a name based on that plus meaning, if present.
                var simpleName = (arguments.first as StringLiteral).stringValue;
                message.name = _computeMessageName(message.name, simpleName, message.meaning);

                _logger.info("        -> ${message.name}");
            }
        }
        return message;
    }
}

/// Given an interpolation, find all of its chunks, validate that they are only
/// simple variable substitutions or else Intl.plural/gender calls,
/// and keep track of the pieces of text so that other parts
/// of the program can deal with the simple string sections and the generated
/// parts separately. Note that this is a SimpleAstVisitor, so it only
/// traverses one level of children rather than automatically recursing. If we
/// find a plural or gender, which requires recursion, we do it with a separate
/// special-purpose visitor.
class InterpolationVisitor extends SimpleAstVisitor {
    final Message message;

    InterpolationVisitor(this.message);

    List pieces = [];
    String get extractedMessage => pieces.join();

    void visitAdjacentStrings(AdjacentStrings node) {
        node.visitChildren(this);
        super.visitAdjacentStrings(node);
    }

    void visitStringInterpolation(StringInterpolation node) {
        node.visitChildren(this);
        super.visitStringInterpolation(node);
    }

    void visitSimpleStringLiteral(SimpleStringLiteral node) {
        pieces.add(node.value);
        super.visitSimpleStringLiteral(node);
    }

    void visitInterpolationString(InterpolationString node) {
        pieces.add(node.value);
        super.visitInterpolationString(node);
    }

    void visitInterpolationExpression(InterpolationExpression node) {
        return handleSimpleInterpolation(node);
    }


    void handleSimpleInterpolation(InterpolationExpression node) {
        var index = arguments.indexOf(node.expression.toString());
        if (index == -1) {
            throw new IntlMessageExtractionException(
                "Cannot find argument ${node.expression}");
        }
        pieces.add(index);
    }

    List get arguments => message.arguments;
}

/// If a message is a string literal without interpolation, compute
/// a name based on that and the meaning, if present.
// NOTE: THIS LOGIC IS DUPLICATED IN intl AND THE TWO MUST MATCH.
String _computeMessageName(String name, String text, String meaning) {
    if (name != null && name != "") return name;
    return meaning == null ? text : "${text}_${meaning}";
}


