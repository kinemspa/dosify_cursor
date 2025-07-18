import 'package:flutter/material.dart';
import '../../models/medication.dart';
import '../../theme/app_decorations.dart';
import '../../services/firebase_service.dart';
import '../../widgets/input_field_row.dart';
import 'package:uuid/uuid.dart';
import 'add_medication_form.dart';

class AddVialReconMedicationScreen extends StatefulWidget {
  const AddVialReconMedicationScreen({super.key});

  @override
  State<AddVialReconMedicationScreen> createState() => _AddVialReconMedicationScreenState();
}

class _AddVialReconMedicationScreenState extends State<AddVialReconMedicationScreen> {
  final _reconVolumeController = TextEditingController();
  String _reconVolumeUnit = 'mL';
  final _concentrationController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _firebaseService.initialize();
    } catch (e) {
      print('Error initializing services: $e');
    }
  }

  @override
  void dispose() {
    _reconVolumeController.dispose();
    _concentrationController.dispose();
    super.dispose();
  }

  Future<void> _handleSave(BuildContext context, Map<String, dynamic> data) async {
    if (_reconVolumeController.text.isEmpty || _concentrationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Generate a unique ID using UUID
      final uuid = const Uuid().v4();
      
      final medication = Medication(
        id: uuid,
        name: data['name'],
        // Using injection type instead of vialPowderedRecon (planned for future expansion)
        type: MedicationType.injection,
        strength: data['strength'],
        strengthUnit: data['strengthUnit'],
        quantity: data['quantity'],
        quantityUnit: data['quantityUnit'],
        currentInventory: data['currentInventory'],
        lastInventoryUpdate: DateTime.now(),
        reconstitutionVolume: double.parse(_reconVolumeController.text),
        reconstitutionVolumeUnit: _reconVolumeUnit,
        concentrationAfterReconstitution: double.parse(_concentrationController.text),
        // Additional fields for injection type
        needsReconstitution: true, // This is a reconstitution vial
      );

      // Save medication to Firebase
      await _firebaseService.addMedication(medication);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medication saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving medication: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildReconstitutionFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Reconstitution Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        InputFieldRow(
          label: 'Reconstitution Volume',
          controller: _reconVolumeController,
          unitValue: _reconVolumeUnit,
          unitOptions: const ['mL'],
          onUnitChanged: (value) {
            if (value != null) {
              setState(() {
                _reconVolumeUnit = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _concentrationController,
          decoration: AppDecorations.inputField(
            labelText: 'Final Concentration (per mL)',
            hintText: 'Enter concentration',
            suffixText: 'mg/mL',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
            if (double.tryParse(value) == null) {
              return 'Invalid number';
            }
            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AddMedicationForm(
      // Using injection type instead of vialPowderedRecon (planned for future expansion)
      medicationType: MedicationType.injection,
      title: 'Add Reconstitution Vial',
      additionalFields: _buildReconstitutionFields(),
      onSave: (data) => _handleSave(context, data),
    );
  }
} 