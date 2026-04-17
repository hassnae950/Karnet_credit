import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'models.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // إضافة بعض التصنيفات الافتراضية عند أول تشغيل
  await _addDefaultCategories();
  
  runApp(KarnetApp()); // أزلنا const
}

// إضافة تصنيفات افتراضية
Future<void> _addDefaultCategories() async {
  final categories = await DatabaseHelper.instance.getAllCategories();
  
  if (categories.isEmpty) {
    // تصنيفات للزبائن
    await DatabaseHelper.instance.createCategory(
      Category(name: 'زبائن VIP', type: 'CLIENT'),
    );
    await DatabaseHelper.instance.createCategory(
      Category(name: 'زبائن عاديون', type: 'CLIENT'),
    );
    await DatabaseHelper.instance.createCategory(
      Category(name: 'زبائن جدد', type: 'CLIENT'),
    );
    
    // تصنيفات للموردين
    await DatabaseHelper.instance.createCategory(
      Category(name: 'موردين رئيسيين', type: 'SUPPLIER'),
    );
    await DatabaseHelper.instance.createCategory(
      Category(name: 'موردين ثانويين', type: 'SUPPLIER'),
    );
  }
}

class KarnetApp extends StatelessWidget {
  const KarnetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Karnet Credit',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B8A6B)),
        useMaterial3: true,
        fontFamily: 'Cairo',
      ),
      home: HomeScreen(), // أزلنا const
    );
  }
}