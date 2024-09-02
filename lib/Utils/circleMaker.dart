import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/animation.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


Future<BitmapDescriptor> CircleMaker(String assetPath, int number, {required int width, required int height}) async {

    ByteData data = await rootBundle.load(assetPath);
    Codec codec = await instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width, targetHeight: height);
    FrameInfo fi = await codec.getNextFrame();
    final Uint8List imageData = (await fi.image.toByteData(format: ImageByteFormat.png))!.buffer.asUint8List();

    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    Size canvasSize = Size(width.toDouble(), height.toDouble());
    paintImage(canvas: canvas, image: (await decodeImageFromList(imageData)), rect: Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height));


    TextPainter textPainter = TextPainter(
        textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: '$number',
      style: TextStyle(fontSize: width * 0.55, color: Colors.white, fontWeight: FontWeight.w500),
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset(width / 2 - textPainter.width / 2, height / 2 - textPainter.height / 2 ));

    ByteData? byteData = await (await pictureRecorder.endRecording().toImage(width, height)).toByteData(format: ImageByteFormat.png);

    Uint8List datass = Uint8List.view(byteData!.buffer);
    return BitmapDescriptor.fromBytes(datass);

}

Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    Codec codec = await instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ImageByteFormat.png))!.buffer.asUint8List();
}