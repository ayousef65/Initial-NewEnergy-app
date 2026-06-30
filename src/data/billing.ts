import type { InvoiceItem, PaymentMethod } from "../types/app";

export const invoiceItems: InvoiceItem[] = [
  { label: "فحص وتشخيص شامل", amount: 450 },
  { label: "تحديث برمجة وحدة الشحن", amount: 850 },
  { label: "تنظيف وفحص حساسات الفرامل", amount: 620 },
  { label: "قطعة غيار معتمدة", amount: 980 },
  { label: "ضريبة وخدمة", amount: 290 }
];

export const paymentMethods: PaymentMethod[] = [
  { id: "card", title: "بطاقة بنكية", icon: "credit-card-outline" },
  { id: "wallet", title: "محفظة إلكترونية", icon: "wallet-outline" },
  { id: "transfer", title: "تحويل بنكي", icon: "bank-transfer" },
  { id: "cash", title: "كاش عند التسليم", icon: "cash" }
];
