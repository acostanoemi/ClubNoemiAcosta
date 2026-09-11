import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/shared_widgets.dart';
import '../models/sede.dart';
import '../models/espacio.dart';
import '../session.dart';

const String _apiBaseUrl = "http://localhost:8000";

const _diasCompletos = ['LUNES', 'MARTES', 'MIÉRCOLES', 'JUEVES', 'VIERNES', 'SÁBADO', 'DOMINGO'];
const _mesesCompletos = ['ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO', 'JULIO', 'AGOSTO', 'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE'];

class ConfirmarReservaScreen extends StatefulWidget {
  final Sede sede;
  final Espacio espacio;
  final DateTime fecha;
  final int horaInicio;
  final int duracionHoras;
  final double total;

  const ConfirmarReservaScreen({
    super.key,
    required this.sede,
    required this.espacio,
    required this.fecha,
    required this.horaInicio,
    required this.duracionHoras,
    required this.total,
  });

  @override
  State<ConfirmarReservaScreen> createState() => _ConfirmarReservaScreenState();
}

class _ConfirmarReservaScreenState extends State<ConfirmarReservaScreen> {
  bool _loading = false;
  bool _confirmada = false;
  String? _error;

  int get _horaFin => widget.horaInicio + widget.duracionHoras;

  Future<void> _confirmarReserva() async {
    if (Session.id == null) {
      setState(() => _error = 'No hay sesión activa. Volvé a loguearte.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final fechaStr = widget.fecha.toIso8601String().split('T').first;
    final horaInicioStr = '${widget.horaInicio.toString().padLeft(2, '0')}:00:00';
    final horaFinStr = '${_horaFin.toString().padLeft(2, '0')}:00:00';

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/reservas'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usuario_id': Session.id,
          'espacio_id': widget.espacio.id,
          'fecha': fechaStr,
          'hora_inicio': horaInicioStr,
          'hora_fin': horaFinStr,
          'monto_total': widget.total,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        setState(() => _confirmada = true);
      } else {
        String detail = 'No pudimos confirmar la reserva.';
        try {
          final data = jsonDecode(response.body);
          detail = data['detail']?.toString() ?? detail;
        } catch (_) {}
        setState(() => _error = detail);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Sin conexión con el servidor');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_confirmada ? '¡Reserva confirmada!' : 'Confirmá tu reserva', style: const TextStyle(color: Colors.black, fontSize: 17, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stepper(),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    Container(
                      height: 90,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF141C0A), Color(0xFF050508)]),
                      ),
                      padding: const EdgeInsets.all(12),
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        'SEDE ${widget.sede.nombre.toUpperCase()}',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900),
                      ),
                    ),
                    _filaResumen('Cancha', (widget.espacio.subcategoria ?? widget.espacio.deporte).toUpperCase()),
                    _filaResumen('Fecha', '${_diasCompletos[widget.fecha.weekday - 1]} ${widget.fecha.day} DE ${_mesesCompletos[widget.fecha.month - 1]}'),
                    _filaResumen('Horario', '${widget.horaInicio.toString().padLeft(2, '0')}:00-${_horaFin.toString().padLeft(2, '0')}:00HS'),
                    _filaResumen('Total', '\$${widget.total.round()}', valorVerde: true, ultima: true),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red[200]!)),
                  child: Text(_error!, style: TextStyle(color: Colors.red[700], fontFamily: 'Inter', fontSize: 13)),
                ),
              ],
              if (_confirmada) ...[
                const Spacer(),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(color: kAccentColor, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.black, size: 36),
                      ),
                      const SizedBox(height: 16),
                      const Text('¡Listo!', style: TextStyle(fontSize: 22, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('Te esperamos en Sede ${widget.sede.nombre}', style: TextStyle(color: Colors.black54, fontFamily: 'Inter', fontSize: 13)),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(backgroundColor: kAccentColor, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('VOLVER', style: TextStyle(color: Colors.black, fontSize: 15, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900)),
                  ),
                ),
              ] else ...[
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _confirmarReserva,
                    style: ElevatedButton.styleFrom(backgroundColor: kAccentColor, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Text('CONFIRMAR RESERVA', style: TextStyle(color: Colors.black, fontSize: 15, fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('Cancelar', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepper() {
    final paso = _confirmada ? 3 : 2;
    return Row(
      children: [
        _circuloPaso(1, paso >= 1, texto: paso > 1 ? null : '1'),
        Expanded(child: Container(height: 2, color: paso >= 2 ? kAccentColor : Colors.black12)),
        _circuloPaso(2, paso >= 2, texto: paso > 2 ? null : '2'),
        Expanded(child: Container(height: 2, color: paso >= 3 ? kAccentColor : Colors.black12)),
        _circuloPaso(3, paso >= 3, texto: '3'),
      ],
    );
  }

  Widget _circuloPaso(int n, bool activo, {String? texto}) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(color: activo ? kAccentColor : Colors.black12, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: texto == null
          ? const Icon(Icons.check, size: 14, color: Colors.black)
          : Text(texto, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: activo ? Colors.black : Colors.black45)),
    );
  }

  Widget _filaResumen(String label, String valor, {bool valorVerde = false, bool ultima = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: ultima ? BorderSide.none : BorderSide(color: Colors.grey[300]!)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.black.withValues(alpha: 0.45), fontSize: 14, fontFamily: 'Inter')),
          Text(valor, style: TextStyle(color: valorVerde ? kAccentColor.withValues(alpha: 1) : Colors.black, fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}