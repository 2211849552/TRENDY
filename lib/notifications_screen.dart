import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/notification_manager.dart';
import 'models/notification_item.dart';
import 'l10n/app_strings.dart';
import 'widgets/app_back_button.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationManager _manager = NotificationManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121026),
      body: SafeArea(
        child: Directionality(
          textDirection: context.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: ListenableBuilder(
            listenable: _manager,
            builder: (context, _) {
              final notifications = _manager.notifications;
              return Column(
                children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildHeader(context),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('notifications'),
                          style: GoogleFonts.cairo(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (notifications.isNotEmpty)
                          TextButton(
                            onPressed: () => _manager.markAllAsRead(),
                            child: Text(
                              context.tr('mark_all_read'),
                              style: GoogleFonts.cairo(color: const Color(0xFF3B82F6), fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: notifications.isEmpty ? _buildEmptyState() : _buildNotificationsList(notifications),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppBackLink(
          label: context.tr('back'),
          onPressed: () => Navigator.pop(context),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFA855F7).withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Text('Trendy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(width: 8),
              Icon(Icons.checkroom_rounded, color: const Color(0xFF3B82F6), size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsList(List<NotificationItem> list) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildNotificationCard(item);
      },
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    return GestureDetector(
      onTap: () {
        _manager.markAsRead(item.id);
        Navigator.pop(context, item);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white.withOpacity(0.03) : const Color(0xFFA855F7).withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: item.isRead ? Colors.white10 : const Color(0xFF3B82F6).withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getIconColor(item.type).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_getIconData(item.type), color: _getIconColor(item.type), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(item.title, style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white54, size: 18),
                        color: const Color(0xFF1E1B4B),
                        onSelected: (value) {
                          if (value == 'toggle') {
                            _manager.toggleRead(item.id);
                          } else if (value == 'delete') {
                            _manager.removeNotification(item.id);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'toggle',
                            child: Text(
                              item.isRead ? context.tr('mark_as_unread') : context.tr('mark_as_read'),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(context.tr('delete_notification')),
                          ),
                        ],
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: const Color(0xFF3B82F6), shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.message, style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13, height: 1.4)),
                  const SizedBox(height: 8),
                  Text(item.formattedTime, style: GoogleFonts.cairo(color: Colors.white30, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(NotificationType type) {
    switch (type) {
      case NotificationType.orderPending: return Icons.access_time_rounded;
      case NotificationType.orderReady: return Icons.check_circle_outline_rounded;
      case NotificationType.orderCompleted: return Icons.shopping_bag_outlined;
      case NotificationType.walletUpdate: return Icons.account_balance_wallet_outlined;
      default: return Icons.notifications_none_rounded;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.orderPending: return Colors.orangeAccent;
      case NotificationType.orderReady: return Colors.greenAccent;
      case NotificationType.orderCompleted: return const Color(0xFF3B82F6);
      case NotificationType.walletUpdate: return Colors.pinkAccent;
      default: return Colors.white54;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
            child: const Icon(Icons.notifications_none_outlined, size: 64, color: Colors.white24),
          ),
          const SizedBox(height: 24),
          Text(context.tr('notifications'), style: GoogleFonts.cairo(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(context.tr('notifications_empty'), style: const TextStyle(fontSize: 14, color: Colors.white30)),
        ],
      ),
    );
  }
}
