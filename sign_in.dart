import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  // Error messages
  static const _emailRequiredError = 'Vui lòng nhập email';
  static const _invalidEmailError = 'Email không hợp lệ';
  static const _passwordRequiredError = 'Vui lòng nhập mật khẩu';
  static const _weakPasswordError = 'Mật khẩu phải có ít nhất 6 ký tự';
  static const _confirmPasswordError = 'Vui lòng nhập lại mật khẩu';
  static const _passwordNotMatchError = 'Mật khẩu không khớp';
  late DatabaseReference df;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // 1. Đăng ký người dùng
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // 2. Kiểm tra người dùng đã được tạo
        if (userCredential.user == null) {
          throw Exception('User creation failed');
        }

        String modifiedUser = _emailController.text.trim().replaceAll('.', '').replaceAll('@gmail.com', '');
        // 3. Ghi email vào Realtime Database theo UID
        df = FirebaseDatabase.instance.ref();
        df.child("$modifiedUser").set("");

        // 4. Thông báo thành công
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký thành công!')),
        );

        // 5. Đóng màn hình đăng ký
        Navigator.pop(context);

      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Đăng ký thất bại';
        if (e.code == 'email-already-in-use') {
          errorMessage = 'Email đã được sử dụng';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Email không hợp lệ';
        } else if (e.code == 'weak-password') {
          errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự';
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi hệ thống: ${e.toString()}')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return _emailRequiredError;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return _invalidEmailError;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return _passwordRequiredError;
    }
    if (value.length < 6) {
      return _weakPasswordError;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return _confirmPasswordError;
    }
    if (value != _passwordController.text) {
      return _passwordNotMatchError;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mật khẩu'),
                obscureText: true,
                validator: _validatePassword,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: 'Nhập lại mật khẩu'),
                obscureText: true,
                validator: _validateConfirmPassword,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRegister,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Đăng ký'),
                ),
              ),
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text('Đã có tài khoản? Đăng nhập'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
