export function formatMoney(value: number) {
  return `${value.toLocaleString("ar-EG")} جنيه`;
}

export function localizeStatus(status: string) {
  const statuses: Record<string, string> = {
    registered: "تم التسجيل",
    inspection: "الفحص الفني",
    issues_found: "تحديد المشاكل",
    repairing: "الإصلاح والمتابعة",
    quality_check: "اختبار الجودة",
    invoice_ready: "الفاتورة جاهزة",
    pending: "قيد المراجعة",
    paid: "تم السداد",
    failed: "فشل الدفع",
    closed: "مغلق"
  };

  return statuses[status] ?? status;
}

export function getMaintenanceStageIndex(status: string) {
  const stages: Record<string, number> = {
    "تم التسجيل": 0,
    "الفحص الفني": 1,
    "تحديد المشاكل": 2,
    "الإصلاح والمتابعة": 3,
    "اختبار الجودة": 4,
    "الفاتورة جاهزة": 5,
    "تم السداد": 5,
    "مغلق": 5
  };

  return stages[status] ?? 2;
}

export function localizeRepairStatus(status: string) {
  const statuses: Record<string, string> = {
    missing: "مطلوب",
    checking: "قيد الفحص",
    waiting_part: "بانتظار قطعة",
    repairing: "قيد الإصلاح",
    testing: "قيد الاختبار",
    fixed: "تم الإصلاح",
    not_needed: "غير مطلوب"
  };

  return statuses[status] ?? status;
}
