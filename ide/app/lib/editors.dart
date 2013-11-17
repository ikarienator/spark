// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/**
 * A library to manage the list of open editors, and persist their state (like
 * their selection and scroll position) across sessions.
 */
library spark.editors;

import 'dart:async';
import 'dart:html' as html;

import 'workspace.dart';

/**
 * Classes implement this interface creates edit sessions for [File]s. To
 * multiple files, [EditorProvider] should maintain a list of opened files to
 * allow quick switching between them.
 */
abstract class EditorProvider {
  /// Returns `true` if file is previously opened.
  bool isFileOpened(File file);

  /// Returns/initiates an edit session for the file. Returns `null` if fails.
  EditorState getEditorSessionForFile(File file);

  /// Inform the editor provider to close a file.
  void close(EditorState session);
}

abstract class Editor {
  /// The root element to put the editor in.
  html.Element get rootElement;

  /// Gets/sets the current session.
  EditorState state;

  /// Resize the editor.
  void resize();
}

abstract class EditorState {
  /// File combined with the editor.
  File get file;

  /// Get/create bounded editor to this Session.
  Editor get editor;

  /// Assure the file of current session is loaded and returns the current
  /// [EditorState].
  Future<EditorState> withSession();

  /// Deserialize the state of an editor.
  /// Returns `true` iff success.
  bool fromMap(Workspace workspace, Map map);

  /// Serializes the state of an editor.
  Map toMap();
}
