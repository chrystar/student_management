// features/auth/presentation/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_management/features/auth/presentation/registration_screen.dart';
import '../../../core/widgets/text_widget.dart';
import '../provider/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _matricController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _selectedRole = 'Student';
  bool _isPasswordVisible = false;

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
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        text24Normal(
                          text: "Login",
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: 12),
                        text14Normal(
                          text: 'Welcome back to the app',
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
            
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      items: ['Student', 'Lecturer', 'Admin']
                          .map((role) => DropdownMenuItem(
                                value: role,
                                child: Text(role),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedRole = value!),
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
                    const SizedBox(height: 16),
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
                      )
                    else
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) => value!.isEmpty ? 'Enter email' : null,
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    // TextFormField(
                    //   controller: _passwordController,
                    //   decoration: const InputDecoration(labelText: 'Password'),
                    //   obscureText: true,
                    //   validator: (value) => value!.isEmpty ? 'Enter password' : null,
                    // ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            child: GestureDetector(
                              onTap: () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() => _isLoading = true);
                                  final auth = Provider.of<AuthProvider>(context,
                                      listen: false);
                                  String? result;
            
                                  if (_selectedRole == 'Student') {
                                    result = await auth.loginWithMatric(
                                      matricNumber: _matricController.text.trim(),
                                      password: _passwordController.text,
                                    );
                                  } else {
                                    result = await auth.loginWithEmail(
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text,
                                    );
                                  }
            
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
                                padding: EdgeInsets.all(18),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(10)
                                ),
                                child: Center(
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          color: Color(0xff4B5768),
                          height: 0.5,
                          width: 125,
                        ),
                        text14Normal(
                            text: 'Or sign Up',
                            color: Color(0xff999DA3)),
                        Container(
                          color: Color(0xff4B5768),
                          height: 0.5,
                          width: 125,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => RegisterScreen()));
                      },
                      child: text16Normal(
                        text: 'Create an Account',
                        color: Colors.green,
                      ),
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
