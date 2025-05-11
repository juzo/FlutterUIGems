import 'package:flutter/material.dart';
import 'package:shockwave_demo/widgets/shockwave_grid.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Shockwave Animation Demo',
      home: Scaffold(
        body: Center(child: ShockwaveGrid()),
      ),
    );
  }
}
