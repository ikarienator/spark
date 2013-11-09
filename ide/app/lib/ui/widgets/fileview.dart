// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library spark.ui.widgets.files_view;

import 'dart:html';

import 'treeview.dart';
import '../../workspace.dart';

/// A class implements a treenode of a [FileView].
class FileNode extends TreeNode {
  Resource resource;
  FileNode(this.resource, FileView fileView)
      : super(fileView, iconSize: new Point(16, 16)) {
    this.label = this.resource.name;
    this.icon = 'chrome://fileicon/${this.resource.name}';
    if (this.resource is Container) {
      this.expandable = true;
      Container container = this.resource;
      container.getChildren().forEach((Resource resource) {
        children.add(new FileNode(resource, fileView));
      });
    } else {
      this.expandable = false;
    }
  }
}

/// This class implements the controller for the list of files.
class FileView extends TreeView {
  final Workspace workspace;
  final Map<Resource, FileNode> _nodeMap = {};
  FileView(
      Element parent,
      this.workspace,
      { indentSize : TreeView.DEFAULT_INDENT_SIZE })
      : super(parent, indentSize: indentSize) {
    reloadData();
    workspace.onResourceChange.listen(_processEvents);
    onClick.listen((e){
      selection.clear();
      selection.add(e.node);
    });
  }

  void reloadData() {
    workspace.getChildren().forEach((Resource resource) {
      children.add(new FileNode(resource, this));
    });

  }

  void selectLastFile() {
    if (_nodeMap.length == 0) return;
    selection.clear();
    selection.add(lastNode);
  }

  void selectFirstFile() {
    if (_nodeMap.length == 0) return;
    selection.clear();
    selection.add(firstNode);
  }

  /// Event handler for workspace events.
  bool _processEvents(ResourceChangeEvent event) {
    Resource resource = event.resource;
    if (event.type == ResourceEventType.ADD) {
      Resource parentResource = resource.parent;
      TreeNode newNode = new FileNode(resource, this);
      _nodeMap[resource] = newNode;
      if (_nodeMap.containsKey(parentResource)) {
        TreeNode parentNode = _nodeMap[parentResource];
        parentNode.children.add(newNode);
      } else {
        children.add(newNode);
      }
    } else if (event.type == ResourceEventType.DELETE) {
      if (_nodeMap.containsKey(resource)) {
        TreeNode node = _nodeMap[resource];
        node.parent.children.remove(node);
        _nodeMap.remove(resource);
        return true;
      }
    }
  }
}
