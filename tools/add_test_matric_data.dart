// Test script to add sample matric numbers for testing login
// Run this once to add test data to Firestore

import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  print('This is a sample script to add test matric numbers.');
  print('You should run this from Firebase Console or add the data manually.');
  print('');
  print('Sample data to add to "valid_matric_numbers" collection:');
  print('');
  
  // Sample matric numbers for testing
  final sampleMatricNumbers = [
    {
      'matricNumber': 'STU001',
      'isUsed': true,
      'userEmail': 'student1@example.com',
      'userId': 'test_user_id_1',
    },
    {
      'matricNumber': 'STU002', 
      'isUsed': true,
      'userEmail': 'student2@example.com',
      'userId': 'test_user_id_2',
    },
    {
      'matricNumber': 'STU003',
      'isUsed': false,
      'userEmail': null,
      'userId': null,
    },
  ];
  
  print('Add these documents to the "valid_matric_numbers" collection:');
  for (int i = 0; i < sampleMatricNumbers.length; i++) {
    print('Document ${i + 1}:');
    print(sampleMatricNumbers[i]);
    print('');
  }
  
  print('To test login:');
  print('1. Make sure you have a user account with email "student1@example.com"');
  print('2. Try logging in with matric number "STU001" and the user\'s password');
}
