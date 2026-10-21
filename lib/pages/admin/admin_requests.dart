import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import 'admin_appointment.dart';
import 'admin_widgets.dart';

Color statusColor(RequestStatus s) => switch (s) {
  RequestStatus.nuova => const Color(0xFFC77A12),
  RequestStatus.contattata => const Color(0xFF3B6FB6),
  RequestStatus.sopralluogo => const Color(0xFF8A5BB0),
  RequestStatus.preventivo => const Color(0xFF1F8A8A),
  RequestStatus.acquisita => const Color(0xFF2E7D4F),
  RequestStatus.archiviata => const Color(0xFF7A746B),
};

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});
  final RequestStatus status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: statusColor(status).withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status.label,
      style: TextStyle(
        color: statusColor(status),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    ),
  );
}

class AdminRequests extends StatefulWidget {
  const AdminRequests({super.key});

  @override
  State<AdminRequests> createState() => _AdminRequestsState();
}

class _AdminRequestsState extends State<AdminRequests> {
  RequestStatus? _filter;
  String _search = '';

  bool _matches(ContactRequest q) {
    final k = _search.trim().toLowerCase();
    if (k.isEmpty) return true;
    return [
      q.name,
      q.phone,
      q.email,
      q.city,
      q.type,
      q.projectRef,
    ].any((e) => e.toLowerCase().contains(k));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.requests
        .where((q) => _filter == null || q.status == _filter)
        .where(_matches)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminHeader(
          title: 'Richieste',
          subtitle: 'Chi ha compilato il modulo contatti: richiama, fissa il sopralluogo e segui la trattativa.',
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: const InputDecoration(
              labelText: 'Cerca per nome, telefono, località…',
              prefixIcon: Icon(Icons.search_rounded, size: 20),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text('Tutte (${s.requests.length})'),
              selected: _filter == null,
              onSelected: (_) => setState(() => _filter = null),
            ),
            for (final st in RequestStatus.values)
              ChoiceChip(
                label: Text(
                  '${st.label} (${s.requests.where((q) => q.status == st).length})',
                ),
                selected: _filter == st,
                onSelected: (_) => setState(() => _filter = st),
              ),
          ],
        ),
        const SizedBox(height: 18),
        if (list.isEmpty)
          const Card(
            child: EmptyState(
              icon: Icons.inbox_outlined,
              message: 'Nessuna richiesta qui. Quando un cliente compilerà il modulo contatti la vedrai comparire.',
            ),
          )
        else
          // La chiave lega stato aperto/chiuso e menu "Stato" alla richiesta
          // giusta quando si filtra, si elimina o cambia lo stato.
          for (final q in list) _RequestCard(key: ValueKey(q.id), request: q),
      ],
    );
  }
}

/// Appunti interni sulla richiesta: si salvano quando si esce dal campo.
class _NotesField extends StatefulWidget {
  const _NotesField({required this.request});
  final ContactRequest request;

  @override
  State<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<_NotesField> {
  late final _c = TextEditingController(text: widget.request.notes);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && _c.text != widget.request.notes) _save();
    });
  }

  void _save() {
    widget.request.notes = _c.text;
    context.read<AppState>().updateRequest(widget.request);
    toast(context, 'Appunti salvati.');
  }

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _c,
    focusNode: _focus,
    minLines: 2,
    maxLines: 5,
    decoration: const InputDecoration(
      labelText: 'Appunti interni (non visibili al cliente)',
      alignLabelWithHint: true,
      isDense: true,
    ),
  );
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({super.key, required this.request});
  final ContactRequest request;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final q = request;
    final date = DateFormat(
      "d MMM y 'alle' HH:mm",
      'it_IT',
    ).format(q.createdAt);
    final appt = s.appointments
        .where((a) => a.id == q.appointmentId)
        .firstOrNull;
    final digits = phoneDigits(q.phone);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: q.status == RequestStatus.nuova,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 6,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            title: Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  q.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                  ),
                ),
                StatusPill(q.status),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${q.summary.isEmpty ? '' : '${q.summary} · '}ricevuta il $date',
                style: const TextStyle(color: Colors.black54),
              ),
            ),
            children: [
              Wrap(
                spacing: 24,
                runSpacing: 10,
                children: [
                  for (final (k, v) in [
                    ('Intervento', q.type),
                    ('Località', q.city),
                    ('Superficie', q.area.isEmpty ? '' : '${q.area} m²'),
                    ('Tempi', q.timing),
                    ('Dal progetto', q.projectRef),
                  ])
                    if (v.trim().isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            k.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10.5,
                              letterSpacing: 1.4,
                              color: Colors.black45,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            v,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => openUrl('tel:$digits'),
                    icon: const Icon(Icons.phone_outlined, size: 18),
                    label: Text(q.phone),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        openUrl('https://wa.me/${digits.replaceAll('+', '')}'),
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text('WhatsApp'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => openUrl('mailto:${q.email}'),
                    icon: const Icon(Icons.mail_outline_rounded, size: 18),
                    label: Text(q.email),
                  ),
                ],
              ),
              if (q.message.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text(
                  'Messaggio del cliente',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(q.message),
              ],
              const SizedBox(height: 18),
              _NotesField(request: q),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<RequestStatus>(
                      initialValue: q.status,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Stato',
                        isDense: true,
                      ),
                      items: [
                        for (final st in RequestStatus.values)
                          DropdownMenuItem(value: st, child: Text(st.label)),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        q.status = v;
                        s.updateRequest(q);
                      },
                    ),
                  ),
                  if (appt == null)
                    FilledButton.icon(
                      onPressed: () =>
                          showAppointmentDialog(context, request: q),
                      icon: const Icon(Icons.event_rounded, size: 18),
                      label: const Text('Fissa sopralluogo'),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () => context.go('/admin/calendario'),
                      icon: const Icon(Icons.event_available_rounded, size: 18),
                      label: Text(
                        'Sopralluogo: ${DateFormat('d MMM HH:mm', 'it_IT').format(appt.start)}',
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () async {
                      if (await confirmDialog(
                        context,
                        'Eliminare definitivamente la richiesta di ${q.name}?',
                      )) {
                        s.deleteRequest(q.id);
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFB3382A),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Elimina'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
