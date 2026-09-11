import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/shared_widgets.dart';
import '../models/sede.dart';
import '../models/espacio.dart';
import '../models/reserva.dart';
import 'confirmar_reserva_screen.dart';

const String _apiBaseUrl = "http://localhost:8000";

const _diasSemanaCortos = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];

class HorariosBottomSheet extends StatefulWidget {
  final Sede sede;
  final Espacio espacio;

  const HorariosBottomSheet({super.key, required this.sede, required this.espacio});

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

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _proximosDias = List.generate(7, (i) => DateTime(hoy.year, hoy.month, hoy.day + i));
    _fechaSeleccionada = _proximosDias.first;
    _cargarReservas();
  }

  int get _horaAperturaInt => int.tryParse((widget.espacio.horaApertura ?? '08:00').split(':')[0]) ?? 8;
  int get _horaCierreInt => int.tryParse((widget.espacio.horaCierre ?? '23:00').split(':')[0]) ?? 23;

  Future<void> _cargarReservas() async {
    setState(() {
      _cargandoReservas = true;
      _horaSeleccionada = null;
    });
    try {
      final fechaStr = _fechaSeleccionada.toIso8601String().split('T').first;
      final response = await http.get(Uri.parse('$_apiBaseUrl/reservas?espacio_id=${widget.espacio.id}&fecha=$fechaStr'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() => _reservasDelDia = data.map((r) => Reserva.fromJson(r)).toList());
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

  void _confirmar() {
    if (_horaSeleccionada == null) return;
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
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('FECHA', style: TextStyle(color: Colors.black45, fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w700, letterSpacing: 1.2)),
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
                                  color: activo ? kAccentColor : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(_diasSemanaCortos[d.weekday - 1], style: const TextStyle(color: Colors.black54, fontSize: 10, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text('${d.day}', style: const TextStyle(color: Colors.black, fontSize: 18, fontFamily: 'Inter', fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('DURACIÓN', style: TextStyle(color: Colors.black45, fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _botonDuracion(1, '1 hora')),
                          const SizedBox(width: 10),
                          Expanded(child: _botonDuracion(2, '2 horas')),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('HORARIO DISPONIBLE', style: TextStyle(color: Colors.black45, fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                      const SizedBox(height: 10),
                      if (_cargandoReservas)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: Center(child: CircularProgressIndicator(color: kAccentColor)),
                        )
                      else if (_horariosDisponibles.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text('No quedan horarios libres este día.', style: TextStyle(color: Colors.black54, fontFamily: 'Inter')),
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
                                  color: activo ? kAccentColor : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(texto, style: TextStyle(color: Colors.black, fontSize: 13, fontFamily: 'Inter', fontWeight: activo ? FontWeight.w800 : FontWeight.w600)),
                              ),
                            );
                          }).toList(),
                        ),
                      if (_noDisponibles > 0) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 14, color: Colors.black38),
                            const SizedBox(width: 6),
                            Text('Algunos horarios están ocupados · $_noDisponibles no disponibles', style: const TextStyle(color: Colors.black45, fontSize: 12, fontFamily: 'Inter')),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(widget.espacio.subcategoria ?? widget.espacio.deporte, style: const TextStyle(color: Colors.black, fontSize: 15, fontFamily: 'Inter', fontWeight: FontWeight.w800)),
                                Text('\$ ${widget.espacio.precioPorHora.round()} × $_duracionHoras', style: const TextStyle(color: Colors.black87, fontSize: 13, fontFamily: 'Inter')),
                              ],
                            ),
                            Text('${widget.espacio.deporte} · ${_duracionHoras}h', style: TextStyle(color: Colors.black.withValues(alpha: 0.45), fontSize: 12, fontFamily: 'Inter')),
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Total', style: TextStyle(color: Colors.black.withValues(alpha: 0.45), fontSize: 13, fontFamily: 'Inter')),
                                    Text('\$ ${_total.round()}', style: const TextStyle(color: Colors.black, fontSize: 28, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900)),
                                  ],
                                ),
                                if (_horaSeleccionada != null)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${_horaSeleccionada!.toString().padLeft(2, '0')}:00 – ${(_horaSeleccionada! + _duracionHoras).toString().padLeft(2, '0')}:00', style: const TextStyle(color: kAccentColor, fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w800)),
                                      Text(_formatearFechaCorta(_fechaSeleccionada), style: TextStyle(color: Colors.black.withValues(alpha: 0.40), fontSize: 12, fontFamily: 'Inter')),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _horaSeleccionada != null ? _confirmar : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kAccentColor,
                            disabledBackgroundColor: Colors.grey[300],
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            _horaSeleccionada != null ? 'CONFIRMAR RESERVA' : 'SELECCIONÁ UN HORARIO',
                            style: TextStyle(color: _horaSeleccionada != null ? Colors.black : Colors.black38, fontSize: 15, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900, letterSpacing: 1),
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

  Widget _botonDuracion(int horas, String texto) {
    final activo = horas == _duracionHoras;
    return GestureDetector(
      onTap: () {
        setState(() => _duracionHoras = horas);
        _cargarReservas();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: activo ? kAccentColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(texto, style: TextStyle(color: Colors.black, fontSize: 14, fontFamily: 'Inter', fontWeight: activo ? FontWeight.w800 : FontWeight.w600)),
      ),
    );
  }

  String _formatearFechaCorta(DateTime f) {
    const dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    const meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${dias[f.weekday - 1]}, ${f.day} ${meses[f.month - 1]}';
  }
}