import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import 'productivity_bloc.dart';
import 'productivity_repository.dart';
import 'productivity_notification_service.dart';
import 'views/today_view.dart';
import 'views/calendar_view.dart';
import 'views/tasks_view.dart';

class ProductivityContainerView extends StatefulWidget {
  final int initialTabIndex;

  const ProductivityContainerView({super.key, this.initialTabIndex = 0});

  @override
  State<ProductivityContainerView> createState() => _ProductivityContainerViewState();
}

class _ProductivityContainerViewState extends State<ProductivityContainerView> {
  late int _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocProvider(
      create: (ctx) {
        final repo = ProductivityRepository(apiClient: ApiClient());
        final notif = ProductivityNotificationService();
        notif.initialize();
        return ProductivityBloc(repository: repo, notificationService: notif)
          ..add(const LoadProductivityData());
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0,
          titleSpacing: 0,
          toolbarHeight: 52,
          title: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colors.surfaceSoft,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSegment('Today', 0, colors),
                _buildSegment('Calendar', 1, colors),
                _buildSegment('Tasks', 2, colors),
              ],
            ),
          ),
        ),
        body: IndexedStack(
          index: _activeTab,
          children: [
            TodayView(
              onOpenCalendar: () => setState(() => _activeTab = 1),
              onOpenTasks: () => setState(() => _activeTab = 2),
            ),
            const CalendarView(),
            const TasksView(),
          ],
        ),
      ),
    );
  }

  Widget _buildSegment(String title, int index, AppSemanticColors colors) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = index),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : colors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
