import 'package:crop_image/crop_image.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crop Image Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(title: 'Crop Image Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final controller = CropController(
    aspectRatio: 1,
    defaultCrop: Rect.fromLTRB(0.1, 0.1, 0.9, 0.9),
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: CropImage(
              controller: controller,
              image: Image.asset('assets/08272011229.jpg'),
            ),
          ),
        ),
        bottomNavigationBar: _buildButtons(),
      );

  Widget _buildButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              controller.aspectRatio = 1.0;
              controller.crop = Rect.fromLTRB(0.1, 0.1, 0.9, 0.9);
            },
          ),
          IconButton(
            icon: Icon(Icons.aspect_ratio),
            onPressed: _aspectRatios,
          ),
          TextButton(
            onPressed: _finished,
            child: Text('Done'),
          ),
        ],
      );

  Future<void> _aspectRatios() async {
    final value = await showDialog<double>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text('Select aspect ratio'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 1.0),
              child: Text('square'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 2.0),
              child: Text('2:1'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 4.0 / 3.0),
              child: Text('4:3'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 16.0 / 9.0),
              child: Text('16:9'),
            ),
          ],
        );
      },
    );
    if (value != null) {
      controller.aspectRatio = value;
      controller.crop = Rect.fromLTRB(0.1, 0.1, 0.9, 0.9);
    }
  }

  Future<void> _finished() async {
    final image = await controller.croppedImage();
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          contentPadding: EdgeInsets.all(6.0),
          titlePadding: EdgeInsets.all(8.0),
          title: Text('Cropped image'),
          children: [
            Text('relative: ${controller.crop}'),
            Text('pixels: ${controller.cropSize}'),
            SizedBox(height: 5),
            image,
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
