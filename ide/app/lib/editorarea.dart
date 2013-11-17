// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/**
 * A TabView associated with opened documents. It sends request to an
 * [EditorProvider] to create/refresh editors.
 */
library spark.editorarea;

import 'dart:html';

import 'editors.dart';
import 'ui/widgets/tabview.dart';
import 'workspace.dart';

class EditorTab extends Tab {
  final EditorState session;
  EditorTab(EditorArea parent, this.session)
      : super(parent) {
    label = session.file.name;
    page = createLoadingPlaceHolder();
  }

  /// Creates a place holder so the page can be loaded on demand
  /// TODO(ikarienator): a beautiful loading indicator.
  static DivElement createLoadingPlaceHolder() =>
    new DivElement()..classes.add('editor-tab-loader-placeholder');

  void activateSession() {
    session.withSession().then((session) {
      if (session != this.session) return;
      session.editor.state = session;
      page = session.editor.rootElement;
      session.editor.resize();
    });
  }

  void activate() {
    activateSession();
    super.activate();
  }
}

/**
 * Manage a list of open editors.
 */
class EditorArea extends TabView {
  final EditorProvider editorProvider;
  final Map<EditorState, EditorTab> _tabOfSession = {};
  bool _allowsLabelBar = true;

  EditorArea(Element parentElement,
             this.editorProvider,
             {allowsLabelBar: true})
      : super(parentElement) {
    this.allowsLabelBar = allowsLabelBar;
    showLabelBar = false;
  }

  bool get allowsLabelBar => _allowsLabelBar;
  set allowsLabelBar(bool value) {
    _allowsLabelBar = value;
    showLabelBar = _allowsLabelBar && _tabOfSession.length > 1;
  }

  // TabView
  Tab add(EditorTab tab, {bool switchesTab: true}) {
    _tabOfSession[tab.session] = tab;
    showLabelBar = _allowsLabelBar && _tabOfSession.length > 1;
    return super.add(tab, switchesTab: switchesTab);
  }

  // TabView
  bool remove(EditorTab tab, {bool switchesTab: true}) {
    if (super.remove(tab, switchesTab: switchesTab)) {
      _tabOfSession.remove(tab.session);
      editorProvider.close(tab.session);
      showLabelBar = _allowsLabelBar && _tabOfSession.length > 1;
      return true;
    }
    return false;
  }

  Tab getTabForSession(EditorState session, {bool switchesTab: true}) {
    if (!_tabOfSession.containsKey(session)) {
      var tab = new EditorTab(this, session);
      add(tab, switchesTab: switchesTab);
    } else if (switchesTab) {
      selectedTab = _tabOfSession[session];
    }
    return _tabOfSession[session];
  }

  /// Switches to a file. If the file is not opened and [forceOpen] is `true`,
  /// [selectFile] will be called instead. Otherwise the editor provide is
  /// requested to switch the file to the editor in case the editor is shared.
  void selectFile(Resource file,
                {bool forceOpen: false, bool switchesTab: true}) {
    if (!forceOpen && !editorProvider.isFileOpened(file)) return;
    EditorState session = editorProvider.getEditorSessionForFile(file);
    getTabForSession(session, switchesTab: switchesTab);
  }

  /// Closes the tab for file.
  void closeFile(Resource file) {
    if (!editorProvider.isFileOpened(file)) return;
    EditorState session = editorProvider.getEditorSessionForFile(file);
    if (_tabOfSession.containsKey(session)) {
      _tabOfSession[session].close();
    }
  }
}
