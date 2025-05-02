import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../auth/provider/user_provider.dart';

class MatricVerificationScreen extends StatefulWidget {
  const MatricVerificationScreen({super.key});

  @override
  State<MatricVerificationScreen> createState() =>
      _MatricVerificationScreenState();
}

class _MatricVerificationScreenState extends State<MatricVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _matricController = TextEditingController();
  final TextEditingController _levelController = TextEditingController();
  String _selectedDepartment = 'Computer Science';
  bool _isLoading = false;
  bool _showBulkUpload = false;
  List<Map<String, String>> _matricNumbers = [];
  final TextEditingController _bulkMatricController = TextEditingController();

  // List of departments
  final List<String> _departments = [
    'Computer Science',
    'Electrical Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'Chemistry',
    'Physics',
    'Mathematics',
    'Accounting',
    'Business Administration',
  ];

  @override
  void initState() {
    super.initState();
    _levelController.text = '100'; // Default level
  }

  @override
  void dispose() {
    _matricController.dispose();
    _levelController.dispose();
    _bulkMatricController.dispose();
    super.dispose();
  }

  // Validate a matric number format
  bool _isValidMatricNumber(String matricNumber) {
    // Implement your validation logic here
    // For example: Check length, prefix format, etc.
    if (matricNumber.isEmpty) return false;
    if (matricNumber.length < 5) return false;

    // You can add more specific validation depending on your institution's format
    // For example: Regular expression to enforce a specific pattern
    return true;
  }

  // Add a single matric number
  Future<void> _addMatricNumber() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final matricNumber = _matricController.text.trim().toUpperCase();
      final level = _levelController.text.trim();

      // Check if this matric number already exists
      final existingDoc = await FirebaseFirestore.instance
          .collection('valid_matric_numbers')
          .where('matricNumber', isEqualTo: matricNumber)
          .get();

      if (existingDoc.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Matric number already exists!')),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Add to Firestore
      await FirebaseFirestore.instance.collection('valid_matric_numbers').add({
        'matricNumber': matricNumber,
        'level': level,
        'department': _selectedDepartment,
        'isUsed': false,
        'dateAdded': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Matriculation number $matricNumber added successfully')),
      );

      // Clear the form
      _matricController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Parse bulk input and add to temporary list
  void _parseBulkInput() {
    final String text = _bulkMatricController.text.trim();
    if (text.isEmpty) return;

    // Split by newlines
    final lines = text.split('\n');
    final parsedMatricNumbers = <Map<String, String>>[];

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isNotEmpty && _isValidMatricNumber(trimmedLine)) {
        parsedMatricNumbers.add({
          'matricNumber': trimmedLine.toUpperCase(),
          'level': _levelController.text.trim(),
          'department': _selectedDepartment,
        });
      }
    }

    setState(() {
      _matricNumbers = parsedMatricNumbers;
    });

    if (parsedMatricNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid matriculation numbers found')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Found ${parsedMatricNumbers.length} matriculation numbers')),
      );
    }
  }

  // Upload bulk matric numbers to Firestore
  Future<void> _uploadBulkMatricNumbers() async {
    if (_matricNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No matriculation numbers to upload')),
      );
      return;
    }

    setState(() => _isLoading = true);
    int successCount = 0;
    int errorCount = 0;

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Check for existing matric numbers first
      final allMatricNumbers =
          _matricNumbers.map((m) => m['matricNumber']!).toList();
      final existingDocs = await FirebaseFirestore.instance
          .collection('valid_matric_numbers')
          .where('matricNumber', whereIn: allMatricNumbers)
          .get();

      // Create a set of existing matric numbers for quick lookup
      final existingMatricNumbers = existingDocs.docs
          .map((doc) => doc.data()['matricNumber'] as String)
          .toSet();

      // Filter out already existing matric numbers
      final newMatricNumbers = _matricNumbers
          .where((m) => !existingMatricNumbers.contains(m['matricNumber']))
          .toList();

      if (newMatricNumbers.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('All matriculation numbers already exist')),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Add each new matric number to the batch
      for (final matricData in newMatricNumbers) {
        final docRef =
            FirebaseFirestore.instance.collection('valid_matric_numbers').doc();
        batch.set(docRef, {
          'matricNumber': matricData['matricNumber'],
          'level': matricData['level'],
          'department': matricData['department'],
          'isUsed': false,
          'dateAdded': FieldValue.serverTimestamp(),
        });
        successCount++;
      }

      // Commit the batch
      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Successfully added $successCount matriculation numbers. '
                '${existingMatricNumbers.length} were skipped as duplicates.')),
      );

      // Clear the form and list
      _bulkMatricController.clear();
      setState(() {
        _matricNumbers = [];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Delete a matric number from Firestore
  Future<void> _deleteMatricNumber(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('valid_matric_numbers')
          .doc(docId)
          .delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Matriculation number deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text(
            'Matric Number Verification',
            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w400),
          ),
          centerTitle: false,
          elevation: 0,
          bottom: TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: 'Add Matric Numbers'),
              Tab(text: 'Manage Matric Numbers'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // First tab: Add matric numbers
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Add Matriculation Numbers',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _showBulkUpload = !_showBulkUpload;
                                  });
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      _showBulkUpload
                                          ? 'Single Entry'
                                          : 'Bulk Upload',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Icon(
                                      _showBulkUpload
                                          ? Icons.person
                                          : Icons.group,
                                      color: Colors.blue,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Add valid matriculation numbers that students can use for registration',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),

                          // Form for adding matric numbers
                          if (!_showBulkUpload) ...[
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    controller: _matricController,
                                    decoration: const InputDecoration(
                                      labelText: 'Matriculation Number',
                                      hintText: 'e.g., CSC/2020/001',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.badge),
                                    ),
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a matriculation number';
                                      }
                                      if (!_isValidMatricNumber(value)) {
                                        return 'Please enter a valid matriculation number';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 150,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Level field
                                        Expanded(
                                          child: TextFormField(
                                            controller: _levelController,
                                            decoration: const InputDecoration(
                                              labelText: 'Level',
                                              hintText: 'e.g., 100',
                                              border: OutlineInputBorder(),
                                              prefixIcon: Icon(Icons.school),
                                            ),
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                            ],
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter a level';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Department dropdown
                                        Expanded(
                                          child:
                                              DropdownButtonFormField<String>(
                                            value: _selectedDepartment,
                                            decoration: const InputDecoration(
                                              labelText: 'Department',
                                              border: OutlineInputBorder(),
                                              prefixIcon: Icon(Icons.business),
                                            ),
                                            items: _departments
                                                .map((String department) {
                                              return DropdownMenuItem<String>(
                                                value: department,
                                                child: Text(department),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              if (newValue != null) {
                                                setState(() {
                                                  _selectedDepartment =
                                                      newValue;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed:
                                          _isLoading ? null : _addMatricNumber,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              'Add Matriculation Number'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // Bulk upload form
                            SizedBox(
                              height: 150,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Level field for bulk
                                  Expanded(
                                    child: TextFormField(
                                      controller: _levelController,
                                      decoration: const InputDecoration(
                                        labelText: 'Level for All',
                                        hintText: 'e.g., 100',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.school),
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Department dropdown for bulk
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedDepartment,
                                      decoration: const InputDecoration(
                                        labelText: 'Department for All',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.business),
                                      ),
                                      items:
                                          _departments.map((String department) {
                                        return DropdownMenuItem<String>(
                                          value: department,
                                          child: Text(department),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            _selectedDepartment = newValue;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _bulkMatricController,
                              decoration: const InputDecoration(
                                labelText:
                                    'Matriculation Numbers (One per line)',
                                hintText:
                                    'CSC/2020/001\nCSC/2020/002\nCSC/2020/003',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                              ),
                              maxLines: 8,
                              textCapitalization: TextCapitalization.characters,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Enter one matriculation number per line',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _parseBulkInput,
                                    icon: const Icon(Icons.check),
                                    label: const Text('Validate'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        _matricNumbers.isEmpty || _isLoading
                                            ? null
                                            : _uploadBulkMatricNumbers,
                                    icon: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.upload),
                                    label: const Text('Upload'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      backgroundColor: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_matricNumbers.isNotEmpty) ...[
                              const Divider(),
                              const SizedBox(height: 8),
                              Text(
                                '${_matricNumbers.length} Valid Matriculation Numbers',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: ListView.builder(
                                  itemCount: _matricNumbers.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: Row(
                                        children: [
                                          Text(
                                            '${index + 1}.',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _matricNumbers[index]
                                                ['matricNumber']!,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '${_matricNumbers[index]['level']} Level',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Second tab: Manage matric numbers
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('valid_matric_numbers')
                  .orderBy('dateAdded', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No matriculation numbers found'),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Registered Matriculation Numbers (${docs.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Data table for matric numbers
                      isMobile
                          ? _buildMobileMatricList(docs)
                          : _buildDesktopMatricTable(docs),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Mobile-friendly list view for matric numbers
  Widget _buildMobileMatricList(List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final isUsed = data['isUsed'] ?? false;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              data['matricNumber'] ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${data['department']} - ${data['level']} Level',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isUsed
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isUsed ? 'Used' : 'Available',
                    style: TextStyle(
                      color: isUsed ? Colors.green : Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteMatricNumber(docs[index].id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Desktop-friendly data table for matric numbers
  Widget _buildDesktopMatricTable(List<QueryDocumentSnapshot> docs) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DataTable(
          columnSpacing: 20,
          horizontalMargin: 12,
          columns: const [
            DataColumn(label: Text('Matriculation Number')),
            DataColumn(label: Text('Level')),
            DataColumn(label: Text('Department')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final isUsed = data['isUsed'] ?? false;

            return DataRow(
              cells: [
                DataCell(Text(
                  data['matricNumber'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                )),
                DataCell(Text(data['level']?.toString() ?? 'N/A')),
                DataCell(Text(data['department'] ?? 'N/A')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isUsed
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isUsed ? 'Used' : 'Available',
                      style: TextStyle(
                        color: isUsed ? Colors.green : Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteMatricNumber(doc.id),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
