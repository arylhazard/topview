import 'package:flutter/material.dart';
import 'package:topview/screens/home_page.dart';
import 'package:topview/screens/enhanced_transactions_page.dart';
import 'package:topview/screens/input_page.dart';
import 'package:topview/screens/settings_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const EnhancedTransactionsPage(),
    const InputPage(), // This will be the elevated center button
    const Placeholder(), // Portfolio/Holdings placeholder
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),        child: BottomAppBar(
          height: 60,
          color: theme.bottomNavigationBarTheme.backgroundColor,
          padding: EdgeInsets.zero, // Changed: Remove horizontal padding from BottomAppBar
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              Expanded(child: _buildNavItem(0, Icons.home, 'Home')),
              Expanded(child: _buildNavItem(1, Icons.receipt_long, 'Transactions')),
              const SizedBox(width: 75), // Changed: Adjusted space for floating action button
              Expanded(child: _buildNavItem(3, Icons.pie_chart, 'Portfolio')),
              Expanded(child: _buildNavItem(4, Icons.settings, 'Settings')),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            setState(() {
              _currentIndex = 2;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.add,
            size: 28,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final theme = Theme.of(context);
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 1), // Changed: Minimal horizontal padding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected 
                ? theme.bottomNavigationBarTheme.selectedItemColor
                : theme.bottomNavigationBarTheme.unselectedItemColor,
              size: 22, // Changed: Slightly smaller icon
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: isSelected 
                  ? theme.bottomNavigationBarTheme.selectedItemColor
                  : theme.bottomNavigationBarTheme.unselectedItemColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
