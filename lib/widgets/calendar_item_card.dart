import 'package:flutter/material.dart';
import '../models/calendar_item.dart';

class CalendarItemCard extends StatelessWidget {
  final CalendarItem item;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;

  const CalendarItemCard({
    Key? key,
    required this.item,
    this.onTap,
    this.onComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: _getGradientForType(),
            border: item.priority == 'high' 
                ? Border.all(color: Colors.red, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with type icon, title, and priority
              Row(
                children: [
                  Text(
                    item.typeIcon,
                    style: TextStyle(fontSize: 20),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        decoration: item.isCompleted 
                            ? TextDecoration.lineThrough 
                            : null,
                      ),
                    ),
                  ),
                  Text(
                    item.priorityIcon,
                    style: TextStyle(fontSize: 16),
                  ),
                  if (item.type == CalendarItemType.task && !item.isCompleted)
                    IconButton(
                      icon: Icon(Icons.check_circle_outline, color: Colors.white),
                      onPressed: onComplete,
                      tooltip: 'Mark as complete',
                    ),
                ],
              ),
              
              // Time/Due date
              if (item.displayTime.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(left: 28, top: 4),
                  child: Text(
                    item.displayTime,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              // Location
              if (item.location.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(left: 28, top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.white70),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Description
              if (item.description.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(left: 28, top: 8),
                  child: Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // Tags
              if (item.tags.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(left: 28, top: 8),
                  child: Wrap(
                    spacing: 4,
                    children: item.tags.map((tag) => Chip(
                      label: Text(
                        '#$tag',
                        style: TextStyle(fontSize: 10),
                      ),
                      backgroundColor: Colors.white.withOpacity(0.2),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                ),

              // Source indicator
              Padding(
                padding: EdgeInsets.only(left: 28, top: 8),
                child: Row(
                  children: [
                    Icon(
                      _getSourceIcon(),
                      size: 12,
                      color: Colors.white60,
                    ),
                    SizedBox(width: 4),
                    Text(
                      _getSourceLabel(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white60,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient _getGradientForType() {
    switch (item.type) {
      case CalendarItemType.event:
        return LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case CalendarItemType.task:
        return LinearGradient(
          colors: item.isCompleted 
              ? [Colors.green.shade600, Colors.green.shade800]
              : [Colors.orange.shade600, Colors.orange.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case CalendarItemType.reminder:
        return LinearGradient(
          colors: [Colors.purple.shade600, Colors.purple.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case CalendarItemType.note:
        return LinearGradient(
          colors: [Colors.teal.shade600, Colors.teal.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  IconData _getSourceIcon() {
    switch (item.source) {
      case 'google_calendar':
        return Icons.calendar_today;
      case 'google_tasks':
        return Icons.task_alt;
      case 'google_calendar_reminders':
        return Icons.notification_important;
      default:
        return Icons.sync;
    }
  }

  String _getSourceLabel() {
    switch (item.source) {
      case 'google_calendar':
        return 'Google Calendar';
      case 'google_tasks':
        return 'Google Tasks';
      case 'google_calendar_reminders':
        return 'Calendar Reminders';
      default:
        return item.source;
    }
  }
}