import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/provider/user_provider.dart';

class StudentProfileTab extends StatelessWidget {
  const StudentProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
        centerTitle: true,
        leading: CircleAvatar(
          radius: 20,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<UserProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Center(
                            child: Text(
                              'Name: ${user.name}',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Center(
                            child: Text('Email: ${user.email}',
                                style: const TextStyle(fontSize: 18)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Center(
                            child: Text('Role: ${user.role}',
                                style: const TextStyle(fontSize: 18)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Center(
                            child: Text('Matric Number: ${user.matricNumber}',
                                style: const TextStyle(fontSize: 18)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
