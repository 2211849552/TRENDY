import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/saved_emails_store.dart';
import 'saved_emails_sheet.dart';

/// حقل بريد مع اختيار من البريدات المستخدمة سابقاً عند النقر.
class SavedEmailField extends StatefulWidget {
  const SavedEmailField({
    super.key,
    required this.controller,
    required this.decoration,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillLast = true,
  });

  final TextEditingController controller;
  final InputDecoration decoration;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  /// تعبئة آخر بريد محفوظ عند فتح الشاشة.
  final bool autofillLast;

  @override
  State<SavedEmailField> createState() => _SavedEmailFieldState();
}

class _SavedEmailFieldState extends State<SavedEmailField> {
  bool _hasSavedEmails = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final emails = await SavedEmailsStore.instance.load();
    if (!mounted) return;
    setState(() => _hasSavedEmails = emails.isNotEmpty);
    if (widget.autofillLast && emails.isNotEmpty && widget.controller.text.trim().isEmpty) {
      widget.controller.text = emails.first;
    }
  }

  Future<void> _pickSavedEmail() async {
    final picked = await showSavedEmailsSheet(context);
    if (picked == null || !mounted) return;
    widget.controller.text = picked;
    widget.controller.selection = TextSelection.collapsed(offset: picked.length);
  }

  InputDecoration get _decoration {
    if (!_hasSavedEmails) return widget.decoration;
    return widget.decoration.copyWith(
      suffixIcon: IconButton(
        icon: const Icon(Icons.expand_more_rounded, color: Colors.white70),
        tooltip: context.tr('pick_saved_email'),
        onPressed: _pickSavedEmail,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.validator != null) {
      return TextFormField(
        controller: widget.controller,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        textInputAction: widget.textInputAction,
        style: const TextStyle(color: Colors.white),
        decoration: _decoration,
        validator: widget.validator,
        onFieldSubmitted: widget.onFieldSubmitted,
        onTap: _hasSavedEmails ? _pickSavedEmail : null,
      );
    }

    return TextField(
      controller: widget.controller,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      textInputAction: widget.textInputAction,
      style: const TextStyle(color: Colors.white),
      decoration: _decoration,
      onSubmitted: widget.onFieldSubmitted,
      onTap: _hasSavedEmails ? _pickSavedEmail : null,
    );
  }
}
