import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/reminder_item.dart';

class ReminderCard extends StatelessWidget {
  final ReminderItem reminder;
  final VoidCallback onToggle;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final timeUntil = reminder.eventTime.difference(DateTime.now());
    final isToday = timeUntil.inHours < 24;
    final categoryIcon = _getCategoryIcon(reminder.category);
    final categoryColor = _getCategoryColor(reminder.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: reminder.isCompleted
              ? Colors.green.withOpacity(0.5)
              : categoryColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Category Icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: FaIcon(
                          categoryIcon,
                          color: categoryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Event Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reminder.eventTitle,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                decoration: reminder.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 16,
                                  color: isToday ? Colors.orange : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatEventTime(reminder.eventTime),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isToday ? Colors.orange : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Completion Indicator
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: reminder.isCompleted
                              ? Colors.green.withOpacity(0.2)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: reminder.isCompleted
                                ? Colors.green
                                : Colors.grey.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.check,
                          color: reminder.isCompleted
                              ? Colors.green
                              : Colors.transparent,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  
                  if (reminder.eventDescription.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      reminder.eventDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Divider
                  Container(
                    height: 1,
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Items to Remember
                  Row(
                    children: [
                      Icon(
                        Icons.checklist_rounded,
                        color: categoryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Don\'t forget:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: categoryColor,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: reminder.itemsToRemember.map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: categoryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getItemIcon(item),
                              size: 16,
                              color: categoryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item,
                              style: TextStyle(
                                color: categoryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate(target: reminder.isCompleted ? 1 : 0)
      .scale(duration: 300.ms, curve: Curves.easeOut);
  }

  String _formatEventTime(DateTime dateTime) {
    // Convert to PST timezone
    final pstLocation = tz.getLocation('America/Los_Angeles');
    final dateTimePST = tz.TZDateTime.from(dateTime, pstLocation);
    
    final now = DateTime.now();
    final nowPST = tz.TZDateTime.from(now, pstLocation);
    final difference = dateTimePST.difference(nowPST);

    if (difference.inDays == 0) {
      return 'Today at ${DateFormat('h:mm a').format(dateTimePST)} PST';
    } else if (difference.inDays == 1) {
      return 'Tomorrow at ${DateFormat('h:mm a').format(dateTimePST)} PST';
    } else if (difference.inDays < 7) {
      return '${DateFormat('EEEE').format(dateTimePST)} at ${DateFormat('h:mm a').format(dateTimePST)} PST';
    } else {
      return '${DateFormat('MMM d, h:mm a').format(dateTimePST)} PST';
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'shopping':
        return FontAwesomeIcons.cartShopping;
      case 'fitness':
        return FontAwesomeIcons.dumbbell;
      case 'work':
        return FontAwesomeIcons.briefcase;
      case 'health':
        return FontAwesomeIcons.heartPulse;
      case 'travel':
        return FontAwesomeIcons.plane;
      case 'dining':
        return FontAwesomeIcons.utensils;
      default:
        return FontAwesomeIcons.calendar;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'shopping':
        return const Color(0xFF10B981); // Green
      case 'fitness':
        return const Color(0xFFEF4444); // Red
      case 'work':
        return const Color(0xFF3B82F6); // Blue
      case 'health':
        return const Color(0xFFEC4899); // Pink
      case 'travel':
        return const Color(0xFF8B5CF6); // Purple
      case 'dining':
        return const Color(0xFFF59E0B); // Orange
      default:
        return const Color(0xFF6366F1); // Indigo
    }
  }

  IconData _getItemIcon(String item) {
    final lowerItem = item.toLowerCase();
    
    if (lowerItem.contains('wallet') || lowerItem.contains('money')) {
      return FontAwesomeIcons.wallet;
    } else if (lowerItem.contains('phone')) {
      return FontAwesomeIcons.mobileScreen;
    } else if (lowerItem.contains('key')) {
      return FontAwesomeIcons.key;
    } else if (lowerItem.contains('laptop') || lowerItem.contains('computer')) {
      return FontAwesomeIcons.laptop;
    } else if (lowerItem.contains('water') || lowerItem.contains('bottle')) {
      return FontAwesomeIcons.bottleWater;
    } else if (lowerItem.contains('bag') || lowerItem.contains('backpack')) {
      return FontAwesomeIcons.bagShopping;
    } else if (lowerItem.contains('charger')) {
      return FontAwesomeIcons.plug;
    } else if (lowerItem.contains('id') || lowerItem.contains('card')) {
      return FontAwesomeIcons.idCard;
    } else if (lowerItem.contains('passport')) {
      return FontAwesomeIcons.passport;
    } else if (lowerItem.contains('ticket')) {
      return FontAwesomeIcons.ticket;
    } else {
      return FontAwesomeIcons.circleCheck;
    }
  }
}
