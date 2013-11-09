// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library spark.ui.widgets.treeview;

import 'dart:html';
import 'dart:async';
import 'selectable.dart';

/// An event associated with a [TreeNode].
class TreeNodeEvent<T> {
  TreeNode node;
  T data;
  TreeNodeEvent(this.node, this.data);
}

/// A tree node of a treeview.
class TreeNode implements Selectable {
  static const int ICON_MARGIN = 2;

  /// Generic data that can be associated with the [TreeNode].
  var tag;

  // General status
  /// The perent treeview. Events will be sent to the treeview directly.
  final TreeView treeView;
  /// The parent [TreeNode].
  TreeNode _parent;
  /// Depth of the node.
  int _depth;
  /// Indicates if the node is selected.
  bool _selected = false;
  /// URL to the icon.
  String _icon = '';
  /// Size of the icon.
  Point<int> _iconSize;
  /// Whether this tree node can be expanded.
  bool _expandable = false;
  /// Collection of sub elements.
  TreeNodeCollection _children;

  // DOM Elements
  /// Element of the whole node and its children
  DivElement _cellElement;
  /// Element of the row.
  DivElement _lineElement;
  /// Element of the grip icon (the expansion indicator).
  DivElement _gripElement;
  /// Element of the icon.
  DivElement _iconElement;
  /// Element of the label.
  DivElement _labelElement;
  /// Element of all the children.
  DivElement _childrenContainerElement;
  /// Element of the menu; Docked at the right side of the row.
  DivElement _menuElement;
  /// Element of the selection highlight.
  DivElement _highlightElement;

  /// Constructor.
  TreeNode(this.treeView, {
    expanded: false,
    expandable: true,
    selected: false,
    icon: '',
    iconSize: const Point(22, 22)
  }) {
    _constructDom();
    _children = new TreeNodeCollection(treeView,
                                       _childrenContainerElement);
    _setupHandlers();

    this.expandable = expandable;
    this.icon = icon;
    this.iconSize = iconSize;
    this.expanded = expanded;
    this.selected = selected;
  }

  void _constructDom() {
    _gripElement = new DivElement()..classes.add('treeview-grip');
    _iconElement = new DivElement()..classes.add('treeview-icon');
    _labelElement = new DivElement()..classes.add('treeview-label');
    _menuElement = new DivElement()..classes.add('treeview-menu');
    _highlightElement = new DivElement()..classes.add('treeview-highlight');

    _lineElement =
        new DivElement()..classes.add('treeview-line')
                        ..children.addAll([_gripElement,
                                           _iconElement,
                                           _labelElement,
                                           _menuElement,
                                           _highlightElement]);

    _childrenContainerElement =
        new DivElement()..classes.add('treeview-children');

    _cellElement = new DivElement()
        ..classes.add('treeview-node')
        ..children.addAll([_lineElement, _childrenContainerElement]);
  }

  void _setupHandlers() {
    _gripElement.onClick.listen((MouseEvent e) {
      expanded = !expanded;
      e.stopPropagation();
      e.preventDefault();
    });
    _lineElement.onClick.listen(_handleClick);
    _lineElement.onDoubleClick.listen(_handleDoubleClick);
  }

  /**
   * Path to the icon.
   */
  String get icon => _icon;
  void set icon(String text) {
    _icon = text;
    _iconElement.style.backgroundImage = 'url($text)';
    if (_icon.length == 0)
      _iconElement.style.display = 'none';
    else
      _iconElement.style.display = 'inline-block';
  }

  /**
   * Size of the icon.
   */
  Point<int> get iconSize => _iconSize;
  void set iconSize(Point<int> size) {
    _iconElement.style.width = '${size.x + ICON_MARGIN}px';
    _iconElement.style.height = '${size.y + ICON_MARGIN}px';
    _iconElement.style.backgroundSize = '${size.x}px ${size.y}px';
  }

  /**
   * The label text of this node.
   */
  String get label => _labelElement.text;
  void set label(String text) {
    _labelElement.text = text;
  }

  /**
   * The label html of this node.
   */
  String get labelHTML => _labelElement.innerHtml;
  void set labelHTML(String html) {
    _labelElement.innerHtml = html;
  }

  /**
   * The child nodes of this node.
   */
  TreeNodeCollection get children => _children;

