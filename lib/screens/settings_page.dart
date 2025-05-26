import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:provider/provider.dart';
import 'package:topview/providers/portfolio_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adaptiveThemeManager = AdaptiveTheme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Theme Settings Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                    // Theme Mode Selector
                  _buildThemeSelector(adaptiveThemeManager, theme),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Data Management Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Management',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Refresh Data
                  ListTile(
                    leading: Icon(
                      Icons.refresh,
                      color: theme.colorScheme.primary,
                    ),
                    title: const Text('Refresh Data'),
                    subtitle: const Text('Re-scan SMS messages and update portfolio'),
                    onTap: () {
                      _refreshData(context);
                    },
                  ),
                  
                  const Divider(),
                  
                  // Clear All Data
                  ListTile(
                    leading: const Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                    ),
                    title: const Text('Clear All Data'),
                    subtitle: const Text('Remove all transactions and portfolio data'),
                    onTap: () {
                      _showClearDataDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // App Information Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ListTile(
                    leading: Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                    ),
                    title: const Text('TopView Portfolio Tracker'),
                    subtitle: const Text('Version 1.0.0'),
                  ),
                  
                  ListTile(
                    leading: Icon(
                      Icons.description,
                      color: theme.colorScheme.primary,
                    ),
                    title: const Text('About'),
                    subtitle: const Text('Track your stock portfolio using SMS messages'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildThemeSelector(AdaptiveThemeManager<ThemeData> adaptiveThemeManager, ThemeData theme) {
    return Column(
      children: [
        _buildThemeOption(
          'Light Mode',
          Icons.light_mode,
          adaptiveThemeManager.mode == AdaptiveThemeMode.light,
          () => adaptiveThemeManager.setLight(),
          theme,
        ),
        const SizedBox(height: 8),
        _buildThemeOption(
          'Dark Mode',
          Icons.dark_mode,
          adaptiveThemeManager.mode == AdaptiveThemeMode.dark,
          () => adaptiveThemeManager.setDark(),
          theme,
        ),
        const SizedBox(height: 8),
        _buildThemeOption(
          'System Default',
          Icons.settings_system_daydream,
          adaptiveThemeManager.mode == AdaptiveThemeMode.system,
          () => adaptiveThemeManager.setSystem(),
          theme,
        ),
      ],
    );
  }

  Widget _buildThemeOption(
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return Container(      decoration: BoxDecoration(
        color: isSelected 
          ? theme.colorScheme.primary.withValues(alpha: 0.1)
          : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected 
            ? theme.colorScheme.primary
            : theme.dividerColor,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected 
            ? theme.colorScheme.primary
            : theme.iconTheme.color,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected 
              ? theme.colorScheme.primary
              : theme.textTheme.bodyMedium?.color,
          ),
        ),
        trailing: isSelected 
          ? Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
            )
          : null,
        onTap: onTap,
      ),
    );
  }

  Future<void> _refreshData(BuildContext context) async {
    final provider = Provider.of<PortfolioProvider>(context, listen: false);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Refreshing data...'),
          ],
        ),
      ),
    );
    
    try {
      await provider.fetchSmsMessages();
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data refreshed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your portfolio data including transactions, holdings, and client information. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _clearAllData(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData(BuildContext context) async {
    final provider = Provider.of<PortfolioProvider>(context, listen: false);
    
    try {
      await provider.clearData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
