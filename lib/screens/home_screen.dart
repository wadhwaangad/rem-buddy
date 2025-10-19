// Copyright (c) 2025 RemBuddy App
// Home screen for displaying unified calendar items and reminders

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;

import '../providers/reminder_provider.dart';
import 'settings_screen.dart';

/// Home screen displaying user's calendar items, reminders, and tasks
/// in a unified timeline view with authentication handling and refresh capability
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const _Header(),
              Expanded(
                child: Consumer<ReminderProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    
                    if (!provider.isAuthenticated) {
                      return const _AuthenticationRequiredState();
                    }
                    
                    return Expanded(
                      child: provider.allCalendarItems.isEmpty
                        ? const _EmptyAllItemsState()
                        : _UnifiedItemsList(provider: provider),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'refresh',
        onPressed: () {
          context.read<ReminderProvider>().fetchReminders();
        },
        child: const Icon(Icons.refresh_rounded),
      ),
    );
  }
}

// ============================================================================
// Helper Widgets
// ============================================================================

/// Authentication required state displayed when user needs to sign in
class _AuthenticationRequiredState extends StatelessWidget {
  const _AuthenticationRequiredState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 80,
            color: Colors.orange,
          ),
          const SizedBox(height: 20),
          Text(
            'Authentication Required',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please restart the app to sign in again',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Unified list showing all calendar items sorted by time
class _UnifiedItemsList extends StatelessWidget {
  final ReminderProvider provider;

  const _UnifiedItemsList({required this.provider});

  @override
  Widget build(BuildContext context) {
    final allItems = _getSortedItems();

    return RefreshIndicator(
      onRefresh: () => provider.fetchReminders(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: allItems.length,
        itemBuilder: (context, index) {
          final item = allItems[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8.0),
            child: _UnifiedItemCard(
              item: item,
              onTap: () => _showItemDetails(context, item),
            ),
          );
        },
      ),
    );
  }

  /// Get all calendar items sorted by time (earliest first)
  List<dynamic> _getSortedItems() {
    final allItems = <dynamic>[];
    allItems.addAll(provider.allCalendarItems);
    
    allItems.sort((a, b) {
      final aTime = _getItemTime(a);
      final bTime = _getItemTime(b);
      return aTime.compareTo(bTime);
    });
    
    return allItems;
  }

  /// Get the time to use for sorting an item (startTime, dueDate, or current time)
  DateTime _getItemTime(dynamic item) {
    if (item.startTime != null) return item.startTime!;
    if (item.dueDate != null) return item.dueDate!;
    return DateTime.now();
  }

  /// Show detailed information about a calendar item in a dialog
  void _showItemDetails(BuildContext context, dynamic item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(
              item.typeIcon,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.description.isNotEmpty) ...[
                const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(item.description),
                const SizedBox(height: 8),
              ],
              const Text('Time:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_formatTimePST(item)),
              const SizedBox(height: 8),
              if (item.location.isNotEmpty) ...[
                const Text('Location:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(item.location),
                const SizedBox(height: 8),
              ],
              const Text('Priority:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${item.priorityIcon} ${item.priority}'),
              const SizedBox(height: 8),
              const Text('Source:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(item.source),
              if (item.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Tags:', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 4,
                  children: item.tags.map((tag) => Chip(
                    label: Text('#$tag'),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTimePST(dynamic item) {
    final pstLocation = tz.getLocation('America/Los_Angeles');
    
    if (item.startTime != null && item.endTime != null) {
      final startTimePST = tz.TZDateTime.from(item.startTime!, pstLocation);
      final endTimePST = tz.TZDateTime.from(item.endTime!, pstLocation);
      
      final startHour = startTimePST.hour.toString().padLeft(2, '0');
      final startMinute = startTimePST.minute.toString().padLeft(2, '0');
      final endHour = endTimePST.hour.toString().padLeft(2, '0');
      final endMinute = endTimePST.minute.toString().padLeft(2, '0');
      
      return '$startHour:$startMinute - $endHour:$endMinute PST';
    } else if (item.dueDate != null) {
      final dueDatePST = tz.TZDateTime.from(item.dueDate!, pstLocation);
      final hour = dueDatePST.hour.toString().padLeft(2, '0');
      final minute = dueDatePST.minute.toString().padLeft(2, '0');
      return 'Due: $hour:$minute PST';
    } else if (item.startTime != null) {
      final startTimePST = tz.TZDateTime.from(item.startTime!, pstLocation);
      final hour = startTimePST.hour.toString().padLeft(2, '0');
      final minute = startTimePST.minute.toString().padLeft(2, '0');
      return '$hour:$minute PST';
    }
    return 'All Day';
  }
}

/// Card widget displaying a calendar item with icon, content, and completion status
class _UnifiedItemCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onTap;

  const _UnifiedItemCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type icon and priority
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Text(
                      item.typeIcon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.priorityIcon,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // Content - flexible to prevent overflow
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: item.isCompleted 
                          ? TextDecoration.lineThrough 
                          : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatTimePST(item),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (item.location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.location,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Status indicator - fixed width
              SizedBox(
                width: 32,
                child: item.isCompleted 
                  ? const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    )
                  : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimePST(dynamic item) {
    final pstLocation = tz.getLocation('America/Los_Angeles');
    
    if (item.startTime != null && item.endTime != null) {
      final startTimePST = tz.TZDateTime.from(item.startTime!, pstLocation);
      final endTimePST = tz.TZDateTime.from(item.endTime!, pstLocation);
      
      final startHour = startTimePST.hour.toString().padLeft(2, '0');
      final startMinute = startTimePST.minute.toString().padLeft(2, '0');
      final endHour = endTimePST.hour.toString().padLeft(2, '0');
      final endMinute = endTimePST.minute.toString().padLeft(2, '0');
      
      return '$startHour:$startMinute - $endHour:$endMinute PST';
    } else if (item.dueDate != null) {
      final dueDatePST = tz.TZDateTime.from(item.dueDate!, pstLocation);
      final hour = dueDatePST.hour.toString().padLeft(2, '0');
      final minute = dueDatePST.minute.toString().padLeft(2, '0');
      return 'Due: $hour:$minute PST';
    } else if (item.startTime != null) {
      final startTimePST = tz.TZDateTime.from(item.startTime!, pstLocation);
      final hour = startTimePST.hour.toString().padLeft(2, '0');
      final minute = startTimePST.minute.toString().padLeft(2, '0');
      return '$hour:$minute PST';
    }
    return 'All Day';
  }
}

/// Empty state displayed when no calendar items are available
class _EmptyAllItemsState extends StatelessWidget {
  const _EmptyAllItemsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_view_day_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'No items yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your events, tasks, and reminders will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Header widget containing app logo, title, and settings button
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    // App Logo
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All Items',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your schedule, tasks, and reminders',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings_rounded),
                iconSize: 28,
              ),
            ],
          ),
        ],
      ),
    );
  }
}