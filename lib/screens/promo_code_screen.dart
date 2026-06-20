import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/promo_code_service.dart';

class PromoCodeScreen extends StatefulWidget {
  const PromoCodeScreen({super.key});

  @override
  State<PromoCodeScreen> createState() => _PromoCodeScreenState();
}

class _PromoCodeScreenState extends State<PromoCodeScreen> {
  final _codeController = TextEditingController();
  final _promoService = PromoCodeService();
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final result = await _promoService.redeemCode(code);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _isSuccess = result == PromoCodeResult.success;
      _message = _messageFor(result);
    });

    if (result == PromoCodeResult.success) {
      // ← Recharge le statut Pro dans l'app entière
      await context.read<AuthProvider>().refreshProStatus();
    }
  }

  String _messageFor(PromoCodeResult result) {
    switch (result) {
      case PromoCodeResult.success:
        return 'Code activé ! Profite de Picder Pro 🎉';
      case PromoCodeResult.notFound:
        return 'Ce code n\'existe pas';
      case PromoCodeResult.expired:
        return 'Ce code a expiré';
      case PromoCodeResult.maxUsesReached:
        return 'Ce code a atteint sa limite d\'utilisation';
      case PromoCodeResult.inactive:
        return 'Ce code n\'est plus actif';
      case PromoCodeResult.alreadyUsedByUser:
        return 'Tu as déjà utilisé ce code';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Code promo', style: TextStyle(color: onSurface)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.redeem, color: Colors.amber, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Entre ton code promo',
                  style: TextStyle(color: onSurface, fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (!authProvider.isLoggedIn)
                  Text(
                    'Connecte-toi d\'abord pour activer un code',
                    style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 24),

                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(color: onSurface, fontSize: 18, letterSpacing: 2),
                  textAlign: TextAlign.center,
                  enabled: authProvider.isLoggedIn,
                  decoration: const InputDecoration(
                    hintText: 'CODEPROMO',
                    border: OutlineInputBorder(),
                  ),
                ),

                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _message!,
                    style: TextStyle(color: _isSuccess ? Colors.green : Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 24),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: (_isLoading || !authProvider.isLoggedIn) ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Activer le code'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}