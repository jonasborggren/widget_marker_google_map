import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../widget_marker_google_map.dart';

class MarkerGenerator extends StatefulWidget {
  const MarkerGenerator({
    Key? key,
    required this.widgetMarkers,
    required this.onMarkerGenerated,
  }) : super(key: key);
  final List<WidgetMarker> widgetMarkers;
  final ValueChanged<List<Marker>> onMarkerGenerated;

  @override
  _MarkerGeneratorState createState() => _MarkerGeneratorState();
}

class _MarkerGeneratorState extends State<MarkerGenerator> {
  List<GlobalKey> globalKeys = [];
  List<WidgetMarker> lastMarkers = [];
  bool wasError = false;
  late Future<List<Pair<RepaintBoundary, Marker>>> future;

  Future<Pair<RepaintBoundary, Marker>> _convertToMarker(RepaintBoundary boundary, WidgetMarker widgetMarker) async {
    final image = await boundary.createRenderObject(context).toImage(pixelRatio: 2);
    final byteData = await image.toByteData(format: ImageByteFormat.png) ?? ByteData(0);
    final uint8List = byteData.buffer.asUint8List();
    return Pair(
        boundary,
        Marker(
          onTap: widgetMarker.onTap,
          markerId: MarkerId(widgetMarker.markerId),
          position: widgetMarker.position,
          icon: BitmapDescriptor.fromBytes(uint8List),
          draggable: widgetMarker.draggable,
          infoWindow: widgetMarker.infoWindow,
          rotation: widgetMarker.rotation,
          visible: widgetMarker.visible,
          zIndex: widgetMarker.zIndex,
          onDragStart: widgetMarker.onDragStart,
          onDragEnd: widgetMarker.onDragEnd,
          onDrag: widgetMarker.onDrag,
        ));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => onBuildCompleted());
    future = Future.wait(
      widget.widgetMarkers.map(
        (widgetMarker) {
          return _convertToMarker(RepaintBoundary(child: widgetMarker.widget), widgetMarker);
        },
      ),
    );
  }

  Future<void> onBuildCompleted() async {
    /// Skip when there's no change in widgetMarkers.
    if (lastMarkers == widget.widgetMarkers && !wasError) {
      return;
    }
    wasError = false;
    lastMarkers = widget.widgetMarkers;

    // final markers = await Future.wait(globalKeys.map((key) => _convertToMarker(key))).onError((error, stacktrace) {
    //   debugPrint("marker error: $error");
    //   debugPrint("marker error: $stacktrace");
    //   wasError = true;
    //   return [];
    // });
    // widget.onMarkerGenerated.call(markers);
  }

  @override
  Widget build(BuildContext context) {
    globalKeys = [];
    return Transform.translate(
      /// Place markers outside of screens
      /// To hide them in case the map becomes transparent.
      offset: Offset(
        -MediaQuery.of(context).size.width,
        -MediaQuery.of(context).size.height,
      ),
      child: FutureBuilder<List<Pair<RepaintBoundary, Marker>>>(
        future: future,
        builder: (context, snapshot) {
          final pairs = snapshot.data ?? [];
          widget.onMarkerGenerated.call(pairs.map((e) => e.second).toList());
          return Stack(children: pairs.map((e) => e.first).toList());
        },
      ),
    );
  }
}

class Pair<A, B> {
  Pair(this.first, this.second);
  final A first;
  final B second;
}