  /**
   * Indicates whether the node is expanded.
   */
  bool get expanded => _cellElement.classes.contains('expanded');
  void set expanded(bool expanded) {
    if (_cellElement.classes.contains('expanded') == expanded)
      return;
    _cellElement.classes.toggle('expanded', expanded);
    treeView._onExpansionChangedController.add(
        new TreeNodeEvent(this, expanded));
  }

  bool get expandable => _expandable;
  void set expandable(bool expandable) {
    _expandable = expandable;
    if (expandable) {
      _gripElement.style.display = 'inline-block';
    } else {
      _gripElement.style.display = 'none';
    }
  }
  /**
   * Indicates whether the node is selected.
   */
  bool get selected => _selected;
  void set selected(bool selected) {
    if (_selected == selected) return;
    _selected = selected;
    _lineElement.classes.toggle('selected', selected);
    treeView._onSelectionChangedController.add(
        new TreeNodeEvent(this, selected));
  }

  /**
   * The parent node.
   */
  TreeNode get parent => _parent;
  void set parent(TreeNode parent) {
    if (parent == _parent) return;
    _parent._children.remove(this);
    parent._children.add(this);
  }

  /**
   * Refresh the indentation.
   */
  int get _depthInternal => _depth;
  void set _depthInternal(int depth) {
    _gripElement.style.marginLeft = '${treeView.indentSize * depth}px';
    _children._depthInternal = depth + 1;
  }

  bool _eventIsOnThis(TreeNodeEvent event) => event.node == this;

  /**
   * Streams
   */
  Stream<TreeNodeEvent<MouseEvent>> get onClick =>
      treeView._onClickController.stream.where(_eventIsOnThis);
  Stream<TreeNodeEvent<MouseEvent>> get onDblClick =>
      treeView._onDblClickController.stream.where(_eventIsOnThis);
  Stream<TreeNodeEvent<bool>> get onSelectionChanged =>
      treeView._onSelectionChangedController.stream.where(_eventIsOnThis);
  Stream<TreeNodeEvent<bool>> get onExpansionChanged =>
      treeView._onExpansionChangedController.stream.where(_eventIsOnThis);

  void _handleClick(MouseEvent event) {
    treeView._onClickController.add(new TreeNodeEvent(this, event));
  }

  void _handleDoubleClick(MouseEvent event) {
    treeView._onDblClickController.add(new TreeNodeEvent(this, event));
  }
}

/// Class to represent a collection of child nodes.
class TreeNodeCollection {
  TreeView treeView;
  int _depth = 0;
  List<TreeNode> _nodes = [];
  DivElement _containerElement;

  TreeNodeCollection(this.treeView, this._containerElement);

  /// The count of child nodes.
  int get length => _nodes.length;

  /// Add a [TreeNode] to the subtree.
  void add(TreeNode node) {
    insert(_nodes.length, node);
  }

  /// Insert a [TreeNode] at position [index].
  /// If index is no more than the [length] of this collection,
  /// it will be placed at the index when the insertion is finished.
  /// If index is less than 0 or greater than [length], a [RangeError] will be
  /// raised.
  void insert(int index, TreeNode node) {
    if (index < 0 || index > _nodes.length)
      throw new RangeError('Index out of range');

    if (node.parent != null)
      node.parent._children.remove(node);

    node._depthInternal = _depth;
    _containerElement.children.insert(index, node._cellElement);
    _nodes.insert(index, node);
    if (node.selected)
      treeView.selection.add(node);
  }

  /// Remove a [TreeNode] from the subtree.
  void remove(TreeNode node) {
    if (node.parent != this)
      return;

    treeView.selection.remove(node);
    _containerElement.children.remove(node._cellElement);
    _nodes.remove(node);
    node.parent = null;
  }

  /// Move a sub node from [from] to [to]. If any of the index is out of bound,
  /// a [RangeError] will be raised. Any nodes between them will be shifted one
  /// step forward or backward.
  void move(int from, int to) {
    if (from < 0 || from >= _nodes.length || to < 0 || to >= _nodes.length)
      throw new RangeError('Index out of range');
    if (from == to) return;

    TreeNode targetNode = _nodes[from];
    _containerElement.children.remove(targetNode._cellElement);
    if (from < to) {
      for (int i = from; i < to; i++) {
        _nodes[i] = _nodes[i + 1];
      }
    } else {
      for (int i = from; i > to; i--) {
        _nodes[i] = _nodes[i - 1];
      }
    }
    _nodes[to] = targetNode;
    _containerElement.children.insert(to, targetNode._cellElement);
  }

