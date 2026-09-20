import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/shared_widgets.dart';
import '../theme/app_theme.dart';
import '../session.dart';
import '../models/sede.dart';
import '../models/espacio.dart';
import '../models/reserva.dart';
import 'confirmar_reserva_screen.dart';

const String _apiBaseUrl = "https://https-club-noemi-acosta-backend-onrender.onrender.com";

const _diasSemanaCortos = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];

class HorariosBottomSheet extends StatefulWidget {
  final Sede sede;
  final Espacio espacio;
  // Si viene una reserva acá, el sheet arranca en modo edición: precarga
  // fecha/horario, el botón hace PATCH en vez de crear una reserva nueva,
  // y al guardar devuelve `true` (pop) para que quien lo abrió sepa refrescar.
  final Reserva? reservaAModificar;

  const HorariosBottomSheet({super.key, required this.sede, required this.espacio, this.reservaAModificar});

  @override
  State<HorariosBottomSheet> createState() => _HorariosBottomSheetState();
}

class _HorariosBottomSheetState extends State<HorariosBottomSheet> {
  late List<DateTime> _proximosDias;
  late DateTime _fechaSeleccionada;
  int _duracionHoras = 1;
  int? _horaSeleccionada; // hora de inicio, ej 13 para 13:00

  List<Reserva> _reservasDelDia = [];
  bool _cargandoReservas = true;
  bool _guardandoCambios = false;
  String? _errorGuardado;

  bool get _editando => widget.reservaAModificar != null;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    final reserva = widget.reservaAModificar;

    // En modo edición, la fecha de la reserva puede caer más allá de los
    // próximos 7 días por defecto -- extendemos el rango para incluirla.
    int diasAGenerar = 7;
    if (reserva != null) {
      final diff = reserva.fecha.difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
      if (diff >= diasAGenerar) diasAGenerar = diff + 1;
    }
    _proximosDias = List.generate(diasAGenerar, (i) => DateTime(hoy.year, hoy.month, hoy.day + i));

    if (reserva != null) {
      _fechaSeleccionada = reserva.fecha;
      final horaInicioInt = int.tryParse(reserva.horaInicio.split(':')[0]);
      final horaFinInt = int.tryParse(reserva.horaFin.split(':')[0]);
      if (horaInicioInt != null && horaFinInt != null) {
        final duracionOriginal = horaFinInt - horaInicioInt;
        // Este selector solo ofrece 1 o 2 horas. Si la reserva original dura
        // más, no la preseleccionamos -- mejor que el usuario elija de nuevo
        // a que le cambiemos la duración sin avisar.
        if (duracionOriginal == 1 || duracionOriginal == 2) {
          _duracionHoras = duracionOriginal;
          _horaSeleccionada = horaInicioInt;
        }
      }
    } else {
      _fechaSeleccionada = _proximosDias.first;
    }

