import 'package:flutter/material.dart';
import 'clients_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // AppBar مع تبويبات
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1B8A6B),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // العنوان
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Icon(Icons.menu_book_rounded, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          'كارنيه',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // تبويبات
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    tabs: const [
                      Tab(text: 'الزبائن'),
                      Tab(text: 'الموردين'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // محتوى التبويبات
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ClientsScreen(type: 'CLIENT'),
                ClientsScreen(type: 'SUPPLIER'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}