library app;

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

part 'world.dart';
part 'utils.dart';
part 'structures.dart';

class VisualsTester extends StatelessWidget {
  const VisualsTester({super.key});

  @override
  Widget build(BuildContext context) {
    /*return GameWidget<_Game>(
      game: _Game(),
    );*/
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}

//class _Game extends FlameGame<_World> {}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with FireOnCalm, LogHelperMixin {
  final Map<String, (ImageInfo, Offset)> _components = {};
  ImageInfo? __worldFile;

  ImageInfo? get _worldFile => __worldFile;

  set _worldFile(ImageInfo? value) {
    if (__worldFile == value) {
      return;
    }
    __worldFile = value;

    setState(() {});
  }

  bool __panEnabled = false;

  bool get _panEnabled => __panEnabled;

  set _panEnabled(bool value) {
    if (__panEnabled == value) {
      return;
    }
    __panEnabled = value;

    setState(() {});
  }

  String? __selectedComponent;

  String? get _selectedComponent => __selectedComponent;

  set _selectedComponent(String? value) {
    if (__selectedComponent == value) {
      return;
    }

    __selectedComponent = value;

    setState(() {});
  }

  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    initializeFireOnCalm(
      calmDownTime: const Duration(milliseconds: 300),
      callbackOnCalm: () async {
        if (mounted) {
          logER("Finally calm");
          _panEnabled = false;
        }
      },
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onKeyEvent(KeyEvent event) {
    logER("Key event: $event");
    if (event.physicalKey == PhysicalKeyboardKey.space) {
      _panEnabled = true;
      notCalm();
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    if (event.buttons == 4) {
      _panEnabled = true;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _panEnabled = false;
  }

  Future<void> _onAddWorld() async {
    final File? file = (await _onPickFiles())?.single;

    if (file == null) {
      return;
    }

    _worldFile = await ImageInfo.fromFile(file);
  }

  Future<void> _onAddComponent() async {
    final List<File>? files = await _onPickFiles();

    if (files == null) {
      return;
    }

    final List<ImageInfo> imageInfos = await ImageInfo.listFromFiles(files);

    if (!mounted) {
      return;
    }

    final Size size = _worldFile?.size ?? MediaQuery.of(context).size;

    final Offset middle = size.center(Offset.zero);

    const Uuid uuid = Uuid();

    _components.addAll(
      imageInfos.asMap().map<String, (ImageInfo, Offset)>(
            (key, value) => MapEntry<String, (ImageInfo, Offset)>(
              uuid.v1(),
              (value, middle),
            ),
          ),
    );

    setState(() {});
  }

  Future<List<File>?> _onPickFiles({bool allowMultiple = false}) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: allowMultiple,
    );

    if (result == null) {
      return null;
    }

    final List<File> files = result.paths.map((path) => File(path!)).toList();

    return files;
  }

  @override
  Widget build(BuildContext context) {
    final Size size = _worldFile?.size ?? MediaQuery.of(context).size;

    final (ImageInfo, Offset)? selectedData = _components[_selectedComponent];

    return Stack(
      fit: StackFit.expand,
      children: [
        InteractiveViewer(
          alignment: Alignment.topLeft,
          clipBehavior: Clip.antiAlias,
          panEnabled: _panEnabled,
          constrained: false,
          child: SizedBox.fromSize(
            size: size,
            child: KeyboardListener(
              focusNode: _focusNode,
              onKeyEvent: _onKeyEvent,
              child: GestureDetector(
                onTap: () {
                  _selectedComponent = null;
                },
                child: MouseRegion(
                  cursor:
                      _panEnabled ? SystemMouseCursors.move : MouseCursor.defer,
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: _onPointerDown,
                    onPointerUp: _onPointerUp,
                    child: Stack(
                      fit: StackFit.expand,
                      clipBehavior: Clip.antiAlias,
                      children: [
                        // World
                        if (_worldFile != null) Image.memory(_worldFile!.data),

                        // Components
                        for (final MapEntry<String, (ImageInfo, Offset)> entry
                            in _components.entries)
                          Positioned.fromRect(
                            rect: Rect.fromCenter(
                              center: entry.value.$2,
                              width: entry.value.$1.size.width,
                              height: entry.value.$1.size.height,
                            ),
                            child: Component(
                              key: ValueKey<String>(entry.key),
                              data: entry.value.$1.data,
                              size: entry.value.$1.size,
                              isSelected: _selectedComponent == entry.key,
                              onSelect: () {
                                _selectedComponent = entry.key;
                              },
                              onDrag: (offset) {
                                logER("onDrag offset: $offset");
                                _components.update(
                                  entry.key,
                                  (value) => (value.$1, offset),
                                );
                                setState(() {});
                              },
                              onResize: (size) {
                                logER("onResize size: $size");
                                _components.update(
                                  entry.key,
                                  (value) => (
                                    value.$1.copyWith(
                                      size: size,
                                    ),
                                    value.$2
                                  ),
                                );
                                setState(() {});
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Property box
        if (_selectedComponent != null)
          Align(
            alignment: Alignment.centerRight,
            child: PropertyBox(
              id: _selectedComponent!,
              size: selectedData!.$1.size,
              offset: selectedData.$2,
              onPositionXChanged: (x) {
                _components.update(
                  _selectedComponent!,
                  (value) {
                    return (value.$1, Offset(x, value.$2.dy));
                  },
                );

                setState(() {});
              },
              onPositionYChanged: (y) {
                _components.update(
                  _selectedComponent!,
                  (value) {
                    return (value.$1, Offset(value.$2.dx, y));
                  },
                );

                setState(() {});
              },
              onSizeXChanged: (x) {
                _components.update(
                  _selectedComponent!,
                  (value) {
                    final Size newSize =
                        value.$1.size.resizeKeepingAspectRatioForWidth(x);
                    return (value.$1.copyWith(size: newSize), value.$2);
                  },
                );

                setState(() {});
              },
              onSizeYChanged: (y) {
                _components.update(
                  _selectedComponent!,
                  (value) {
                    final Size newSize =
                        value.$1.size.resizeKeepingAspectRatioForHeight(y);
                    return (value.$1.copyWith(size: newSize), value.$2);
                  },
                );

                setState(() {});
              },
              onDelete: () {
                _components.remove(_selectedComponent);
                _selectedComponent = null;
              },
            ),
          ),

        // Buttons
        ...[
          Align(
            alignment: const Alignment(-0.4, 0.95),
            child: IconButton(
              tooltip: "Add World",
              icon: const Icon(Icons.wordpress_outlined),
              onPressed: _onAddWorld,
            ),
          ),
          Align(
            alignment: const Alignment(0.6, 0.95),
            child: IconButton(
              tooltip: "Add Component",
              icon: const Icon(Icons.insert_photo_rounded),
              onPressed: _onAddComponent,
            ),
          ),
        ],
      ],
    );
  }
}

typedef OnValueChanged = void Function(double value);

class PropertyBox extends StatelessWidget {
  final String id;
  final Size size;
  final Offset offset;
  final OnValueChanged onPositionXChanged;
  final OnValueChanged onPositionYChanged;
  final OnValueChanged onSizeXChanged;
  final OnValueChanged onSizeYChanged;
  final VoidCallback onDelete;

  const PropertyBox({
    super.key,
    required this.id,
    required this.size,
    required this.offset,
    required this.onPositionXChanged,
    required this.onPositionYChanged,
    required this.onSizeXChanged,
    required this.onSizeYChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        elevation: 1,
        child: SizedBox(
          width: 280,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Properties",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(
                  height: 16,
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Position",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                _TextField(
                  label: "x",
                  value: offset.dx,
                  onValueChanged: onPositionXChanged,
                ),
                _TextField(
                  label: "y",
                  value: offset.dy,
                  onValueChanged: onPositionYChanged,
                ),
                const SizedBox(
                  height: 16,
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Size",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                _TextField(
                  label: "x",
                  value: size.width,
                  onValueChanged: onSizeXChanged,
                ),
                _TextField(
                  label: "y",
                  value: size.height,
                  onValueChanged: onSizeYChanged,
                ),
                const SizedBox(
                  height: 16,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete_forever_rounded),
                  label: const Text("Delete"),
                  onPressed: onDelete,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateColor.resolveWith((states) {
                      if (states.contains(MaterialState.pressed)) {
                        return Colors.red.shade600;
                      } else if (states.contains(MaterialState.hovered)) {
                        return Colors.redAccent;
                      } else if (states.contains(MaterialState.focused)) {
                        return Colors.redAccent.shade400;
                      }
                      return Colors.red;
                    }),
                    foregroundColor: MaterialStateColor.resolveWith((states) {
                      if (states.contains(MaterialState.pressed)) {
                        return Colors.white38;
                      } else if (states.contains(MaterialState.hovered)) {
                        return Colors.white;
                      } else if (states.contains(MaterialState.focused)) {
                        return Colors.white54;
                      }
                      return Colors.white70;
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TextField extends StatefulWidget {
  final String label;
  final double value;
  final OnValueChanged onValueChanged;

  const _TextField({
    // ignore: unused_element
    super.key,
    required this.label,
    required this.value,
    required this.onValueChanged,
  });

  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> with LogHelperMixin {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _TextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != oldWidget.value) {
      logER("setting controller value");
      _controller.text = widget.value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text("${widget.label}: "),
        Expanded(
          child: TextFormField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(
                  r"([+-]?(?=\.\d|\d)(?:\d+)?(?:\.?\d*))(?:[Ee]([+-]?\d+))?",
                ),
              ),
            ],
            onFieldSubmitted: (value) {
              final String text = value.trim();
              final double? number = num.tryParse(text)?.toDouble();

              if (number != null && number != widget.value) {
                widget.onValueChanged(number);
              }
            },
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LittleButton(
              child: const Icon(Icons.arrow_drop_up_rounded),
              onTap: () {
                final String text = _controller.text.trim();
                final num? number = num.tryParse(text);

                if (number != null) {
                  widget.onValueChanged(number + 1);
                }
              },
            ),
            _LittleButton(
              child: const Icon(Icons.arrow_drop_down_rounded),
              onTap: () {
                final String text = _controller.text.trim();
                final num? number = num.tryParse(text);

                if (number != null) {
                  widget.onValueChanged(number - 1);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _LittleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _LittleButton({
    // ignore: unused_element
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(3)),
      hoverColor: Colors.grey,
      onTap: onTap,
      child: IconTheme(
        data: const IconThemeData(
          size: 14,
        ),
        child: child,
      ),
    );
  }
}

class Component extends StatefulWidget {
  final Uint8List data;
  final Size size;
  final bool isSelected;
  final VoidCallback onSelect;
  final void Function(Offset offset) onDrag;
  final void Function(Size size) onResize;

  const Component({
    required super.key,
    required this.data,
    required this.size,
    required this.isSelected,
    required this.onSelect,
    required this.onDrag,
    required this.onResize,
  });

  @override
  State<Component> createState() => _ComponentState();
}

class _ComponentState extends State<Component> with LogHelperMixin {
  List<Widget> _buildResizables() {
    const double resizeableWidth = 6;
    final Widget verticalResizable = SizedBox(
      height: resizeableWidth,
      width:
          (widget.size.width - (resizeableWidth * 2)).clamp(0, double.infinity),
      child: const ColoredBox(color: Colors.redAccent),
    );

    final Widget horizontalResizable = SizedBox(
      width: resizeableWidth,
      height: (widget.size.height - (resizeableWidth * 2))
          .clamp(0, double.infinity),
      child: const ColoredBox(color: Colors.redAccent),
    );

    const Widget cornerResizable = SizedBox(
      height: resizeableWidth,
      width: resizeableWidth,
      child: ColoredBox(color: Colors.red),
    );

    logER("size: ${widget.size}");

    void onPointerMove(PointerMoveEvent event) {
      logER(
        "Local position: ${event.localPosition}, center: ${widget.size.center(Offset.zero)}",
      );
      widget.onResize(
        widget.size.addOffset(
          event.localPosition - widget.size.center(Offset.zero),
        ),
      );
    }

    return [
      // Top
      Align(
        alignment: Alignment.topCenter,
        child: Listener(
          onPointerMove: onPointerMove,
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeUp,
            child: verticalResizable,
          ),
        ),
      ),
      // Bottom
      Align(
        alignment: Alignment.bottomCenter,
        child: Listener(
          onPointerMove: onPointerMove,
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeDown,
            child: verticalResizable,
          ),
        ),
      ),
      // Left
      Align(
        alignment: Alignment.centerLeft,
        child: Listener(
          onPointerMove: onPointerMove,
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeLeft,
            child: horizontalResizable,
          ),
        ),
      ),
      // Right
      Align(
        alignment: Alignment.centerRight,
        child: Listener(
          onPointerMove: onPointerMove,
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeRight,
            child: horizontalResizable,
          ),
        ),
      ),

      // Top-Left
      Align(
        alignment: Alignment.topLeft,
        child: Listener(
          onPointerMove: onPointerMove,
          child: const MouseRegion(
            cursor: SystemMouseCursors.resizeUpLeft,
            child: cornerResizable,
          ),
        ),
      ),

      // Top-Right
      Align(
        alignment: Alignment.topRight,
        child: Listener(
          onPointerMove: onPointerMove,
          child: const MouseRegion(
            cursor: SystemMouseCursors.resizeUpRight,
            child: cornerResizable,
          ),
        ),
      ),

      // Bottom-Left
      Align(
        alignment: Alignment.bottomLeft,
        child: Listener(
          onPointerMove: onPointerMove,
          child: const MouseRegion(
            cursor: SystemMouseCursors.resizeDownLeft,
            child: cornerResizable,
          ),
        ),
      ),

      // Bottom-Right
      Align(
        alignment: Alignment.bottomRight,
        child: Listener(
          onPointerMove: onPointerMove,
          child: const MouseRegion(
            cursor: SystemMouseCursors.resizeDownRight,
            child: cornerResizable,
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Image.memory(widget.data);

    if (widget.isSelected) {
      child = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border.all(),
        ),
        child: child,
      );
      child = Draggable<String>(
        feedback: Opacity(
          opacity: 0.5,
          child: SizedBox.fromSize(
            size: widget.size,
            child: child,
          ),
        ),
        child: child,
        childWhenDragging: const SizedBox.shrink(),
        onDragEnd: (details) {
          widget.onDrag(details.offset + widget.size.center(Offset.zero));
        },
        hitTestBehavior: HitTestBehavior.opaque,
      );
    } else {
      child = GestureDetector(
        onTap: widget.onSelect,
        child: child,
      );
    }

    return SizedBox.fromSize(
      size: widget.size,
      child: Stack(
        children: [
          child,
          if (widget.isSelected) ..._buildResizables(),
        ],
      ),
    );
  }
}
