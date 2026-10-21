import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import 'admin_widgets.dart';

/// Crea o modifica un appuntamento. Se [request] è indicata, l'appuntamento
/// (di solito il sopralluogo) nasce da quella richiesta e vi resta collegato.
/// Restituisce `true` se qualcosa è cambiato.
Future<bool> showAppointmentDialog(
  BuildContext context, {
  Appointment? existing,
  DateTime? day,
  ContactRequest? request,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (_) =>
        _AppointmentDialog(existing: existing, day: day, request: request),
  );
  return r ?? false;
}

class _AppointmentDialog extends StatefulWidget {
  const _AppointmentDialog({this.existing, this.day, this.request});
  final Appointment? existing;
  final DateTime? day;
  final ContactRequest? request;

  @override
  State<_AppointmentDialog> createState() => _AppointmentDialogState();
}

class _AppointmentDialogState extends State<_AppointmentDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _notes;
  late DateTime _date;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late bool _allDay;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final q = widget.request;
    if (e != null) {
      _title = TextEditingController(text: e.title);
      _location = TextEditingController(text: e.location);
      _notes = TextEditingController(text: e.notes);
      _date = DateTime(e.start.year, e.start.month, e.start.day);
      // Un appuntamento "tutto il giorno" ha orari 00:00–00:00: togliendo
      // l'opzione si parte dagli orari predefiniti invece che da un errore.
      _start = e.allDay
          ? const TimeOfDay(hour: 10, minute: 0)
          : TimeOfDay.fromDateTime(e.start);
      _end = e.allDay
          ? const TimeOfDay(hour: 11, minute: 0)
          : TimeOfDay.fromDateTime(e.end);
      _allDay = e.allDay;
    } else {
      final d = widget.day ?? DateTime.now().add(const Duration(days: 1));
      _date = DateTime(d.year, d.month, d.day);
      _start = const TimeOfDay(hour: 10, minute: 0);
      _end = const TimeOfDay(hour: 11, minute: 0);
      _allDay = false;
      _title = TextEditingController(
        text: q == null
            ? ''
            : 'Sopralluogo ${q.name}${q.type.isEmpty ? '' : ' · ${q.type}'}',
      );
      _location = TextEditingController(text: q?.city ?? '');
      _notes = TextEditingController(
        text: q == null
            ? ''
            : [
                'Tel: ${q.phone}',
                'Email: ${q.email}',
                if (q.type.isNotEmpty) 'Intervento: ${q.type}',
                if (q.area.isNotEmpty) 'Superficie: ${q.area} m²',
                if (q.timing.isNotEmpty) 'Tempi: ${q.timing}',
                if (q.projectRef.isNotEmpty)
                  'Progetto di riferimento: ${q.projectRef}',
                if (q.message.isNotEmpty) 'Note: ${q.message}',
              ].join('\n'),
      );
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  DateTime _at(TimeOfDay t) =>
      DateTime(_date.year, _date.month, _date.day, t.hour, t.minute);

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      // Un evento importato da Google può essere più vecchio del 2020: il
      // calendario non deve fallire (initialDate prima di firstDate).
      firstDate: _date.isBefore(DateTime(2020)) ? _date : DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('it', 'IT'),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initial) => showTimePicker(
    context: context,
    initialTime: initial,
    builder: (ctx, child) => MediaQuery(
      data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
  );

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final s = context.read<AppState>();
    setState(() => _saving = true);
    final a =
        widget.existing ??
        Appointment(title: '', start: DateTime.now(), end: DateTime.now());
    a
      ..title = _title.text.trim()
      ..allDay = _allDay
      ..start = _allDay
          ? DateTime(_date.year, _date.month, _date.day)
          : _at(_start)
      ..end = _allDay ? DateTime(_date.year, _date.month, _date.day) : _at(_end)
      ..location = _location.text.trim()
      ..notes = _notes.text.trim();
    if (widget.existing == null && widget.request != null) {
      a.requestId = widget.request!.id;
    }

    final warning = await s.saveAppointment(a);

    // Un sopralluogo fissato porta avanti la richiesta.
    final q = widget.request;
    if (q != null && widget.existing == null) {
      q.appointmentId = a.id;
      if (q.status == RequestStatus.nuova ||
          q.status == RequestStatus.contattata) {
        q.status = RequestStatus.sopralluogo;
      }
      await s.updateRequest(q);
    }
    if (!mounted) return;
    Navigator.pop(context, true);
    toast(
      context,
      warning ??
          (s.calendar.connected
              ? 'Appuntamento salvato e sincronizzato con Google Calendar.'
              : 'Appuntamento salvato.'),
      error: warning != null,
    );
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(context, 'Eliminare questo appuntamento?');
    if (!ok || !mounted) return;
    final s = context.read<AppState>();
    final warning = await s.deleteAppointment(widget.existing!);
    if (!mounted) return;
    Navigator.pop(context, true);
    toast(
      context,
      warning ?? 'Appuntamento eliminato.',
      error: warning != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEEE d MMMM y', 'it_IT');
    final e = widget.existing;
    final linked = context.read<AppState>().requestById(
      e?.requestId ?? widget.request?.id,
    );
    return AlertDialog(
      title: Text(e == null ? 'Nuovo appuntamento' : 'Modifica appuntamento'),
      content: SizedBox(
        width: dialogWidth(context, 520),
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (linked != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F1EE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.mark_email_unread_outlined, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Collegato alla richiesta di ${linked.name}',
                          ),
                        ),
                      ],
                    ),
                  ),
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Titolo *'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Inserisci un titolo'
                      : null,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data',
                      suffixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                    child: Text(
                      toBeginningOfSentenceCase(fmt.format(_date)) ?? '',
                    ),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tutto il giorno'),
                  value: _allDay,
                  onChanged: (v) => setState(() => _allDay = v),
                ),
                if (!_allDay)
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final t = await _pickTime(_start);
                            if (t != null) {
                              setState(() {
                                final dur =
                                    (_end.hour * 60 + _end.minute) -
                                    (_start.hour * 60 + _start.minute);
                                _start = t;
                                final m =
                                    (t.hour * 60 +
                                            t.minute +
                                            (dur > 0 ? dur : 60))
                                        .clamp(0, 23 * 60 + 59);
                                _end = TimeOfDay(hour: m ~/ 60, minute: m % 60);
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Dalle',
                            ),
                            child: Text(_start.format(context)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final t = await _pickTime(_end);
                            if (t != null) setState(() => _end = t);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Alle',
                            ),
                            child: Text(_end.format(context)),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (!_allDay &&
                    (_end.hour * 60 + _end.minute) <=
                        (_start.hour * 60 + _start.minute))
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      "L'orario di fine deve essere dopo l'inizio.",
                      style: TextStyle(color: Color(0xFFB3382A), fontSize: 13),
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _location,
                  decoration: const InputDecoration(
                    labelText: 'Luogo',
                    prefixIcon: Icon(Icons.place_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notes,
                  minLines: 3,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (e != null)
          TextButton(
            onPressed: _saving ? null : _delete,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFB3382A),
            ),
            child: const Text('Elimina'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed:
              _saving ||
                  (!_allDay &&
                      (_end.hour * 60 + _end.minute) <=
                          (_start.hour * 60 + _start.minute))
              ? null
              : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salva'),
        ),
      ],
    );
  }
}
