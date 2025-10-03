import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Multi-step form for adding new medication reminders
/// Includes drug search, dosage input, frequency selection, and custom scheduling
class AddMedicationFormWidget extends StatefulWidget {
  final Function(MedicationFormData) onSave;

  const AddMedicationFormWidget({
    super.key,
    required this.onSave,
  });

  @override
  State<AddMedicationFormWidget> createState() =>
      _AddMedicationFormWidgetState();
}

class _AddMedicationFormWidgetState extends State<AddMedicationFormWidget> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  int _currentStep = 0;
  final int _totalSteps = 4;

  // Form data
  String _drugName = '';
  String _dosage = '';
  FrequencyType _frequencyType = FrequencyType.daily;
  List<TimeOfDay> _scheduledTimes = [];
  List<int> _selectedDays = [];
  String _notes = '';
  String _selectedDosageUnit = 'mg';

  static const List<String> _commonMedications = [
    'Aspirin',
    'Ibuprofen',
    'Paracetamol',
    'Metformin',
    'Lisinopril',
    'Amlodipine',
    'Simvastatin',
    'Omeprazole',
    'Levothyroxine',
    'Warfarin',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _saveMedication() {
    if (_formKey.currentState?.validate() ?? false) {
      final medicationData = MedicationFormData(
        drugName: _drugName,
        dosage: '$_dosage $_selectedDosageUnit',
        frequencyType: _frequencyType,
        scheduledTimes: _scheduledTimes,
        selectedDays: _selectedDays,
        notes: _notes.isEmpty ? null : _notes,
      );

      widget.onSave(medicationData);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medication'),
        actions: [
          if (_currentStep == _totalSteps - 1)
            TextButton(
              onPressed: _saveMedication,
              child: Text(
                'Save',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),

            // Step indicator
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Step ${_currentStep + 1} of $_totalSteps',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _getStepTitle(),
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),

            // Form pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildDrugSelectionStep(),
                  _buildDosageStep(),
                  _buildFrequencyStep(),
                  _buildNotesStep(),
                ],
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentStep == _totalSteps - 1
                          ? _saveMedication
                          : _nextStep,
                      child: Text(
                        _currentStep == _totalSteps - 1
                            ? 'Save Medication'
                            : 'Next',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Select Medication';
      case 1:
        return 'Set Dosage';
      case 2:
        return 'Set Frequency';
      case 3:
        return 'Additional Notes';
      default:
        return '';
    }
  }

  Widget _buildDrugSelectionStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What medication are you taking?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),

          // Drug name input
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Medication Name',
              hintText: 'Enter or search medication name',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _drugName = value),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter medication name';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Common medications
          Text(
            'Common Medications',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: _commonMedications
                  .map((medication) => _buildMedicationChip(medication))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationChip(String medication) {
    final theme = Theme.of(context);
    final isSelected = _drugName == medication;

    return InkWell(
      onTap: () => setState(() => _drugName = medication),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            medication,
            style: GoogleFonts.inter(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDosageStep() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s the dosage?',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Dosage amount
              Expanded(
                flex: 2,
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    hintText: '10',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setState(() => _dosage = value),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Enter dosage';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(width: 16),

              // Unit selector
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                  ),
                  value: _selectedDosageUnit,
                  items: ['mg', 'g', 'ml', 'tablets', 'drops', 'IU']
                      .map((unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(unit),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedDosageUnit = value);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How often do you take it?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),

          // Frequency options
          ...FrequencyType.values.map(
            (frequency) => RadioListTile<FrequencyType>(
              title: Text(frequency.label),
              subtitle: Text(frequency.description),
              value: frequency,
              groupValue: _frequencyType,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _frequencyType = value);
                }
              },
            ),
          ),

          const SizedBox(height: 24),

          // Time selection
          if (_frequencyType == FrequencyType.daily ||
              _frequencyType == FrequencyType.twiceDaily ||
              _frequencyType == FrequencyType.threeTimesDaily) ...[
            Text(
              'Select Times',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._scheduledTimes.map((time) => Chip(
                      label: Text(time.format(context)),
                      onDeleted: () {
                        setState(() => _scheduledTimes.remove(time));
                      },
                    )),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('Add Time'),
                  onPressed: _addTime,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Information',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Special Instructions (Optional)',
              hintText: 'Take with food, before meals, etc.',
            ),
            maxLines: 3,
            onChanged: (value) => setState(() => _notes = value),
          ),
        ],
      ),
    );
  }

  void _addTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null && !_scheduledTimes.contains(time)) {
      setState(() => _scheduledTimes.add(time));
    }
  }
}

/// Frequency options for medication reminders
enum FrequencyType {
  daily('Daily', 'Once per day'),
  twiceDaily('Twice Daily', 'Two times per day'),
  threeTimesDaily('Three Times Daily', 'Three times per day'),
  weekly('Weekly', 'Once per week'),
  asNeeded('As Needed', 'When required');

  const FrequencyType(this.label, this.description);

  final String label;
  final String description;
}

/// Data class for medication form
class MedicationFormData {
  final String drugName;
  final String dosage;
  final FrequencyType frequencyType;
  final List<TimeOfDay> scheduledTimes;
  final List<int> selectedDays;
  final String? notes;

  const MedicationFormData({
    required this.drugName,
    required this.dosage,
    required this.frequencyType,
    required this.scheduledTimes,
    required this.selectedDays,
    this.notes,
  });
}
