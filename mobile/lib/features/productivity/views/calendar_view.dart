import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_geometry.dart';
import '../../../shared/components/app_card.dart';
import '../productivity_bloc.dart';
import 'event_dialog.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocBuilder<ProductivityBloc, ProductivityState>(
      builder: (context, state) {
        if (state is ProductivityLoading && state is! ProductivityLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is! ProductivityLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final loaded = state;
        final selectedDate = loaded.selectedDate;

        return Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppGeometry.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Calendar', style: AppTypography.h2.copyWith(color: colors.textPrimary)),
                      IconButton(
                        tooltip: 'Add Event',
                        icon: Icon(Icons.add_circle, color: colors.primary, size: 28),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => EventDialog(
                              initialDate: selectedDate,
                              onSave: (ev) => context.read<ProductivityBloc>().add(CreateEventAction(ev)),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Month Navigation & Grid
                  _buildMonthCalendar(loaded, colors),
                  const SizedBox(height: 20),

                  // Selected Day Schedule Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('EEEE, MMM d').format(selectedDate),
                        style: AppTypography.h3.copyWith(color: colors.textPrimary),
                      ),
                      Text(
                        '${loaded.selectedDayEvents.length} event${loaded.selectedDayEvents.length == 1 ? '' : 's'}',
                        style: AppTypography.caption.copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Day's Events List
                  if (loaded.selectedDayEvents.isEmpty)
                    AppCard(
                      backgroundColor: colors.surfaceSoft,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              Icon(Icons.event_note, color: colors.textMuted, size: 36),
                              const SizedBox(height: 8),
                              Text('No events on this day', style: AppTypography.body.copyWith(color: colors.textSecondary)),
                              const SizedBox(height: 4),
                              TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => EventDialog(
                                      initialDate: selectedDate,
                                      onSave: (ev) => context.read<ProductivityBloc>().add(CreateEventAction(ev)),
                                    ),
                                  );
                                },
                                child: const Text('Schedule an Event'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ...loaded.selectedDayEvents.map((ev) => _buildEventCard(context, ev, colors)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthCalendar(ProductivityLoaded state, AppSemanticColors colors) {
    final monthFormat = DateFormat('MMMM yyyy');
    final firstDayOfMonth = _currentMonth;
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(state.selectedDate.year, state.selectedDate.month, state.selectedDate.day);

    // Build event count by day map
    final eventDays = <int, int>{};
    for (final e in state.allEvents) {
      if (e.startTime.year == _currentMonth.year && e.startTime.month == _currentMonth.month) {
        eventDays[e.startTime.day] = (eventDays[e.startTime.day] ?? 0) + 1;
      }
    }

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Month Header with arrows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                color: colors.textPrimary,
                onPressed: _prevMonth,
              ),
              Text(
                monthFormat.format(_currentMonth),
                style: AppTypography.h3.copyWith(color: colors.textPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                color: colors.textPrimary,
                onPressed: _nextMonth,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Day of Week Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) {
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: AppTypography.caption.copyWith(color: colors.textMuted, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42, // 6 weeks * 7 days
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (context, idx) {
              final dayNum = idx - (startWeekday - 2);
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const SizedBox();
              }

              final cellDate = DateTime(_currentMonth.year, _currentMonth.month, dayNum);
              final isToday = cellDate.isAtSameMomentAs(today);
              final isSelected = cellDate.isAtSameMomentAs(selectedDay);
              final hasEvents = (eventDays[dayNum] ?? 0) > 0;

              return InkWell(
                onTap: () {
                  context.read<ProductivityBloc>().add(SelectDateEvent(cellDate));
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primary
                        : (isToday ? colors.primarySoft : Colors.transparent),
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !isSelected ? Border.all(color: colors.primary) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isToday ? colors.primary : colors.textPrimary),
                          fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      if (hasEvents) ...[
                        const SizedBox(height: 2),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : colors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel ev, AppSemanticColors colors) {
    final startFmt = DateFormat('HH:mm').format(ev.startTime);
    final endFmt = DateFormat('HH:mm').format(ev.endTime);

    Color pColor = colors.textSecondary;
    if (ev.priority == 'Urgent') pColor = colors.error;
    if (ev.priority == 'High') pColor = colors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => EventDialog(
              initialEvent: ev,
              onSave: (updated) => context.read<ProductivityBloc>().add(UpdateEventAction(updated)),
            ),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(startFmt, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                Text(endFmt, style: AppTypography.caption.copyWith(color: colors.textMuted)),
              ],
            ),
            const SizedBox(width: 14),
            Container(width: 3, height: 44, color: pColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ev.title,
                          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600, color: colors.textPrimary),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.surfaceSoft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colors.border),
                        ),
                        child: Text(ev.category, style: AppTypography.caption.copyWith(fontSize: 10, color: colors.textSecondary)),
                      ),
                    ],
                  ),
                  if (ev.description != null && ev.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      ev.description!,
                      style: AppTypography.caption.copyWith(color: colors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (ev.location != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: colors.textMuted),
                        const SizedBox(width: 4),
                        Text(ev.location!, style: AppTypography.caption.copyWith(color: colors.textMuted)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: colors.textMuted, size: 20),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Event?'),
                    content: Text('Are you sure you want to delete "${ev.title}"?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.read<ProductivityBloc>().add(DeleteEventAction(ev.id));
                        },
                        child: Text('Delete', style: TextStyle(color: colors.error)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
