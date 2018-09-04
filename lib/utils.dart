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

library l10.utils;

import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:validate/validate.dart';

final Logger _logger = new Logger("l10n.utils");

String makePrettyJsonString(final json) {
    Validate.notEmpty(json);

    final JsonEncoder encoder = const JsonEncoder.withIndent('   ');
    return encoder.convert(json);
}

/// Goes through the files
void iterateThroughDirSync(final String dir,final List<String> extensions,  final List<String> dirsToExclude, void callback(final File file)) {
    String scanningMessage() => Intl.message("Scanning",desc: "In '_iterateThroughDirSync'");
    _logger.info("${scanningMessage()}: $dir");

    // its OK if the path starts with packages but not if the path contains packages (avoid recursion)
    final RegExp regexp = new RegExp("^/*packages/*");

    final Directory directory = new Directory(dir);
    if (directory.existsSync()) {
        directory.listSync(recursive: true).where((final FileSystemEntity entity) {
            _logger.finer("Entity: ${entity}");

            bool isValidExtension(final String path)
                => extensions.any((final String extension) => path.toLowerCase().endsWith("${extension.toLowerCase()}"));

            bool isUsableFile = (entity != null
                && FileSystemEntity.isFileSync(entity.path)
                && isValidExtension(entity.path));

            if(!isUsableFile) {
                return false;
            }
            if(entity.path.contains("packages")) {
                // return only true if the path starts!!!!! with packages
                return entity.path.contains(regexp);
            }

            if(entity.path.startsWith(".pub/") || entity.path.startsWith("./.pub/") ||
                entity.path.startsWith(".git/") || entity.path.startsWith("./.git/") ||
                entity.path.startsWith("build/") || entity.path.startsWith("./build/")){
                return false;
            }

            for(final String dirToExclude in dirsToExclude) {
                final String dir = dirToExclude.trim();
                if(entity.path.startsWith("${dir}/") || entity.path.startsWith("./${dir}/")) {
                    return false;
                }
            }

            return true;

        }).map((final FileSystemEntity entity) => new File(entity.path))
            .forEach((final File file) {
            _logger.fine("  Found: ${file}");
            callback(file);
        });
    }
}

