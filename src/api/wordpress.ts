import {
  IS_WORDPRESS_CONFIGURED,
  WORDPRESS_APP_TOKEN,
  WORDPRESS_BASE_URL
} from "../config";

const API_NAMESPACE = "newenergy/v1";

export type WordpressServiceRequestPayload = {
  serviceId: string;
  serviceTitle: string;
  status: string;
  priority: string;
  customerName: string;
  phone: string;
  vehicle: string;
  location: string;
  preferredDate: string;
  notes: string;
};

export type WordpressInvoiceItem = {
  label: string;
  amount: number;
};

export type WordpressRepairItem = {
  issue: string;
  fix: string;
  status: string;
};

export type WordpressServiceRequest = {
  id: number;
  requestNumber: string;
  serviceId: string;
  serviceTitle: string;
  status: string;
  priority: string;
  customerName: string;
  phone: string;
  vehicle: string;
  location: string;
  preferredDate: string;
  notes: string;
  reportText: string;
  repairItems: WordpressRepairItem[];
  invoiceItems: WordpressInvoiceItem[];
  invoiceTotal: number;
  paymentStatus: string;
  paymentMethod: string;
  paidAmount: number;
  rating: number;
  createdAt: string;
  updatedAt: string;
};

export type WordpressProduct = {
  id: number;
  name: string;
  permalink: string;
  prices?: {
    price?: string;
    currency_symbol?: string;
    currency_minor_unit?: number;
  };
  categories?: Array<{
    id: number;
    name: string;
    slug: string;
  }>;
};

type WordpressPaymentPayload = {
  paymentMethod: string;
  amount: number;
  status: "paid" | "pending" | "failed";
};

type WordpressReviewPayload = {
  rating: number;
  message?: string;
};

type ApiFetchOptions = {
  method?: "GET" | "POST" | "PUT" | "PATCH" | "DELETE";
  body?: string;
  headers?: Record<string, string>;
  requireToken?: boolean;
};

export async function checkWordpressConnection() {
  return wordpressFetch<{ ok: boolean; site: string; namespace: string }>("/health", {
    method: "GET",
    requireToken: false
  });
}

export async function createServiceRequest(payload: WordpressServiceRequestPayload) {
  return wordpressFetch<WordpressServiceRequest>("/service-requests", {
    method: "POST",
    body: JSON.stringify({
      service_id: payload.serviceId,
      service_title: payload.serviceTitle,
      status: payload.status,
      priority: payload.priority,
      customer_name: payload.customerName,
      phone: payload.phone,
      vehicle: payload.vehicle,
      location: payload.location,
      preferred_date: payload.preferredDate,
      notes: payload.notes
    })
  });
}

export async function listServiceRequests(phone: string) {
  const query = `phone=${encodeURIComponent(phone)}`;
  return wordpressFetch<WordpressServiceRequest[]>(`/service-requests?${query}`, {
    method: "GET"
  });
}

export async function recordPayment(requestId: number, payload: WordpressPaymentPayload) {
  return wordpressFetch<WordpressServiceRequest>(`/service-requests/${requestId}/payment`, {
    method: "POST",
    body: JSON.stringify({
      payment_method: payload.paymentMethod,
      amount: payload.amount,
      status: payload.status
    })
  });
}

export async function submitAppReview(requestId: number, payload: WordpressReviewPayload) {
  return wordpressFetch<WordpressServiceRequest>(`/service-requests/${requestId}/review`, {
    method: "POST",
    body: JSON.stringify({
      rating: payload.rating,
      message: payload.message ?? ""
    })
  });
}

export async function fetchStoreProducts(limit = 4) {
  const response = await fetch(
    `${WORDPRESS_BASE_URL}/wp-json/wc/store/v1/products?per_page=${limit}`
  );

  if (!response.ok) {
    throw new Error(`WooCommerce products failed with ${response.status}`);
  }

  return (await response.json()) as WordpressProduct[];
}

async function wordpressFetch<T>(
  path: string,
  options: ApiFetchOptions = {}
) {
  const requireToken = options.requireToken ?? true;

  if (requireToken && !IS_WORDPRESS_CONFIGURED) {
    throw new Error("WordPress app token is not configured.");
  }

  const response = await fetch(`${WORDPRESS_BASE_URL}/wp-json/${API_NAMESPACE}${path}`, {
    ...options,
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      ...(WORDPRESS_APP_TOKEN ? { "X-NewEnergy-App-Token": WORDPRESS_APP_TOKEN } : {}),
      ...(options.headers ?? {})
    }
  });

  const data = await response.json().catch(() => null);

  if (!response.ok) {
    const message =
      data && typeof data === "object" && "message" in data
        ? String((data as { message: unknown }).message)
        : `WordPress request failed with ${response.status}`;
    throw new Error(message);
  }

  return data as T;
}
