import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/service_models.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

class RequestSheet extends StatefulWidget {
  const RequestSheet({
    required this.controller,
    required this.service,
    super.key,
  });

  final AppController controller;
  final ServiceItem service;

  @override
  State<RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<RequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _locationController = TextEditingController();
  final _dateController = TextEditingController();
  final _notesController = TextEditingController();
  late String _priority = widget.service.priorityOptions.first;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.controller.account?.displayName ?? '';
    _phoneController.text = widget.controller.account?.phone ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleController.dispose();
    _locationController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return FractionallySizedBox(
          heightFactor: 0.94,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: widget.service.tint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          widget.service.icon,
                          color: widget.service.color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.service.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.service.description,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Tooltip(
                        message: 'إغلاق',
                        child: IconButton(
                          onPressed: widget.controller.isSubmitting
                              ? null
                              : () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      key: const Key('request-form-list'),
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                        _Field(
                          label: 'الاسم',
                          hint: 'اسم العميل',
                          controller: _nameController,
                          readOnly:
                              widget
                                  .controller
                                  .account
                                  ?.displayName
                                  .isNotEmpty ??
                              false,
                          autofillHints: const [AutofillHints.name],
                          textInputAction: TextInputAction.next,
                        ),
                        _Field(
                          label: 'رقم الهاتف',
                          hint: '01xxxxxxxxx',
                          controller: _phoneController,
                          readOnly:
                              widget.controller.account?.phone.isNotEmpty ??
                              false,
                          keyboardType: TextInputType.phone,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          textInputAction: TextInputAction.next,
                          validator: _requiredValidator,
                        ),
                        _Field(
                          label: 'نوع السيارة',
                          hint: 'مثال: BYD أو Tesla أو Mercedes EQ',
                          controller: _vehicleController,
                          textInputAction: TextInputAction.next,
                        ),
                        _Field(
                          label: 'الموقع',
                          hint: 'العنوان أو المنطقة',
                          controller: _locationController,
                          autofillHints: const [
                            AutofillHints.fullStreetAddress,
                          ],
                          textInputAction: TextInputAction.next,
                          validator: _requiredValidator,
                        ),
                        _Field(
                          label: 'الموعد المفضل',
                          hint: 'اليوم مساءً أو غداً 11 ص',
                          controller: _dateController,
                          textInputAction: TextInputAction.next,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'الأولوية',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return SegmentedButton<String>(
                              showSelectedIcon: false,
                              segments: widget.service.priorityOptions
                                  .map(
                                    (option) => ButtonSegment<String>(
                                      value: option,
                                      label: Text(
                                        option,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              selected: {_priority},
                              onSelectionChanged: (selection) {
                                setState(() => _priority = selection.first);
                              },
                              style: ButtonStyle(
                                minimumSize: const WidgetStatePropertyAll(
                                  Size(0, 46),
                                ),
                                padding: WidgetStatePropertyAll(
                                  EdgeInsets.symmetric(
                                    horizontal: constraints.maxWidth < 360
                                        ? 6
                                        : 11,
                                  ),
                                ),
                                textStyle: const WidgetStatePropertyAll(
                                  TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        _Field(
                          label: 'تفاصيل إضافية',
                          hint: 'اكتب المشكلة أو القطعة المطلوبة',
                          controller: _notesController,
                          minLines: 3,
                          maxLines: 5,
                          textInputAction: TextInputAction.newline,
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: AsyncButton(
                            label: widget.controller.isSubmitting
                                ? 'جاري تسجيل الطلب'
                                : 'تأكيد الطلب',
                            icon: Icons.check_circle_outline,
                            busy: widget.controller.isSubmitting,
                            onPressed: _submit,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'هذا الحقل مطلوب';
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final result = await widget.controller.submitRequest(
      widget.service,
      RequestDraft(
        customerName: _nameController.text,
        phone: _phoneController.text,
        vehicle: _vehicleController.text,
        location: _locationController.text,
        preferredDate: _dateController.text,
        notes: _notesController.text,
        priority: _priority,
      ),
    );
    if (!mounted) return;
    if (result.success) {
      Navigator.pop(context, result);
    } else {
      showAppMessage(context, result.message, isError: true);
    }
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    required this.textInputAction,
    this.keyboardType,
    this.autofillHints,
    this.validator,
    this.readOnly = false,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final bool readOnly;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            autofillHints: autofillHints,
            textInputAction: textInputAction,
            validator: validator,
            readOnly: readOnly,
            minLines: minLines,
            maxLines: maxLines,
            textAlign: TextAlign.right,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }
}
