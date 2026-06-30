import type { RequestDraft, ServiceRequest } from "../types/app";

export const emptyDraft: RequestDraft = {
  customerName: "",
  phone: "",
  vehicle: "",
  location: "",
  preferredDate: "",
  notes: "",
  priority: "عادي"
};

export const starterRequests: ServiceRequest[] = [
  {
    id: "NE-2406",
    serviceId: "maintenance",
    title: "حجز الصيانة",
    status: "الفحص الفني",
    createdAt: "اليوم 10:30 ص",
    priority: "قريب",
    customerName: "عميل New Energy",
    phone: "01000000000",
    vehicle: "سيارة كهربائية",
    location: "مدينة نصر",
    notes: "فحص دوري مع متابعة سرعة الشحن."
  }
];