    // Si ya precargamos una hora (modo edición), que la primera carga de
    // reservas no la borre de nuevo.
    _cargarReservas(resetearHora: !_editando || _horaSeleccionada == null);
  }

  int get _horaAperturaInt => int.tryParse((widget.espacio.horaApertura ?? '08:00').split(':')[0]) ?? 8;
  int get _horaCierreInt => int.tryParse((widget.espacio.horaCierre ?? '23:00').split(':')[0]) ?? 23;

  Future<void> _cargarReservas({bool resetearHora = true}) async {
    setState(() {
      _cargandoReservas = true;
      if (resetearHora) _horaSeleccionada = null;
    });
    try {
      final fechaStr = _fechaSeleccionada.toIso8601String().split('T').first;
      final response = await http.get(Uri.parse('$_apiBaseUrl/reservas?espacio_id=${widget.espacio.id}&fecha=$fechaStr'), headers: Session.authHeader);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        var reservas = data.map((r) => Reserva.fromJson(r)).toList();
        // En modo edición, la reserva que se está modificando no cuenta
        // como "ocupada" contra sí misma.
        if (widget.reservaAModificar != null) {
          reservas = reservas.where((r) => r.id != widget.reservaAModificar!.id).toList();
        }
        setState(() => _reservasDelDia = reservas);
      }
    } catch (e) {
      // Si falla, mostramos todos los horarios como disponibles antes que romper la pantalla.
      setState(() => _reservasDelDia = []);
    } finally {
      if (mounted) setState(() => _cargandoReservas = false);
    }
  }

  bool _horaLibre(int horaInicio, int duracion) {
    final finPropuesto = horaInicio + duracion;
    for (final r in _reservasDelDia) {
      final inicioR = int.tryParse(r.horaInicio.split(':')[0]) ?? 0;
      final finR = int.tryParse(r.horaFin.split(':')[0]) ?? 0;
      if (horaInicio < finR && inicioR < finPropuesto) return false;
    }
    return true;
  }

  List<int> get _horariosPosibles {
    final lista = <int>[];
    for (int h = _horaAperturaInt; h + _duracionHoras <= _horaCierreInt; h++) {
      lista.add(h);
    }
    return lista;
  }

  List<int> get _horariosDisponibles => _horariosPosibles.where((h) => _horaLibre(h, _duracionHoras)).toList();

  int get _noDisponibles => _horariosPosibles.length - _horariosDisponibles.length;

  double get _total => widget.espacio.precioPorHora * _duracionHoras;

  Future<void> _confirmar() async {
    if (_horaSeleccionada == null) return;

    if (!_editando) {
      Navigator.of(context).pop();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ConfirmarReservaScreen(
          sede: widget.sede,
          espacio: widget.espacio,
          fecha: _fechaSeleccionada,
          horaInicio: _horaSeleccionada!,
          duracionHoras: _duracionHoras,
          total: _total,
        ),
      ));
      return;
    }

    // Modo edición: PATCH directo a la reserva existente, sin pasar por
    // ConfirmarReservaScreen (esa pantalla es solo para reservas nuevas).
    setState(() {
      _guardandoCambios = true;
      _errorGuardado = null;
    });

    final horaFin = _horaSeleccionada! + _duracionHoras;

    try {
      final response = await http.patch(
        Uri.parse('$_apiBaseUrl/reservas/${widget.reservaAModificar!.id}'),
        headers: {'Content-Type': 'application/json', ...Session.authHeader},
        body: jsonEncode({
          'espacio_id': widget.espacio.id,
          'fecha': _fechaSeleccionada.toIso8601String().split('T').first,
          'hora_inicio': '${_horaSeleccionada!.toString().padLeft(2, '0')}:00:00',
          'hora_fin': '${horaFin.toString().padLeft(2, '0')}:00:00',
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.of(context).pop(); // cierra el bottom sheet
        Navigator.of(context).pop(true); // avisa éxito a quien lo abrió
      } else {
        String detail = 'No pudimos modificar la reserva';
        try {
          final data = jsonDecode(response.body);
          detail = data['detail'] ?? detail;
        } catch (_) {}
        setState(() => _errorGuardado = detail);
      }
    } catch (e) {
      if (mounted) setState(() => _errorGuardado = 'Sin conexión con el servidor');
    } finally {
      if (mounted) setState(() => _guardandoCambios = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.bottomSheetBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.surfaceBorder, borderRadius: BorderRadius.circular(2))),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_editando) ...[
                        Text('MODIFICANDO RESERVA', style: TextStyle(color: colors.accentText, fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                      ],
                      Text('FECHA', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 66,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _proximosDias.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final d = _proximosDias[i];
                            final activo = d.year == _fechaSeleccionada.year && d.month == _fechaSeleccionada.month && d.day == _fechaSeleccionada.day;
                            return GestureDetector(
                              onTap: () {
                                setState(() => _fechaSeleccionada = d);
                                _cargarReservas();
                              },
                              child: Container(
                                width: 56,
                                decoration: BoxDecoration(
                                  color: activo ? colors.accent : colors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(_diasSemanaCortos[d.weekday - 1], style: TextStyle(color: activo ? Colors.black54 : colors.textSecondary, fontSize: 10, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text('${d.day}', style: TextStyle(color: activo ? Colors.black : colors.textPrimary, fontSize: 18, fontFamily: 'Inter', fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('DURACIÓN', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _botonDuracion(1, '1 hora', colors)),
                          const SizedBox(width: 10),
                          Expanded(child: _botonDuracion(2, '2 horas', colors)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('HORARIO DISPONIBLE', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                      const SizedBox(height: 10),
                      if (_cargandoReservas)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Center(child: CircularProgressIndicator(color: colors.accent)),
                        )
                      else if (_horariosDisponibles.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text('No quedan horarios libres este día.', style: TextStyle(color: colors.textSecondary, fontFamily: 'Inter')),
                        )
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _horariosDisponibles.map((h) {
                            final activo = h == _horaSeleccionada;
                            final texto = '${h.toString().padLeft(2, '0')}:00 – ${(h + _duracionHoras).toString().padLeft(2, '0')}:00';
                            return GestureDetector(
                              onTap: () => setState(() => _horaSeleccionada = h),
                              child: Container(
                                width: (MediaQuery.of(context).size.width - 20 * 2 - 10) / 2,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: activo ? colors.accent : colors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(texto, style: TextStyle(color: activo ? Colors.black : colors.textPrimary, fontSize: 13, fontFamily: 'Inter', fontWeight: activo ? FontWeight.w800 : FontWeight.w600)),
                              ),
                            );
                          }).toList(),
                        ),
                      if (_noDisponibles > 0) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 14, color: colors.textMuted),
                            const SizedBox(width: 6),
                            Text('Algunos horarios están ocupados · $_noDisponibles no disponibles', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontFamily: 'Inter')),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(14)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(widget.espacio.subcategoria ?? widget.espacio.deporte, style: TextStyle(color: colors.textPrimary, fontSize: 15, fontFamily: 'Inter', fontWeight: FontWeight.w800)),
                                Text('\$ ${widget.espacio.precioPorHora.round()} × $_duracionHoras', style: TextStyle(color: colors.textPrimary, fontSize: 13, fontFamily: 'Inter')),
                              ],
                            ),
                            Text('${widget.espacio.deporte} · ${_duracionHoras}h', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontFamily: 'Inter')),
                            const SizedBox(height: 10),
                            Divider(height: 1, color: colors.surfaceBorder),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Total', style: TextStyle(color: colors.textSecondary, fontSize: 13, fontFamily: 'Inter')),
                                    Text('\$ ${_total.round()}', style: TextStyle(color: colors.textPrimary, fontSize: 28, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900)),
                                  ],
                                ),
                                if (_horaSeleccionada != null)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${_horaSeleccionada!.toString().padLeft(2, '0')}:00 – ${(_horaSeleccionada! + _duracionHoras).toString().padLeft(2, '0')}:00', style: TextStyle(color: colors.accentText, fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w800)),
                                      Text(_formatearFechaCorta(_fechaSeleccionada), style: TextStyle(color: colors.textMuted, fontSize: 12, fontFamily: 'Inter')),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (_errorGuardado != null) ...[
                        const SizedBox(height: 12),
                        Text(_errorGuardado!, style: TextStyle(color: Colors.red[300], fontSize: 13, fontFamily: 'Inter')),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: (_horaSeleccionada != null && !_guardandoCambios) ? _confirmar : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.accent,
                            disabledBackgroundColor: colors.surface,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _guardandoCambios
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : Text(
                                  _horaSeleccionada == null ? 'SELECCIONÁ UN HORARIO' : (_editando ? 'GUARDAR CAMBIOS' : 'CONFIRMAR RESERVA'),
                                  style: TextStyle(color: _horaSeleccionada != null ? Colors.black : colors.textMuted, fontSize: 15, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900, letterSpacing: 1),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _botonDuracion(int horas, String texto, AppColors colors) {
    final activo = horas == _duracionHoras;
    return GestureDetector(
      onTap: () {
        setState(() => _duracionHoras = horas);
        _cargarReservas();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: activo ? colors.accent : colors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(texto, style: TextStyle(color: activo ? Colors.black : colors.textPrimary, fontSize: 14, fontFamily: 'Inter', fontWeight: activo ? FontWeight.w800 : FontWeight.w600)),
      ),
    );
  }

  String _formatearFechaCorta(DateTime f) {
    const dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    const meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${dias[f.weekday - 1]}, ${f.day} ${meses[f.month - 1]}';
  }
}
