import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import 'admin_requests.dart' show StatusPill;
import 'admin_widgets.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final now = DateTime.now();
    // Gli appuntamenti "tutto il giorno" finiscono a mezzanotte del giorno
    // stesso: restano "prossimi" fino alla fine della giornata.
    final upcoming =
        s.appointments
            .where(
              (a) =>
                  (a.allDay
                          ? DateTime(a.end.year, a.end.month, a.end.day + 1)
                          : a.end)
                      .isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    final newRequests = s.newRequests;
    final open = s.projects
        .where((p) => p.status == ProjectStatus.inCorso)
        .length;
    final wide = MediaQuery.sizeOf(context).width > 980;

    final stats = [
      _Stat(
        'Richieste nuove',
        '$newRequests',
        Icons.mark_email_unread_outlined,
        newRequests > 0 ? const Color(0xFFC77A12) : null,
        () => context.go('/admin/richieste'),
      ),
      _Stat(
        'Prossimi appuntamenti',
        '${upcoming.length}',
        Icons.event_outlined,
        null,
        () => context.go('/admin/calendario'),
      ),
      _Stat(
        'Progetti pubblicati',
        '${s.publishedProjects.length}',
        Icons.apartment_outlined,
        null,
        () => context.go('/admin/progetti'),
      ),
      _Stat(
        'Cantieri in corso',
        '$open',
        Icons.construction_outlined,
        null,
        () => context.go('/admin/progetti'),
      ),
    ];

    final recent = Panel(
      title: 'Ultime richieste',
      trailing: TextButton(
        onPressed: () => context.go('/admin/richieste'),
        child: const Text('Vedi tutte'),
      ),
      child: s.requests.isEmpty
          ? const EmptyState(
              icon: Icons.inbox_outlined,
              message: 'Ancora nessuna richiesta dal sito.',
            )
          : Column(
              children: [
                for (final q in s.requests.take(5))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => context.go('/admin/richieste'),
                    title: Text(
                      q.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${q.summary.isEmpty ? 'Richiesta' : q.summary} · ${DateFormat('d MMM', 'it_IT').format(q.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: StatusPill(q.status),
                  ),
              ],
            ),
    );

    final next = Panel(
      title: 'Prossimi appuntamenti',
      trailing: TextButton(
        onPressed: () => context.go('/admin/calendario'),
        child: const Text('Apri calendario'),
      ),
      child: upcoming.isEmpty
          ? const EmptyState(
              icon: Icons.event_available_outlined,
              message: 'Nessun appuntamento in programma.',
            )
          : Column(
              children: [
                for (final a in upcoming.take(5))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => context.go('/admin/calendario'),
                    leading: Container(
                      width: 48,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary
                            .withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('d', 'it_IT').format(a.start),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            DateFormat(
                              'MMM',
                              'it_IT',
                            ).format(a.start).toUpperCase(),
                            style: const TextStyle(fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                    title: Text(
                      a.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      a.allDay
                          ? 'Tutto il giorno'
                          : DateFormat.Hm().format(a.start),
                    ),
                  ),
              ],
            ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminHeader(
          title: 'Bentornato',
          subtitle: 'La situazione di oggi.',
        ),
        LayoutBuilder(
          builder: (context, box) {
            final cols = box.maxWidth > 900 ? 4 : 2;
            const gap = 16.0;
            final w = (box.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [for (final st in stats) SizedBox(width: w, child: st)],
            );
          },
        ),
        const SizedBox(height: 22),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: recent),
              const SizedBox(width: 20),
              Expanded(child: next),
            ],
          )
        else ...[
          recent,
          const SizedBox(height: 20),
          next,
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon, this.highlight, this.onTap);
  final String label;
  final String value;
  final IconData icon;
  final Color? highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = highlight ?? Theme.of(context).colorScheme.primary;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: c),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
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
}
