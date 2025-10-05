import 'package:flutter/material.dart';

class LoginButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onPressed;
  const LoginButton({super.key, required this.loading, required this.onPressed});
  @override
  LoginButtonState createState() => LoginButtonState();
}

class LoginButtonState extends State<LoginButton> with TickerProviderStateMixin {
  late AnimationController _successController;
  late AnimationController _errorController;
  bool _showSuccess = false;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _errorController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _successController.dispose();
    _errorController.dispose();
    super.dispose();
  }

  void showSuccessAnimation() {
    setState(() { _showSuccess = true; });
    _successController.forward(from: 0).then((_) {
      setState(() { _showSuccess = false; });
    });
  }

  void showErrorAnimation() {
    setState(() { _showError = true; });
    _errorController.forward(from: 0).then((_) {
      setState(() { _showError = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_successController, _errorController]),
      builder: (context, child) {
        double shake = _showError ? 8.0 * (1.0 - _errorController.value) * (_errorController.value % 0.2 < 0.1 ? 1 : -1) : 0.0;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _showSuccess ? Colors.green : Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: widget.loading ? null : widget.onPressed,
            child: widget.loading
                ? const CircularProgressIndicator(color: Colors.white)
                : _showSuccess
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 24),
                          SizedBox(width: 10),
                          Text('Welcome!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                        ],
                      )
                    : _showError
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, color: Colors.white, size: 24),
                              SizedBox(width: 10),
                              Text('Login Failed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                            ],
                          )
                        : const Text('LOGIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          ),
        );
      },
    );
  }
}
