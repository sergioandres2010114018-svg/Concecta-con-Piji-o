import 'package:flutter/material.dart';

import '../services/auth.dart';
import '../theme.dart';

/// Fondo compartido por login y registro: la foto de las letras de PIJIÑO
/// ajustada a toda la pantalla con un degradado para que el formulario se lea.
class FondoPijino extends StatelessWidget {
  final Widget child;
  const FondoPijino({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      Image.asset(
        'assets/img/fondo_login.jpg',
        fit: BoxFit.cover,
        alignment: const Alignment(0, -0.35), // mantiene las letras a la vista
        filterQuality: FilterQuality.medium,
      ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, .35, 1],
            colors: [Color(0x33000000), Color(0x55000000), Color(0xE61B1712)],
          ),
        ),
      ),
      SafeArea(child: child),
    ]);
  }
}

InputDecoration _campo(String label, IconData icono, {Widget? sufijo}) =>
    InputDecoration(
      labelText: label,
      prefixIcon: Icon(icono),
      suffixIcon: sufijo,
      filled: true,
      fillColor: Colors.white.withOpacity(.94),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    );

String? validarCorreo(String? v) {
  if (v == null || v.trim().isEmpty) return 'Escribe tu correo';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
    return 'Correo no válido';
  }
  return null;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  bool _ver = false;
  bool _cargando = false;
  String? _error;

  Future<void> _ingresar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await Auth.instancia.ingresar(_correo.text, _clave.text);
    } on ErrorAuth catch (e) {
      setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _recuperar() async {
    if (validarCorreo(_correo.text) != null) {
      setState(() => _error = 'Escribe tu correo arriba para recuperar la contraseña.');
      return;
    }
    try {
      await Auth.instancia.recuperarClave(_correo.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Te enviamos un correo para cambiar la contraseña.')));
    } on ErrorAuth catch (e) {
      setState(() => _error = e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FondoPijino(
        child: LayoutBuilder(
          builder: (_, c) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight - 48),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset('assets/img/logo_crop.jpg',
                            width: 72, height: 78, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Conecta con Pijiño',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(color: Colors.white)),
                    const Text('El corazón de Pijiño en cada atarraya',
                        style: TextStyle(
                            color: Color(0xFFFBD3A8),
                            fontStyle: FontStyle.italic)),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _correo,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      validator: validarCorreo,
                      decoration: _campo('Correo', Icons.mail_outline),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _clave,
                      obscureText: !_ver,
                      autofillHints: const [AutofillHints.password],
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Escribe tu contraseña' : null,
                      onFieldSubmitted: (_) => _ingresar(),
                      decoration: _campo(
                        'Contraseña',
                        Icons.lock_outline,
                        sufijo: IconButton(
                          tooltip: _ver ? 'Ocultar' : 'Mostrar',
                          icon: Icon(_ver ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _ver = !_ver),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _recuperar,
                        child: const Text('¿Olvidaste tu contraseña?',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    if (_error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFCE8DC),
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(_error!,
                            style: const TextStyle(color: Color(0xFF8A3A10))),
                      ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: Paleta.atardecer,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      onPressed: _cargando ? null : _ingresar,
                      child: _cargando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Iniciar sesión',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const RegistroScreen())),
                      child: const Text('Crear cuenta',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    TextButton(
                      onPressed: Auth.instancia.entrarComoInvitado,
                      child: const Text('Entrar como invitado',
                          style: TextStyle(color: Colors.white70)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _tel = TextEditingController();
  final _clave = TextEditingController();
  final _clave2 = TextEditingController();
  String _perfil = 'Habitante de Pijiño';
  bool _acepta = false;
  bool _cargando = false;
  String? _error;

  static const perfiles = [
    'Habitante de Pijiño',
    'Pijiñero que vive fuera',
    'Visitante / turista',
    'Estudiante o docente',
    'Comerciante o emprendedor',
    'Gestor cultural',
  ];

  Future<void> _registrar() async {
    if (!_form.currentState!.validate()) return;
    if (!_acepta) {
      setState(() => _error = 'Debes aceptar el tratamiento de datos.');
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await Auth.instancia.registrar(
        nombre: _nombre.text,
        correo: _correo.text,
        telefono: _tel.text,
        perfil: _perfil,
        clave: _clave.text,
      );
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on ErrorAuth catch (e) {
      setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Crear cuenta'),
      ),
      body: FondoPijino(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 140, 24, 24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nombre,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Escribe tu nombre completo'
                      : null,
                  decoration: _campo('Nombre completo', Icons.person_outline),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _correo,
                  keyboardType: TextInputType.emailAddress,
                  validator: validarCorreo,
                  decoration: _campo('Correo', Icons.mail_outline),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tel,
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null ||
                          !RegExp(r'^3\d{9}$').hasMatch(v.replaceAll(' ', '')))
                      ? 'Celular de 10 dígitos (ej. 3001234567)'
                      : null,
                  decoration: _campo('Celular', Icons.phone_outlined),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _perfil,
                  decoration: _campo('¿Quién eres?', Icons.groups_outlined),
                  items: perfiles
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _perfil = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _clave,
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Mínimo 6 caracteres'
                      : null,
                  decoration: _campo('Contraseña', Icons.lock_outline),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _clave2,
                  obscureText: true,
                  validator: (v) =>
                      v != _clave.text ? 'Las contraseñas no coinciden' : null,
                  decoration: _campo('Repite la contraseña', Icons.lock_outline),
                ),
                CheckboxListTile(
                  value: _acepta,
                  onChanged: (v) => setState(() => _acepta = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  checkColor: Colors.white,
                  activeColor: Paleta.atardecer,
                  title: const Text(
                    'Autorizo el tratamiento de mis datos personales para fines del proyecto (Ley 1581 de 2012).',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFCE8DC),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(_error!,
                        style: const TextStyle(color: Color(0xFF8A3A10))),
                  ),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: Paleta.atardecer,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  onPressed: _cargando ? null : _registrar,
                  child: Text(_cargando ? 'Creando cuenta…' : 'Registrarme',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
