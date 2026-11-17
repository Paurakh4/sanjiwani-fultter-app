import 'package:flutter/material.dart';

import '../core/icons.dart';

import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../core/nepali.dart';
import '../core/tokens.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../widgets/app_refresh.dart';
import '../widgets/common.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _genders = ['महिला', 'पुरुष', 'अन्य'];
  static const _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
    'थाहा छैन',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _ageController;
  late final TextEditingController _addressController;
  late String _gender;
  late String _bloodGroup;
  late final PatientProfile _initial;
  late String _initialGender;
  late String _initialBloodGroup;
  bool _saved = false;

  bool get _dirty =>
      !_saved &&
      (_nameController.text != _initial.name ||
          _phoneController.text != _initial.phone ||
          _ageController.text != _initial.age ||
          _addressController.text != _initial.address ||
          _gender != _initialGender ||
          _bloodGroup != _initialBloodGroup);

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>().profile;
    _nameController = TextEditingController(text: profile.name);
    _phoneController = TextEditingController(text: profile.phone);
    _ageController = TextEditingController(text: profile.age);
    _addressController = TextEditingController(text: profile.address);
    _gender = _genders.contains(profile.gender)
        ? profile.gender
        : _genders.first;
    _bloodGroup = _bloodGroups.contains(profile.bloodGroup)
        ? profile.bloodGroup
        : 'थाहा छैन';
    _initial = profile;
    _initialGender = _gender;
    _initialBloodGroup = _bloodGroup;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _save() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final l10n = L10n.of(context);
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final age = _ageController.text.trim();

    state.updateProfile(
      state.profile.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        age: age.isEmpty ? state.profile.age : age,
        gender: _gender,
        bloodGroup: _bloodGroup,
        address: _addressController.text.trim(),
      ),
    );

    _saved = true;
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);
    final profile = context.read<AppState>().profile;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: Text(l10n.editProfileTitle),
        ),
        body: AppRefreshView(
          onRefresh: demoRefresh,
          child: Form(
            key: _formKey,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppTokens.gutter,
                4,
                AppTokens.gutter,
                40,
              ),
              children: [
                Text(
                  l10n.editProfileIntro,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: l10n.fullNameHint,
                    prefixIcon: const Icon(CoolIcons.user),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.nameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: l10n.phoneHint,
                    prefixIcon: const Icon(CoolIcons.phone),
                  ),
                  validator: (value) {
                    final digits = (value ?? '').replaceAll(
                      RegExp(r'[^0-9०-९]'),
                      '',
                    );
                    if (digits.length < 7) {
                      return l10n.phoneInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: l10n.ageHint,
                    prefixIcon: const Icon(CoolIcons.cake),
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return null;
                    final age = int.tryParse(asciiDigits(text));
                    if (age == null || age < 1 || age > 120) {
                      return l10n.ageInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _FieldLabel(text: l10n.genderLabel),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final gender in _genders)
                      ChoicePill(
                        label: l10n.gender(gender),
                        selected: _gender == gender,
                        onTap: () => setState(() => _gender = gender),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _FieldLabel(text: l10n.bloodGroupLabel),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final group in _bloodGroups)
                      ChoicePill(
                        label: l10n.bloodGroupDisplay(group),
                        selected: _bloodGroup == group,
                        onTap: () => setState(() => _bloodGroup = group),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _addressController,
                  textInputAction: TextInputAction.done,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: l10n.addressHint,
                    prefixIcon: const Icon(CoolIcons.mapPin),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppTokens.radiusField),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CoolIcons.identificationBadge,
                        size: 20,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.patientIdField,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        profile.patientId,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(onPressed: _save, child: Text(l10n.saveProfile)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDiscard() async {
    final l10n = L10n.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.discardTitle),
        content: Text(l10n.discardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.keepEditing),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.discardChanges),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
