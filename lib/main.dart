import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Dock<Object>(
            items: const [
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

class Dock<T extends Object> extends StatefulWidget {
  const Dock({
    super.key,
    required this.items,
    required this.builder,
  });

  final List<T> items;
  final Widget Function(T) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

class _DockState<T extends Object> extends State<Dock<T>>
    with SingleTickerProviderStateMixin {
  List<T> _items = [];
  List<T> _filteredItem = [];
  T? removedItem;
  int? removedItemIndex;
  int? _animatingIndex;

  late AnimationController _controller;
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

  Widget _buildDraggableItem(T item, int index) {
    return GestureDetector(
      onTap: () async {
        setState(() {
          _animatingIndex = index;
        });
        await _controller.forward();
        await Future.delayed(const Duration(milliseconds: 50));
        await _controller.reverse();
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
            child: widget.builder(item),
          ),
          childWhenDragging: Opacity(
            opacity: 1, // Reduced opacity for better dragging effect
            child: widget.builder(item),
          ),
          onDragStarted: () {
            setState(() {
              removedItem = item;
              removedItemIndex = index;
              _filteredItem
                  .remove(item); // Temporarily remove item to shrink dock
            });
          },
          onDraggableCanceled: (_, __) {
            setState(() {
              // Reinsert the item if drag is canceled outside
              if (removedItem != null && removedItemIndex != null) {
                _filteredItem.insert(removedItemIndex!, removedItem!);
                removedItem = null;
                removedItemIndex = null;
                _controller.reverse();
              }
            });
          },
          child: DragTarget<T>(
            onWillAccept: (data) => data != item,
            onAcceptWithDetails: (DragTargetDetails<T> details) {
              setState(() {
                final receivedItem = details.data;
                final oldIndex = _filteredItem.indexOf(receivedItem);

                // Remove the item from the old position if needed
                if (oldIndex != -1) {
                  _filteredItem.removeAt(oldIndex);
                }

                // Insert the item at the new position or back to its original position
                _filteredItem.insert(index, receivedItem);
              });
            },
            builder: (context, acceptedData, rejectedData) {
              return widget.builder(item);
            },
          ),
        ),
      ),
    );
  }
}
