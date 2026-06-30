export type TabKey = "home" | "orders" | "tracking" | "invoice" | "payment" | "reviews";

export type ApiState = "checking" | "connected" | "local" | "error";

export type ServiceItem = {
  id: string;
  title: string;
  description: string;
  icon: string;
  color: string;
  tint: string;
  priorityOptions: string[];
};

export type InvoiceItem = {
  label: string;
  amount: number;
};

export type ServiceRequest = {
  id: string;
  wordpressId?: number;
  serviceId: string;
  title: string;
  status: string;
  createdAt: string;
  priority: string;
  customerName: string;
  phone: string;
  vehicle: string;
  location: string;
  notes: string;
  synced?: boolean;
  paymentStatus?: string;
  reportText?: string;
  repairItems?: RepairItem[];
  invoiceItems?: InvoiceItem[];
  invoiceTotal?: number;
};

export type RequestDraft = {
  customerName: string;
  phone: string;
  vehicle: string;
  location: string;
  preferredDate: string;
  notes: string;
  priority: string;
};

export type RepairItem = {
  issue: string;
  fix: string;
  status: string;
};

export type MaintenanceStage = {
  title: string;
  body: string;
};

export type PaymentMethod = {
  id: string;
  title: string;
  icon: string;
};
