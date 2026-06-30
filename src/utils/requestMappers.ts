import type { WordpressServiceRequest } from "../api/wordpress";
import type { ServiceRequest } from "../types/app";
import { localizeRepairStatus, localizeStatus } from "./formatting";

export function mapWordpressRequest(item: WordpressServiceRequest): ServiceRequest {
  return {
    id: item.requestNumber || `NE-${item.id}`,
    wordpressId: item.id,
    serviceId: item.serviceId,
    title: item.serviceTitle || "طلب خدمة",
    status: localizeStatus(item.status || "تم التسجيل"),
    createdAt: item.createdAt ? new Date(item.createdAt).toLocaleDateString("ar-EG") : "WordPress",
    priority: item.priority || "عادي",
    customerName: item.customerName || "عميل New Energy",
    phone: item.phone,
    vehicle: item.vehicle || "غير محدد",
    location: item.location || "غير محدد",
    notes: item.notes || item.preferredDate,
    synced: true,
    paymentStatus: item.paymentStatus,
    reportText: item.reportText,
    repairItems: item.repairItems?.map((repair) => ({
      issue: repair.issue,
      fix: repair.fix,
      status: localizeRepairStatus(repair.status)
    })),
    invoiceItems: item.invoiceItems,
    invoiceTotal: item.invoiceTotal
  };
}
