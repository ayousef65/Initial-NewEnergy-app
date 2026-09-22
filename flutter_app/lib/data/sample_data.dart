import 'package:flutter/material.dart';

import '../models/service_models.dart';

const services = <ServiceItem>[
  ServiceItem(
    id: 'maintenance',
    title: 'حجز الصيانة',
    description: 'موعد مركز الخدمة مع تشخيص وفحص شامل.',
    icon: Icons.car_repair_outlined,
    color: Color(0xFF157A6E),
    tint: Color(0xFFE0F3EF),
    priorityOptions: ['عادي', 'قريب', 'عاجل'],
  ),
  ServiceItem(
    id: 'home-visit',
    title: 'طلب زيارة منزلية',
    description: 'فني يصل للعميل للفحص أو التركيب.',
    icon: Icons.home_repair_service_outlined,
    color: Color(0xFF315C9A),
    tint: Color(0xFFE7EEF9),
    priorityOptions: ['عادي', 'قريب', 'عاجل'],
  ),
  ServiceItem(
    id: 'emergency-visit',
    title: 'طلب زيارة طوارئ',
    description: 'استجابة سريعة للأعطال المفاجئة.',
    icon: Icons.emergency_outlined,
    color: Color(0xFFC84630),
    tint: Color(0xFFFBE8E4),
    priorityOptions: ['طوارئ', 'فوري', 'أقرب فني'],
  ),
  ServiceItem(
    id: 'spare-parts',
    title: 'شراء قطعة غيار',
    description: 'طلب قطع أصلية أو بدائل معتمدة.',
    icon: Icons.settings_outlined,
    color: Color(0xFF8E5A00),
    tint: Color(0xFFFFF0CF),
    priorityOptions: ['عرض سعر', 'متوفر الآن', 'طلب خاص'],
  ),
  ServiceItem(
    id: 'charger-accessory',
    title: 'شراء شاحن أو اكسسوار',
    description: 'شواحن منزلية، كابلات، ومحولات.',
    icon: Icons.ev_station_outlined,
    color: Color(0xFF5D58A6),
    tint: Color(0xFFECEBFA),
    priorityOptions: ['عرض سعر', 'تركيب', 'استلام'],
  ),
  ServiceItem(
    id: 'tow',
    title: 'طلب ونش طوارئ',
    description: 'نقل السيارة لأقرب مركز خدمة.',
    icon: Icons.local_shipping_outlined,
    color: Color(0xFF0F6B7A),
    tint: Color(0xFFE0F2F5),
    priorityOptions: ['فوري', 'خلال ساعة', 'حسب المتاح'],
  ),
];

const starterRequests = <ServiceRequest>[
  ServiceRequest(
    id: 'NE-2406',
    serviceId: 'maintenance',
    title: 'حجز الصيانة',
    status: 'الفحص الفني',
    createdAt: 'اليوم 10:30 ص',
    priority: 'قريب',
    customerName: 'عميل New Energy',
    phone: '01000000000',
    vehicle: 'سيارة كهربائية',
    location: 'مدينة نصر',
    notes: 'فحص دوري مع متابعة سرعة الشحن.',
  ),
];

const maintenanceStages = <MaintenanceStage>[
  MaintenanceStage(
    title: 'تسجيل الطلب',
    body: 'تم استلام بيانات العميل والسيارة وتأكيد قناة التواصل.',
  ),
  MaintenanceStage(
    title: 'الفحص الفني',
    body: 'الفني يراجع الأعطال ويحدثك بتقرير أولي.',
  ),
  MaintenanceStage(
    title: 'تحديد المشاكل',
    body: 'تم حصر البنود المطلوبة وقطع الغيار قبل البدء.',
  ),
  MaintenanceStage(
    title: 'الإصلاح والمتابعة',
    body: 'إصلاحات جارية مع تحديثات مباشرة عند كل خطوة.',
  ),
  MaintenanceStage(
    title: 'اختبار الجودة',
    body: 'اختبار أداء السيارة والشاحن قبل التسليم.',
  ),
  MaintenanceStage(
    title: 'الفاتورة والتسليم',
    body: 'إرسال التقرير والفاتورة ثم إغلاق الطلب بعد السداد.',
  ),
];

const repairItems = <RepairItem>[
  RepairItem(
    issue: 'ضعف في سرعة الشحن',
    fix: 'تحديث برمجة وحدة الشحن وفحص منفذ Type 2.',
    status: 'تم الإصلاح',
  ),
  RepairItem(
    issue: 'اهتزاز بسيط مع الفرامل',
    fix: 'تنظيف حساس ABS ومراجعة تيل الفرامل.',
    status: 'قيد الاختبار',
  ),
  RepairItem(
    issue: 'تنبيه بطارية على الشاشة',
    fix: 'فحص BMS وإعادة معايرة نسبة الشحن.',
    status: 'بانتظار تأكيد الفني',
  ),
];

const invoiceItems = <InvoiceItem>[
  InvoiceItem(label: 'فحص وتشخيص شامل', amount: 450),
  InvoiceItem(label: 'تحديث برمجة وحدة الشحن', amount: 850),
  InvoiceItem(label: 'تنظيف وفحص حساسات الفرامل', amount: 620),
  InvoiceItem(label: 'قطعة غيار معتمدة', amount: 980),
  InvoiceItem(label: 'ضريبة وخدمة', amount: 290),
];

const paymentMethods = <PaymentMethodItem>[
  PaymentMethodItem(
    id: 'card',
    title: 'بطاقة بنكية',
    icon: Icons.credit_card_outlined,
  ),
  PaymentMethodItem(
    id: 'wallet',
    title: 'محفظة إلكترونية',
    icon: Icons.account_balance_wallet_outlined,
  ),
  PaymentMethodItem(
    id: 'transfer',
    title: 'تحويل بنكي',
    icon: Icons.account_balance_outlined,
  ),
  PaymentMethodItem(
    id: 'cash',
    title: 'كاش عند التسليم',
    icon: Icons.payments_outlined,
  ),
];
