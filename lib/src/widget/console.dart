import 'dart:collection';
import 'dart:io';
import 'dart:ui';
import 'package:fconsole/src/core/fconsole.dart';
import 'package:fconsole/src/core/log.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

part 'console_panel.dart';

part 'console_container.dart';

LinkedHashMap<Object, BuildContext> _contextMap = LinkedHashMap();

bool consoleHasShow = false;

OverlayEntry consoleEntry;

///show console btn
void showConsole({BuildContext context}) {
  if (!consoleHasShow) {
    consoleHasShow = true;
    context ??= _contextMap.values.first;
    _ConsoleTheme _consoleTheme = _ConsoleTheme.of(context);
    Widget consoleBtn = _consoleTheme.consoleBtn ?? _consoleBtn();

    Alignment consolePosition =
        _consoleTheme.consolePosition ?? Alignment.centerRight;

    consoleEntry = OverlayEntry(builder: (ctx) {
      return ConsoleContainer(
        consoleBtn: consoleBtn,
        consolePosition: consolePosition,
      );
    });
    Overlay.of(context).insert(consoleEntry);
  }
}

///hide console btn
void hideConsole({BuildContext context}) {
  if (consoleEntry != null && consoleHasShow) {
    consoleEntry.remove();
    consoleEntry = null;
  }
}

OverlayEntry consolePanelEntry;

///show console panel
showConsolePanel(Function onHideTap, {BuildContext context}) {
  context ??= _contextMap.values.first;

  consolePanelEntry = OverlayEntry(builder: (ctx) {
    return ConsolePanel(() {
      onHideTap?.call();
      hideConsolePanel();
    });
  });
  Overlay.of(context).insert(consolePanelEntry);
}

hideConsolePanel() {
  if (consolePanelEntry != null) {
    consolePanelEntry.remove();
    consolePanelEntry = null;
  }
}

class ConsoleWidget extends StatefulWidget {
  final Widget child;
  final Widget consoleBtn;
  final Alignment consolePosition;

  ConsoleWidget({
    Key key,
    @required this.child,
    this.consolePosition,
    this.consoleBtn,
  }) : super(key: key);

  @override
  _ConsoleWidgetState createState() => _ConsoleWidgetState();
}

class _ConsoleWidgetState extends State<ConsoleWidget> {
  dispose() {
    _contextMap.remove(this);
    FConsole.instance.stopShakeListener();
    super.dispose();
  }

  initState() {
    super.initState();
    if (FConsole.instance.options.displayMode == ConsoleDisplayMode.Shake) {
      FConsole.instance.startShakeListener(() {
        if (mounted) {
          showConsole();
        }
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((d) {
      if (FConsole.instance.options.displayMode == ConsoleDisplayMode.Always) {
        showConsole();
      }
    });
  }

  Widget build(BuildContext context) {
    return _ConsoleTheme(
      consoleBtn: widget.consoleBtn,
      consolePosition: widget.consolePosition,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(initialEntries: [
          OverlayEntry(builder: (ctx) {
            _contextMap[this] = ctx;
            return widget.child;
          })
        ]),
      ),
    );
  }
}

class _ConsoleTheme extends InheritedWidget {
  final Widget consoleBtn;
  final Widget child;
  final Alignment consolePosition;

  _ConsoleTheme({this.child, this.consoleBtn, this.consolePosition})
      : super(child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return true;
  }

  static _ConsoleTheme of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ConsoleTheme>();
}