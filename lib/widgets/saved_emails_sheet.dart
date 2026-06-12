import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_strings.dart';
import '../models/saved_emails_store.dart';
import '../theme/app_colors.dart';

/// يعرض البريدات المحفوظة عند النقر على حقل البريد.
Future<String?> showSavedEmailsSheet(BuildContext context) async {
  final emails = await SavedEmailsStore.instance.load();
  if (emails.isEmpty || !context.mounted) return null;

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _SavedEmailsSheetBody(emails: emails),
  );
}

class _SavedEmailsSheetBody extends StatefulWidget {
  const _SavedEmailsSheetBody({required this.emails});

  final List<String> emails;

  @override
  State<_SavedEmailsSheetBody> createState() => _SavedEmailsSheetBodyState();
}

class _SavedEmailsSheetBodyState extends State<_SavedEmailsSheetBody> {
  late List<String> _emails;

  @override
  void initState() {
    super.initState();
    _emails = List<String>.from(widget.emails);
  }

  Future<void> _remove(String email) async {
    await SavedEmailsStore.instance.remove(email);
    if (!mounted) return;
    setState(() => _emails.remove(email));
    if (_emails.isEmpty) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('saved_emails_title'),
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._emails.map(
              (email) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.email_outlined, color: AppColors.primary),
                title: Text(
                  email,
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 15),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
                  tooltip: context.tr('remove_saved_email'),
                  onPressed: () => _remove(email),
                ),
                onTap: () => Navigator.pop(context, email),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.tr('enter_new_email'),
                style: GoogleFonts.cairo(color: Colors.white70, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
