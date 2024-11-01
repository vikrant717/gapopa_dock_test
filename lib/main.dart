import 'package:flutter/material.dart';

/// Entrypoint of the application.
void main() {
  runApp(MyApp());
}

/// [Widget] building the [MaterialApp].
class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Dock<Object>(
            items: [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo
            ],
            builder: (icon) {
              return Container(
                constraints: const BoxConstraints(minWidth: 48),
                height: 48,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color:
                      Colors.primaries[icon.hashCode % Colors.primaries.length],
                ),
                child:
                    Center(child: Icon(icon as IconData, color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dock of the reorderable [items].
class Dock<T extends Object> extends StatefulWidget {
  const Dock({
    super.key,
    required this.items,
    required this.builder,
  });

  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder building the provided [T] item.
  final Widget Function(T) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of the [Dock] used to manipulate the [_items].
class _DockState<T extends Object> extends State<Dock<T>>
    with SingleTickerProviderStateMixin {
  /// [T] items being manipulated.
  List<T> _items = [];
  List<T> _filteredItem = [];
  T? removedItem;
  int? removedItemIndex;

  /// Index of the item currently being animated.
  int? _animatingIndex;

  /// Animation controller for zoom-in/zoom-out.
  late AnimationController _controller;

  /// Animation for the scale transition (zoom effect).
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _items.addAll(widget.items);
    _filteredItem.addAll(widget.items);

    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black12,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _filteredItem.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildDraggableItem(item, index);
        }).toList(),
      ),
    );
  }

  /// Builds each draggable item with a zoom effect on tap and draggable behavior.
  Widget _buildDraggableItem(T item, int index) {
    return GestureDetector(
      onTap: () async {
        // Set the animating index to the tapped item
        setState(() {
          _animatingIndex = index;
        });

        await _controller.forward(); // Start animation
        await Future.delayed(
            const Duration(milliseconds: 50)); // Delay for a short moment
        await _controller.reverse(); // Reverse animation

        // Reset animating index
        setState(() {
          _animatingIndex = null;
        });
      },
      child: ScaleTransition(
        scale: _animatingIndex == index
            ? _animation
            : const AlwaysStoppedAnimation(1.0),
        child: Draggable<T>(
          data: item,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: Material(
            color: Colors.transparent,
            child: widget.builder(item), // The icon shown when dragging
          ),
          childWhenDragging: Opacity(
            opacity: 1, // Change appearance when dragging
            child: widget.builder(item),
          ),
          onDragStarted: () {
            setState(() {
              removedItem = item;
              removedItemIndex = index;
              _filteredItem.remove(item);
            });
          },
          onDraggableCanceled: (_, __) {
            setState(() {
              if (removedItem != null && removedItemIndex != null) {
                _filteredItem.insert(removedItemIndex!, removedItem!);
                removedItem = null;
                removedItemIndex = null;
                _controller.reverse(); // Expand the dock back
              }
            });
          },
          child: DragTarget<T>(
            onWillAccept: (data) => data != item,
            onAcceptWithDetails: (DragTargetDetails<T> details) {
              setState(() {
                final receivedItem = details.data;
                final oldIndex = _filteredItem.indexOf(receivedItem);

                // Remove the item from the old position
                if (oldIndex != -1) {
                  _filteredItem.removeAt(oldIndex);
                }

                // Insert the item at the new position
                _filteredItem.insert(index, receivedItem);
              });
            },
            builder: (context, acceptedData, rejectedData) {
              return widget.builder(item); // Build the icon in its place
            },
          ),
        ),
      ),
    );
  }
}