  /// Traverse the sub tree.
  void traverse({
    void enter(TreeNode element): null,
    void exit(TreeNode element): null
    }) {
    _nodes.forEach((node) {
      if (enter != null) enter(node);
      node._children.traverse(enter: enter, exit: exit);
      if (exit != null) exit(node);
    });
  }

  int get _depthInternal => _depth;
  void set _depthInternal(int depth) {
    _depth = depth;
    _nodes.forEach((node) {
      node._depthInternal = depth;
    });
  }

  /// The first child in the [TreeNodeCollection] or `null` if the collection
  /// is empty.
  TreeNode get firstNode => _nodes.length > 0 ? _nodes.first : null;

  /// The last child in the [TreeNodeCollection] or `null` if the collection is
  /// empty.
  TreeNode get lastNode {
    if (_nodes.length == 0) return null;
    if (_nodes.last.children.length > 0) return _nodes.last.children.lastNode;
    return _nodes.last;
  }
}

/// This class encapsulates a tree view.
class TreeView {
  static const int DEFAULT_INDENT_SIZE = 20;

  /// Element where the [TreeView] is placed inside.
  final Element parentElement;

  int _indentSize;

  /// Selection collection of the tree view.
  final SelectionCollection selection = new SelectionCollection();

  TreeNodeCollection _children;

  DivElement _scroller;
  DivElement _container;

  /// Event stream controllers
  StreamController<TreeNodeEvent<MouseEvent>> _onClickController =
      new StreamController<TreeNodeEvent<MouseEvent>>.broadcast();
  StreamController<TreeNodeEvent<MouseEvent>> _onDblClickController =
      new StreamController<TreeNodeEvent<MouseEvent>>.broadcast();
  StreamController<TreeNodeEvent<bool>> _onSelectionChangedController =
      new StreamController<TreeNodeEvent<bool>>.broadcast();
  StreamController<TreeNodeEvent<bool>> _onExpansionChangedController =
      new StreamController<TreeNodeEvent<bool>>.broadcast();

  /// Event streams
  Stream<TreeNodeEvent<MouseEvent>> get onClick =>
      _onClickController.stream;
  Stream<TreeNodeEvent<MouseEvent>> get onDblClick =>
      _onDblClickController.stream;
  Stream<TreeNodeEvent<bool>> get onSelectionChanged =>
      _onSelectionChangedController.stream;
  Stream<TreeNodeEvent<bool>> get onExpansionChanged =>
      _onExpansionChangedController.stream;

  TreeView(this.parentElement, { indentSize : DEFAULT_INDENT_SIZE }) {
    _constructDom();
    _children = new TreeNodeCollection(this, _container);
    this.indentSize = indentSize;
  }

  void _constructDom() {
    _container = new DivElement()
        ..classes.add('treeview-container');
    _scroller = new DivElement()
        ..classes.add('treeview-scroller')
        ..children.add(_container);
    parentElement.children.add(_scroller);
  }

  /// Top level nodes of the [TreeView].
  TreeNodeCollection get children => _children;

  /// Indentation size of each level in pixel. Setting [indentSize] will trigger
  /// the indentation of the whole tree.
  int get indentSize => _indentSize;
  void set indentSize(int indentSize) {
    _indentSize = indentSize;
    _children._depthInternal = 0;
  }

  /// Traverse the [TreeNode]s. If present, [enter] will be called against a
  /// [TreeNode] before all its descendants, [exit] will be called after all
  /// its descendants. You shall throw an exception to abort the traverse.
  void traverse({
    void enter(TreeNode element): null,
    void exit(TreeNode element): null
    }) {
    _children.traverse(enter: enter, exit: exit);
  }

  /// The first node in the [TreeView] or `null` if the [TreeView] is empty.
  TreeNode get firstNode => _children.firstNode;

  /// The last node in the [TreeView] or `null` if the [TreeView] is empty.
  TreeNode get lastNode => _children.lastNode;
}