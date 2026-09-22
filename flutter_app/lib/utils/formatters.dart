import 'package:intl/intl.dart';

String formatMoney(num value) {
  return '${NumberFormat.decimalPattern('ar_EG').format(value)} جنيه';
}

String formatDecimal(num value) {
  return NumberFormat.decimalPattern('ar_EG').format(value);
}

String formatProductPrice({
  required String rawPrice,
  required String currencySymbol,
  required int minorUnit,
}) {
  final amount = double.tryParse(rawPrice);
  if (amount == null || amount <= 0) return 'السعر عند الطلب';
  final visible = amount / _powerOfTen(minorUnit);
  return '$currencySymbol${NumberFormat.decimalPattern('ar_EG').format(visible)}';
}

String formatApiDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value.isEmpty ? 'الآن' : value;
  return DateFormat('d MMMM yyyy', 'ar_EG').format(parsed.toLocal());
}

String localizeStatus(String status) {
  const statuses = <String, String>{
    'registered': 'تم التسجيل',
    'dispatching': 'توجيه الفريق',
    'inspection': 'الفحص الفني',
    'issues_found': 'تحديد المشاكل',
    'repairing': 'الإصلاح والمتابعة',
    'quality_check': 'اختبار الجودة',
    'invoice_ready': 'الفاتورة جاهزة',
    'pending': 'قيد المراجعة',
    'submitted': 'قيد المراجعة',
    'paid': 'تم السداد',
    'failed': 'فشل الدفع',
    'refunded': 'تم رد المبلغ',
    'closed': 'مغلق',
  };
  return statuses[status] ?? status;
}

String localizeRepairStatus(String status) {
  const statuses = <String, String>{
    'missing': 'مطلوب',
    'checking': 'قيد الفحص',
    'waiting_part': 'بانتظار قطعة',
    'repairing': 'قيد الإصلاح',
    'testing': 'قيد الاختبار',
    'fixed': 'تم الإصلاح',
    'not_needed': 'غير مطلوب',
  };
  return statuses[status] ?? status;
}

String localizeOrderStatus(String status) {
  const statuses = <String, String>{
    'pending': 'بانتظار الدفع',
    'on-hold': 'قيد التأكيد',
    'processing': 'قيد التجهيز',
    'completed': 'مكتمل',
    'cancelled': 'ملغي',
    'refunded': 'تم رد المبلغ',
    'failed': 'تعذر التنفيذ',
  };
  return statuses[status] ?? status;
}

int maintenanceStageIndex(String status) {
  const indexes = <String, int>{
    'تم التسجيل': 0,
    'الفحص الفني': 1,
    'تحديد المشاكل': 2,
    'الإصلاح والمتابعة': 3,
    'اختبار الجودة': 4,
    'الفاتورة جاهزة': 5,
    'تم السداد': 5,
    'مغلق': 5,
  };
  return indexes[localizeStatus(status)] ?? 2;
}

num _powerOfTen(int exponent) {
  var result = 1;
  for (var index = 0; index < exponent; index += 1) {
    result *= 10;
  }
  return result;
}
