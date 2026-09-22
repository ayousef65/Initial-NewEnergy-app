import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/app_controller.dart';
import '../models/service_models.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({required this.controller, super.key});

  final AppController controller;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.controller.account?.displayName ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.controller.account?.phone ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('بيانات الطلب')),
          body: Form(
            key: _formKey,
            child: ContentPage(
              children: [
                const ScreenHeading(
                  title: 'التوصيل والتأكيد',
                  subtitle: 'راجع بيانات التواصل ومكان استلام المنتجات.',
                  icon: Icons.local_shipping_outlined,
                ),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(
                    labelText: 'الاسم',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  textDirection: TextDirection.ltr,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: _addressController,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.streetAddressLine1],
                  decoration: const InputDecoration(
                    labelText: 'العنوان بالتفصيل',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: _cityController,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.addressCity],
                  decoration: const InputDecoration(
                    labelText: 'المدينة أو المنطقة',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات اختيارية',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SectionTitle(title: 'ملخص المنتجات'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        ...widget.controller.cartItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.product.name} × ${item.quantity}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${item.product.currencySymbol}${formatDecimal(item.total)}',
                                  style: const TextStyle(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 22),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'الإجمالي المبدئي',
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Text(
                              '${widget.controller.cartCurrency}${formatDecimal(widget.controller.cartTotal)}',
                              style: const TextStyle(
                                color: AppColors.brand,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'سيؤكد فريق New Energy التوصيل وطريقة الدفع بعد مراجعة الطلب.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                AsyncButton(
                  label: 'تأكيد طلب المتجر',
                  icon: Icons.check_circle_outline,
                  busy: widget.controller.isPlacingShopOrder,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final result = await widget.controller.placeShopOrder(
      ShopCheckoutDraft(
        customerName: _nameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        city: _cityController.text,
        notes: _notesController.text,
      ),
    );
    if (!mounted) return;
    if (!result.success) {
      showAppMessage(context, result.message, isError: true);
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.brand, size: 42),
        title: const Text('تم استلام طلبك'),
        content: Text(result.message, textAlign: TextAlign.center),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('العودة للمتجر'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.pop();
  }
}
