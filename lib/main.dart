import 'package:flutter/material.dart';

void main() {
  runApp(const ControleFinanceiroApp());
}

class ControleFinanceiroApp extends StatelessWidget {
  const ControleFinanceiroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle Financeiro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Controle Financeiro App'),
        ),
      ),
    );
  }
}
