// features/auth/presentation/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/text_widget.dart';
import '../provider/auth_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _matricController = TextEditingController();
  String _selectedRole = 'Student';
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter your name' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter your email' : null,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      items: ['Student', 'Lecturer', 'Admin']
                          .map((role) => DropdownMenuItem(
                                value: role,
                                child: Text(role),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedRole = value!),
                      decoration: InputDecoration(
                        //labelText: 'Role',
                        hintText: 'role',
                        prefixIcon: const Icon(Icons.work),
                        border: const OutlineInputBorder(),
                        filled: false,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    if (_selectedRole == 'Student')
                      TextFormField(
                        controller: _matricController,
                        decoration: const InputDecoration(
                          labelText: 'Matric Number',
                          prefixIcon: Icon(Icons.app_registration),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Enter matric number' : null,
                      ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter password' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'confirm Password',
                        hintText: 'confirm password',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Confirm your password' : null,
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        text12Normal(
                          text: "By continuing, you agree to our",
                          color: Colors.black,
                        ),
                        text12Normal(
                          text: " terms & conditions",
                          color: Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : GestureDetector(
                            onTap: () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() => _isLoading = true);
                                final auth = Provider.of<AuthProvider>(context,
                                    listen: false);
                                final result = await auth.register(
                                  name: _nameController.text.trim(),
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text,
                                  confirmPassword:
                                      _confirmPasswordController.text,
                                  role: _selectedRole,
                                  matricNumber: _selectedRole == 'Student'
                                      ? _matricController.text.trim()
                                      : '',
                                );
                                setState(() => _isLoading = false);

                                if (result != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(result)));
                                } else {
                                  Navigator.pushReplacementNamed(context, '/');
                                }
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(16),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Center(
                                child: const Text(
                                  'Register',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                    SizedBox(height: 20),
                    GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoginScreen()));
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            text14Normal(
                              text: 'Already have an account?',
                              color: Colors.grey,
                            ),
                            text14Normal(
                              text: ' Sign in here',
                              color: Colors.green,
                            ),
                          ],
                        )
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
