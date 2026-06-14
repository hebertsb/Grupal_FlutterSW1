import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../nucleo/constantes/colores.dart';
import '../../nucleo/proveedores/auth_proveedor.dart';

class PantallaLogin extends ConsumerStatefulWidget {
  const PantallaLogin({super.key});

  @override
  ConsumerState<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends ConsumerState<PantallaLogin>
    with SingleTickerProviderStateMixin {
  // Modo actual
  bool _enRegistro = false;

  // Controladores login
  final _loginForm     = GlobalKey<FormState>();
  final _loginEmail    = TextEditingController();
  final _loginPassword = TextEditingController();

  // Controladores registro
  final _regForm     = GlobalKey<FormState>();
  final _regNombre   = TextEditingController();
  final _regEmail    = TextEditingController();
  final _regPassword = TextEditingController();

  late final AnimationController _anim;
  late final Animation<Offset> _slideEntrada;
  late final Animation<Offset> _slideSalida;
  late final Animation<double> _fadeEntrada;
  late final Animation<double> _fadeSalida;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));

    _slideSalida  = Tween<Offset>(begin: Offset.zero, end: const Offset(-1, 0))
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
    _slideEntrada = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
    _fadeSalida   = Tween<double>(begin: 1, end: 0)
        .animate(CurvedAnimation(parent: _anim, curve: const Interval(0, .5)));
    _fadeEntrada  = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _anim, curve: const Interval(.5, 1)));
  }

  @override
  void dispose() {
    _anim.dispose();
    _loginEmail.dispose(); _loginPassword.dispose();
    _regNombre.dispose();  _regEmail.dispose(); _regPassword.dispose();
    super.dispose();
  }

  void _irARegistro() {
    setState(() => _enRegistro = true);
    _anim.forward();
    ref.read(authProvider.notifier).limpiarError();
  }

  void _irALogin() {
    setState(() => _enRegistro = false);
    _anim.reverse();
    ref.read(authProvider.notifier).limpiarError();
  }

  Future<void> _enviarLogin() async {
    if (!_loginForm.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).iniciarSesion(
      _loginEmail.text.trim(),
      _loginPassword.text,
    );
    if (ok && mounted) {
      final usuario = ref.read(authProvider).usuario;
      context.go(usuario?.esAdmin == true ? '/dashboard' : '/camaras');
    }
  }

  Future<void> _enviarRegistro() async {
    if (!_regForm.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).registrarGuardia(
      nombre:   _regNombre.text.trim(),
      email:    _regEmail.text.trim(),
      password: _regPassword.text,
    );
    if (ok && mounted) {
      context.go('/camaras');
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: kFondoOscuro,
      body: Stack(
        children: [
          // Gradiente decorativo de fondo
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF020c1b), Color(0xFF0a1e42), Color(0xFF020c1b)],
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo + título (siempre visible)
                    Image.asset('assets/icon/icon.png', width: 88, height: 88),
                    const SizedBox(height: 12),
                    Text(
                      'SIVIC',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sistema de Vigilancia Inteligente',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Tarjeta animada (login ↔ registro)
                    ClipRect(
                      child: Stack(
                        children: [
                          // Panel LOGIN
                          AnimatedBuilder(
                            animation: _anim,
                            builder: (_, child) => FadeTransition(
                              opacity: _fadeSalida,
                              child: SlideTransition(
                                position: _slideSalida,
                                child: child,
                              ),
                            ),
                            child: _enRegistro
                                ? const SizedBox.shrink()
                                : _PanelLogin(
                                    formKey:  _loginForm,
                                    email:    _loginEmail,
                                    password: _loginPassword,
                                    estado:   estado,
                                    onEnviar: _enviarLogin,
                                    onRegistro: _irARegistro,
                                  ),
                          ),

                          // Panel REGISTRO
                          AnimatedBuilder(
                            animation: _anim,
                            builder: (_, child) => FadeTransition(
                              opacity: _fadeEntrada,
                              child: SlideTransition(
                                position: _slideEntrada,
                                child: child,
                              ),
                            ),
                            child: !_enRegistro
                                ? const SizedBox.shrink()
                                : _PanelRegistro(
                                    formKey:   _regForm,
                                    nombre:    _regNombre,
                                    email:     _regEmail,
                                    password:  _regPassword,
                                    estado:    estado,
                                    onEnviar:  _enviarRegistro,
                                    onLogin:   _irALogin,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Panel Login ───────────────────────────────────────────────────────────

class _PanelLogin extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final EstadoAuth estado;
  final VoidCallback onEnviar;
  final VoidCallback onRegistro;

  const _PanelLogin({
    required this.formKey,
    required this.email,
    required this.password,
    required this.estado,
    required this.onEnviar,
    required this.onRegistro,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (estado.error != null)
          _ErrorBanner(mensaje: estado.error!),

        Form(
          key: formKey,
          child: Column(
            children: [
              _CampoTexto(
                controlador: email,
                etiqueta: 'Correo electrónico',
                icono: Icons.email_outlined,
                teclado: TextInputType.emailAddress,
                validador: (v) => (v == null || !v.contains('@')) ? 'Email inválido' : null,
              ),
              const SizedBox(height: 16),
              _CampoTexto(
                controlador: password,
                etiqueta: 'Contraseña',
                icono: Icons.lock_outline,
                esPassword: true,
                validador: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: estado.cargando ? null : onEnviar,
                  style: FilledButton.styleFrom(backgroundColor: kPrimario),
                  child: estado.cargando
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Ingresar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('¿No tienes cuenta?', style: TextStyle(fontSize: 13, color: kTexto2Oscuro)),
            TextButton(
              onPressed: onRegistro,
              child: const Text('Registrarse', style: TextStyle(fontSize: 13, color: kPrimario)),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Panel Registro ────────────────────────────────────────────────────────

class _PanelRegistro extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nombre;
  final TextEditingController email;
  final TextEditingController password;
  final EstadoAuth estado;
  final VoidCallback onEnviar;
  final VoidCallback onLogin;

  const _PanelRegistro({
    required this.formKey,
    required this.nombre,
    required this.email,
    required this.password,
    required this.estado,
    required this.onEnviar,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Crear cuenta de guardia',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'El rol guardia es asignado automáticamente',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        if (estado.error != null)
          _ErrorBanner(mensaje: estado.error!),

        Form(
          key: formKey,
          child: Column(
            children: [
              _CampoTexto(
                controlador: nombre,
                etiqueta: 'Nombre completo',
                icono: Icons.person_outline,
                validador: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 14),
              _CampoTexto(
                controlador: email,
                etiqueta: 'Correo electrónico',
                icono: Icons.email_outlined,
                teclado: TextInputType.emailAddress,
                validador: (v) => (v == null || !v.contains('@')) ? 'Email inválido' : null,
              ),
              const SizedBox(height: 14),
              _CampoTexto(
                controlador: password,
                etiqueta: 'Contraseña',
                icono: Icons.lock_outline,
                esPassword: true,
                validador: (v) => (v == null || v.length < 8) ? 'Mínimo 8 caracteres' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: estado.cargando ? null : onEnviar,
                  style: FilledButton.styleFrom(backgroundColor: kPrimario),
                  child: estado.cargando
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Crear cuenta', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('¿Ya tienes cuenta?', style: TextStyle(fontSize: 13, color: kTexto2Oscuro)),
            TextButton(
              onPressed: onLogin,
              child: const Text('Iniciar sesión', style: TextStyle(fontSize: 13, color: kPrimario)),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Widgets compartidos ───────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String mensaje;
  const _ErrorBanner({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kPeligro.withAlpha(30),
        border: Border.all(color: kPeligro),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(mensaje, style: const TextStyle(color: kPeligro, fontSize: 13)),
    );
  }
}

class _CampoTexto extends StatefulWidget {
  final TextEditingController controlador;
  final String etiqueta;
  final IconData icono;
  final bool esPassword;
  final TextInputType teclado;
  final String? Function(String?)? validador;

  const _CampoTexto({
    required this.controlador,
    required this.etiqueta,
    required this.icono,
    this.esPassword = false,
    this.teclado = TextInputType.text,
    this.validador,
  });

  @override
  State<_CampoTexto> createState() => _CampoTextoState();
}

class _CampoTextoState extends State<_CampoTexto> {
  bool _oculto = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controlador,
      keyboardType: widget.teclado,
      obscureText: widget.esPassword && _oculto,
      validator: widget.validador,
      style: const TextStyle(color: kTextoOscuro),
      decoration: InputDecoration(
        labelText: widget.etiqueta,
        prefixIcon: Icon(widget.icono, color: kTexto2Oscuro),
        suffixIcon: widget.esPassword
            ? IconButton(
                icon: Icon(_oculto ? Icons.visibility_off : Icons.visibility, color: kTexto2Oscuro),
                onPressed: () => setState(() => _oculto = !_oculto),
              )
            : null,
        filled: true,
        fillColor: kSuperficie2Oscura,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kBordeOscuro)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kBordeOscuro)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kPrimario)),
      ),
    );
  }
}
