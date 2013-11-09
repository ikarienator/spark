// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library spark.ui.widgets.selectable;

/// Abstract class for selectable.
abstract class Selectable {
  bool get selected;
  void set selected(bool selected);
}

/**
 * A selection collection synchronized with the selected status of
 * [Selectable]s.
 */
class SelectionCollection {
  Set<Selectable> _selection = new Set<Selectable>();

  /**
   * Returns true if [value] is in the collection.
   */
  bool contains(Selectable value) {
    return _selection.contains(value);
  }

  /**
   * Adds [value] into the collection.
   * Returns `true` if [value] was added to the collection.
   *
   * If [value] already exists, the collection is not changed and `false` is
   * returned.
   */
  bool add(Selectable value) {
    if (!value.selected)
      value.selected = true;
    return _selection.add(value);
  }

  /**
   * Adds all of [elements] to this collection.
   */
  void addAll(Iterable<Selectable> elements) {
    elements.forEach(add);
  }

  /**
   * Removes [value] from the collection. Returns true if [value] was
   * in the collection. Returns false otherwise. The method has no effect
   * if [value] value was not in the collection.
   */
  bool remove(Selectable value) {
    if (value.selected)
      value.selected = false;
    return _selection.remove(value);
  }
  /**
   * Removes each element of [elements] from this collection.
   */
  void removeAll(Iterable<Selectable> elements) {
    elements.forEach(remove);
  }

  /**
   * Returns whether this collection contains all the elements of [other].
   */
  bool containsAll(Iterable<Selectable> other) {
    return other.every(contains);
  }

  /**
   * Clear the collection.
   */
  void clear() {
    while (_selection.length > 0) {
      remove(_selection.first);
    }
  }

  Iterable<Selectable> asIterable() => _selection;
}