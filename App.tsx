import { StatusBar } from "expo-status-bar";
import { useEffect, useMemo, useState } from "react";
import { Alert, I18nManager, Linking, Pressable, SafeAreaView, ScrollView, Text, View } from "react-native";
import {
  checkWordpressConnection,
  createServiceRequest,
  fetchStoreProducts,
  listServiceRequests,
  recordPayment,
  submitAppReview,
  type WordpressProduct
} from "./src/api/wordpress";
import { ConnectionBanner, ProductRow, RequestCard, ServiceCard } from "./src/components/cards";
import { MIcon } from "./src/components/common/MIcon";
import { ActionButton, ScreenHeading, SectionTitle, StatusPill, TabButton } from "./src/components/common/ui";
import { StageTimeline } from "./src/components/maintenance/StageTimeline";
import { RequestModal } from "./src/components/modals/RequestModal";
import { IS_WORDPRESS_CONFIGURED, REVIEW_LINKS, WORDPRESS_BASE_URL } from "./src/config";
import { invoiceItems, paymentMethods } from "./src/data/billing";
import { repairItems } from "./src/data/maintenance";
import { emptyDraft, starterRequests } from "./src/data/requests";
import { services } from "./src/data/services";
import { styles } from "./src/styles/appStyles";
import type { ApiState, RequestDraft, ServiceItem, ServiceRequest, TabKey } from "./src/types/app";
import { formatMoney, getMaintenanceStageIndex } from "./src/utils/formatting";
import { mapWordpressRequest } from "./src/utils/requestMappers";

I18nManager.allowRTL(true);

const reviewLinks = REVIEW_LINKS;

function getRepairTone(status: string): "good" | "warn" | "danger" {
  if (["تم الإصلاح", "غير مطلوب"].includes(status)) {
    return "good";
  }

  if (status === "مطلوب") {
    return "danger";
  }

  return "warn";
}

export default function App() {
  const [activeTab, setActiveTab] = useState<TabKey>("home");
  const [requests, setRequests] = useState<ServiceRequest[]>(starterRequests);
  const [selectedService, setSelectedService] = useState<ServiceItem | null>(null);
  const [draft, setDraft] = useState<RequestDraft>(emptyDraft);
  const [selectedPayment, setSelectedPayment] = useState("card");
  const [paymentPaid, setPaymentPaid] = useState(false);
  const [rating, setRating] = useState(5);
  const [apiState, setApiState] = useState<ApiState>(IS_WORDPRESS_CONFIGURED ? "checking" : "local");
  const [apiMessage, setApiMessage] = useState(
    IS_WORDPRESS_CONFIGURED
      ? `Connecting to ${WORDPRESS_BASE_URL}`
      : "Add EXPO_PUBLIC_NEWENERGY_APP_TOKEN to sync requests with WordPress."
  );
  const [shopProducts, setShopProducts] = useState<WordpressProduct[]>([]);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isSyncing, setIsSyncing] = useState(false);

  const invoiceTotal = useMemo(
    () => invoiceItems.reduce((sum, item) => sum + item.amount, 0),
    []
  );

  const activeRequest = requests[0];
  const activePaymentPaid =
    paymentPaid || activeRequest.paymentStatus === "paid" || activeRequest.status === "تم السداد";
  const activeInvoiceItems =
    activeRequest.invoiceItems && activeRequest.invoiceItems.length > 0
      ? activeRequest.invoiceItems
      : invoiceItems;
  const activeRepairItems =
    activeRequest.repairItems && activeRequest.repairItems.length > 0
      ? activeRequest.repairItems
      : repairItems;
  const activeInvoiceTotal =
    activeRequest.invoiceTotal && activeRequest.invoiceTotal > 0 ? activeRequest.invoiceTotal : invoiceTotal;
  const activeStageIndex = getMaintenanceStageIndex(activeRequest.status);
  const updateTime = useMemo(() => {
    return new Date().toLocaleString("ar-EG", {
      weekday: "long",
      hour: "numeric",
      minute: "2-digit"
    });
  }, []);

  useEffect(() => {
    let mounted = true;

    async function connect() {
      if (!IS_WORDPRESS_CONFIGURED) {
        return;
      }

      try {
        await checkWordpressConnection();
        if (mounted) {
          setApiState("connected");
          setApiMessage("Requests and payments will sync with newenergyeg.com.");
        }
      } catch (error) {
        if (mounted) {
          setApiState("error");
          setApiMessage(error instanceof Error ? error.message : "WordPress connection failed.");
        }
      }
    }

    connect();

    return () => {
      mounted = false;
    };
  }, []);

  useEffect(() => {
    let mounted = true;

    async function loadProducts() {
      try {
        const products = await fetchStoreProducts(4);
        if (mounted) {
          setShopProducts(products);
        }
      } catch {
        if (mounted) {
          setShopProducts([]);
        }
      }
    }

    loadProducts();

    return () => {
      mounted = false;
    };
  }, []);

  function openService(item: ServiceItem) {
    setSelectedService(item);
    setDraft({
      ...emptyDraft,
      priority: item.priorityOptions[0]
    });
  }

  function updateDraft(key: keyof RequestDraft, value: string) {
    setDraft((current) => ({
      ...current,
      [key]: value
    }));
  }

  async function submitRequest() {
    if (!selectedService) {
      return;
    }

    if (!draft.phone.trim() || !draft.location.trim()) {
      Alert.alert("بيانات مطلوبة", "أدخل رقم الهاتف والموقع حتى يستطيع الفريق تأكيد الطلب.");
      return;
    }

    const localRequest: ServiceRequest = {
      id: `NE-${Math.floor(1000 + Math.random() * 9000)}`,
      serviceId: selectedService.id,
      title: selectedService.title,
      status: selectedService.id.includes("emergency") || selectedService.id === "tow" ? "توجيه الفريق" : "تم التسجيل",
      createdAt: "الآن",
      priority: draft.priority,
      customerName: draft.customerName.trim() || "عميل New Energy",
      phone: draft.phone.trim(),
      vehicle: draft.vehicle.trim() || "غير محدد",
      location: draft.location.trim(),
      notes: draft.notes.trim() || draft.preferredDate.trim(),
      synced: false,
      paymentStatus: "pending"
    };

    setIsSubmitting(true);

    try {
      const wordpressRequest = await createServiceRequest({
        serviceId: selectedService.id,
        serviceTitle: selectedService.title,
        status: localRequest.status,
        priority: draft.priority,
        customerName: localRequest.customerName,
        phone: localRequest.phone,
        vehicle: localRequest.vehicle,
        location: localRequest.location,
        preferredDate: draft.preferredDate.trim(),
        notes: draft.notes.trim()
      });

      setRequests((current) => [mapWordpressRequest(wordpressRequest), ...current]);
      setApiState("connected");
      setApiMessage("Latest request was saved in WordPress.");
      setSelectedService(null);
      setActiveTab("orders");
      Alert.alert("تم تسجيل الطلب", "تم حفظ الطلب داخل WordPress ويمكن متابعته من لوحة الموقع.");
    } catch (error) {
      setRequests((current) => [localRequest, ...current]);
      setApiState(IS_WORDPRESS_CONFIGURED ? "error" : "local");
      setApiMessage(error instanceof Error ? error.message : "Request saved locally only.");
      setSelectedService(null);
      setActiveTab("orders");
      Alert.alert("تم تسجيل الطلب محلياً", "لم يتم إرسال الطلب إلى WordPress بعد. راجع إعدادات التوكن أو إضافة WordPress.");
    } finally {
      setIsSubmitting(false);
    }
  }

  function openExternal(url: string) {
    Linking.openURL(url).catch(() => {
      Alert.alert("تعذر فتح الرابط", "تأكد من توفر متصفح أو تطبيق مناسب على الجهاز.");
    });
  }

  async function openReviewLink(url: string) {
    if (activeRequest.wordpressId) {
      try {
        await submitAppReview(activeRequest.wordpressId, {
          rating,
          message: "Submitted from the mobile app."
        });
      } catch (error) {
        setApiState("error");
        setApiMessage(error instanceof Error ? error.message : "Review sync failed.");
      }
    }

    openExternal(url);
  }

  async function syncRequestsFromWordpress() {
    const phone = activeRequest?.phone;

    if (!phone) {
      Alert.alert("لا يوجد رقم هاتف", "أنشئ طلباً أولاً أو أدخل رقم هاتف في الطلب.");
      return;
    }

    setIsSyncing(true);

    try {
      const wordpressRequests = await listServiceRequests(phone);
      setRequests(wordpressRequests.map(mapWordpressRequest));
      setApiState("connected");
      setApiMessage("Requests were refreshed from WordPress.");
      Alert.alert("تم التحديث", "تم تحميل أحدث الطلبات من WordPress.");
    } catch (error) {
      setApiState(IS_WORDPRESS_CONFIGURED ? "error" : "local");
      setApiMessage(error instanceof Error ? error.message : "Could not sync requests.");
      Alert.alert("تعذر التحديث", "لم نتمكن من تحميل الطلبات من WordPress الآن.");
    } finally {
      setIsSyncing(false);
    }
  }

  async function completePayment() {
    if (activePaymentPaid) {
      return;
    }

    try {
      if (activeRequest.wordpressId) {
        const updatedRequest = await recordPayment(activeRequest.wordpressId, {
          paymentMethod: selectedPayment,
          amount: activeInvoiceTotal,
          status: "paid"
        });
        const mappedRequest = mapWordpressRequest(updatedRequest);
        setRequests((current) =>
          current.map((request) => (request.id === activeRequest.id ? mappedRequest : request))
        );
      }

      setPaymentPaid(true);
      Alert.alert("تم السداد", "تم تسجيل الدفع وإتاحة إرسال التقييم.");
      setActiveTab("reviews");
    } catch (error) {
      setApiState("error");
      setApiMessage(error instanceof Error ? error.message : "Payment sync failed.");
      Alert.alert("تعذر تسجيل الدفع", "راجع اتصال WordPress ثم حاول مرة أخرى.");
    }
  }

  function renderHome() {
    return (
      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        <View style={styles.headerBand}>
          <View style={styles.brandRow}>
            <View>
              <Text style={styles.brandText}>New Energy</Text>
              <Text style={styles.brandSubText}>خدمات السيارات الكهربائية</Text>
            </View>
            <Pressable
              accessibilityRole="button"
              onPress={() => openExternal("tel:01000000000")}
              style={({ pressed }) => [styles.callButton, pressed && styles.pressed]}
            >
              <MIcon name="phone-outline" size={22} color="#FFFFFF" />
            </Pressable>
          </View>

          <Text style={styles.heroTitle}>لوحة الخدمة</Text>
          <Text style={styles.heroText}>تابع الصيانة، اطلب زيارة أو ونش، واشتر قطع الغيار والشواحن من مكان واحد.</Text>

          <View style={styles.summaryStrip}>
            <View style={styles.summaryItem}>
              <Text style={styles.summaryValue}>{requests.length}</Text>
              <Text style={styles.summaryLabel}>طلب نشط</Text>
            </View>
            <View style={styles.summaryDivider} />
            <View style={styles.summaryItem}>
              <Text style={styles.summaryValue}>{activePaymentPaid ? "مدفوع" : "مفتوح"}</Text>
              <Text style={styles.summaryLabel}>الفاتورة</Text>
            </View>
            <View style={styles.summaryDivider} />
            <View style={styles.summaryItemWide}>
              <Text style={styles.summaryValueSmall}>{updateTime}</Text>
              <Text style={styles.summaryLabel}>آخر تحديث</Text>
            </View>
          </View>
        </View>

        <ConnectionBanner state={apiState} message={apiMessage} />

        <SectionTitle title="الخدمات" />
        <View style={styles.serviceGrid}>
          {services.map((item) => (
            <ServiceCard key={item.id} item={item} onPress={() => openService(item)} />
          ))}
        </View>

        {shopProducts.length > 0 && (
          <>
            <SectionTitle
              title="منتجات من الموقع"
              action={
                <Pressable onPress={() => openExternal(`${WORDPRESS_BASE_URL}/shop/`)} style={styles.linkButton}>
                  <Text style={styles.linkButtonText}>فتح المتجر</Text>
                </Pressable>
              }
            />
            <View style={styles.productList}>
              {shopProducts.map((product) => (
                <ProductRow
                  key={product.id}
                  product={product}
                  onPress={() => openExternal(product.permalink)}
                />
              ))}
            </View>
          </>
        )}

        <SectionTitle
          title="متابعة الصيانة"
          action={
            <Pressable onPress={() => setActiveTab("tracking")} style={styles.linkButton}>
              <Text style={styles.linkButtonText}>عرض التفاصيل</Text>
            </Pressable>
          }
        />
        <View style={styles.card}>
          <View style={styles.cardTopRow}>
            <View>
              <Text style={styles.cardTitle}>{activeRequest.title}</Text>
              <Text style={styles.cardMeta}>{activeRequest.id} - {activeRequest.location}</Text>
            </View>
            <StatusPill label="الفحص الفني" tone="warn" />
          </View>
          <View style={styles.progressTrack}>
            <View style={styles.progressFill} />
          </View>
          <Text style={styles.cardBody}>تم فحص نظام الشحن وتسجيل 3 ملاحظات. التقرير الفني والفاتورة جاهزان للمراجعة.</Text>
          <View style={styles.buttonRow}>
            <ActionButton label="التقرير" icon="file-document-outline" onPress={() => setActiveTab("invoice")} variant="secondary" />
            <ActionButton label="الدفع" icon="cash-check" onPress={() => setActiveTab("payment")} variant="primary" />
          </View>
        </View>
      </ScrollView>
    );
  }

  function renderOrders() {
    return (
      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        <ScreenHeading
          title="طلباتك"
          subtitle="كل طلب صيانة أو زيارة أو شراء يظهر هنا مع حالته الحالية."
          icon="clipboard-text-search-outline"
        />
        <ConnectionBanner state={apiState} message={apiMessage} />
        <View style={styles.singleButtonRow}>
          <ActionButton
            label={isSyncing ? "جاري التحديث" : "تحديث من WordPress"}
            icon="cloud-sync-outline"
            onPress={syncRequestsFromWordpress}
            variant="secondary"
            disabled={isSyncing}
          />
        </View>
        {requests.map((request) => (
          <RequestCard
            key={request.id}
            request={request}
            onTrack={() => setActiveTab("tracking")}
            onInvoice={() => setActiveTab("invoice")}
          />
        ))}
      </ScrollView>
    );
  }

  function renderTracking() {
    return (
      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        <ScreenHeading
          title="متابعة الصيانة"
          subtitle="مراحل الصيانة والمشاكل والإصلاحات تظهر أولاً بأول."
          icon="timeline-check-outline"
        />

        <View style={styles.card}>
          <View style={styles.cardTopRow}>
            <View>
              <Text style={styles.cardTitle}>{activeRequest.id}</Text>
              <Text style={styles.cardMeta}>{activeRequest.vehicle} - {activeRequest.location}</Text>
            </View>
            <StatusPill label="قيد التنفيذ" tone="good" />
          </View>
          <StageTimeline currentIndex={activeStageIndex} />
        </View>

        <SectionTitle title="المشاكل والإصلاحات" />
        {activeRepairItems.map((item) => (
          <View key={item.issue} style={styles.repairRow}>
            <View style={styles.repairIcon}>
              <MIcon name="wrench-outline" size={20} color="#157A6E" />
            </View>
            <View style={styles.repairCopy}>
              <View style={styles.timelineTitleRow}>
                <Text style={styles.repairIssue}>{item.issue}</Text>
                <StatusPill label={item.status} tone={getRepairTone(item.status)} />
              </View>
              <Text style={styles.repairFix}>{item.fix}</Text>
            </View>
          </View>
        ))}
      </ScrollView>
    );
  }

  function renderInvoice() {
    return (
      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        <ScreenHeading
          title="التقرير والفاتورة"
          subtitle="ملخص فني واضح مع بنود التكلفة قبل السداد."
          icon="receipt-text-outline"
        />

        <View style={styles.card}>
          <View style={styles.cardTopRow}>
            <View>
              <Text style={styles.cardTitle}>تقرير فني رقم {activeRequest.id}</Text>
              <Text style={styles.cardMeta}>الفني المسؤول: م. أحمد - مركز القاهرة</Text>
            </View>
            <StatusPill label={activePaymentPaid ? "مدفوعة" : "غير مدفوعة"} tone={activePaymentPaid ? "good" : "danger"} />
          </View>

          <View style={styles.reportBox}>
            <Text style={styles.reportTitle}>نتيجة الفحص</Text>
            <Text style={styles.reportText}>{activeRequest.reportText || "السيارة تعمل بكفاءة بعد تحديث وحدة الشحن وإعادة معايرة نظام إدارة البطارية. يوصى بمراجعة دورية بعد 5,000 كم."}</Text>
          </View>

          <View style={styles.invoiceList}>
            {activeInvoiceItems.map((item) => (
              <View key={item.label} style={styles.invoiceRow}>
                <Text style={styles.invoiceLabel}>{item.label}</Text>
                <Text style={styles.invoiceAmount}>{formatMoney(item.amount)}</Text>
              </View>
            ))}
          </View>

          <View style={styles.totalRow}>
            <Text style={styles.totalLabel}>الإجمالي</Text>
            <Text style={styles.totalAmount}>{formatMoney(activeInvoiceTotal)}</Text>
          </View>

          <View style={styles.buttonRow}>
            <ActionButton label="إرسال التقرير" icon="share-variant-outline" onPress={() => Alert.alert("جاهز للإرسال", "يمكن ربط هذا الزر بالبريد أو واتساب أو لوحة الإدارة.")} variant="secondary" />
            <ActionButton label="سداد الآن" icon="cash-check" onPress={() => setActiveTab("payment")} variant="primary" disabled={activePaymentPaid} />
          </View>
        </View>
      </ScrollView>
    );
  }

  function renderPayment() {
    return (
      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        <ScreenHeading
          title="الدفع"
          subtitle="اختر وسيلة السداد ثم أكد العملية لإغلاق الفاتورة."
          icon="cash-check"
        />

        <View style={styles.paymentPanel}>
          <Text style={styles.paymentAmount}>{formatMoney(activeInvoiceTotal)}</Text>
          <Text style={styles.paymentCaption}>{activePaymentPaid ? "تم السداد بنجاح" : "المبلغ المستحق لفاتورة الصيانة الحالية"}</Text>
        </View>

        <SectionTitle title="وسيلة الدفع" />
        <View style={styles.methodGrid}>
          {paymentMethods.map((method) => {
            const active = selectedPayment === method.id;
            return (
              <Pressable
                key={method.id}
                accessibilityRole="button"
                onPress={() => setSelectedPayment(method.id)}
                style={({ pressed }) => [
                  styles.methodCard,
                  active && styles.methodCardActive,
                  pressed && styles.pressed
                ]}
              >
                <MIcon name={method.icon} size={26} color={active ? "#157A6E" : "#54616B"} />
                <Text style={[styles.methodTitle, active && styles.methodTitleActive]}>{method.title}</Text>
              </Pressable>
            );
          })}
        </View>

        <View style={styles.card}>
          <View style={styles.cardTopRow}>
            <View>
              <Text style={styles.cardTitle}>إيصال مبدئي</Text>
              <Text style={styles.cardMeta}>فاتورة {activeRequest.id} - {activePaymentPaid ? "مسددة" : "في انتظار السداد"}</Text>
            </View>
            <StatusPill label={activePaymentPaid ? "مكتمل" : "مطلوب"} tone={activePaymentPaid ? "good" : "warn"} />
          </View>
          <ActionButton
            label={activePaymentPaid ? "تم السداد" : "تأكيد الدفع"}
            icon={activePaymentPaid ? "check-circle-outline" : "lock-check-outline"}
            onPress={completePayment}
            disabled={activePaymentPaid}
          />
        </View>
      </ScrollView>
    );
  }

  function renderReviews() {
    return (
      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        <ScreenHeading
          title="التقييم"
          subtitle="بعد إتمام الخدمة، شارك تقييمك على فيسبوك وجوجل ماب."
          icon="star-outline"
        />

        <View style={styles.card}>
          <View style={styles.reviewHeader}>
            <MIcon name={activePaymentPaid ? "check-decagram-outline" : "clock-outline"} size={34} color={activePaymentPaid ? "#157A6E" : "#C84630"} />
            <View style={styles.reviewHeaderCopy}>
              <Text style={styles.cardTitle}>{activePaymentPaid ? "الخدمة جاهزة للتقييم" : "التقييم بعد السداد"}</Text>
              <Text style={styles.cardBody}>{activePaymentPaid ? "شكراً لاستخدامك New Energy." : "سيتم تفعيل روابط التقييم بمجرد تسجيل الدفع."}</Text>
            </View>
          </View>

          <View style={styles.starRow}>
            {[1, 2, 3, 4, 5].map((star) => (
              <Pressable
                key={star}
                accessibilityRole="button"
                onPress={() => setRating(star)}
                style={({ pressed }) => [styles.starButton, pressed && styles.pressed]}
              >
                <MIcon name={star <= rating ? "star" : "star-outline"} size={32} color="#F0A202" />
              </Pressable>
            ))}
          </View>

          <View style={styles.buttonRow}>
            <ActionButton
              label="فيسبوك"
              icon="facebook"
              onPress={() => openReviewLink(reviewLinks.facebook)}
              variant="secondary"
              disabled={!activePaymentPaid}
            />
            <ActionButton
              label="جوجل ماب"
              icon="google-maps"
              onPress={() => openReviewLink(reviewLinks.googleMaps)}
              variant="primary"
              disabled={!activePaymentPaid}
            />
          </View>
        </View>
      </ScrollView>
    );
  }

  function renderActiveTab() {
    switch (activeTab) {
      case "orders":
        return renderOrders();
      case "tracking":
        return renderTracking();
      case "invoice":
        return renderInvoice();
      case "payment":
        return renderPayment();
      case "reviews":
        return renderReviews();
      case "home":
      default:
        return renderHome();
    }
  }

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar style="dark" />
      <View style={styles.appShell}>
        {renderActiveTab()}
        <View style={styles.bottomTabs}>
          <TabButton tab="home" activeTab={activeTab} icon="home-outline" label="الرئيسية" onPress={setActiveTab} />
          <TabButton tab="orders" activeTab={activeTab} icon="clipboard-list-outline" label="الطلبات" onPress={setActiveTab} />
          <TabButton tab="tracking" activeTab={activeTab} icon="timeline-check-outline" label="الصيانة" onPress={setActiveTab} />
          <TabButton tab="payment" activeTab={activeTab} icon="cash-check" label="الدفع" onPress={setActiveTab} />
          <TabButton tab="reviews" activeTab={activeTab} icon="star-outline" label="التقييم" onPress={setActiveTab} />
        </View>
      </View>

      <RequestModal
        service={selectedService}
        draft={draft}
        isSubmitting={isSubmitting}
        onChange={updateDraft}
        onSubmit={submitRequest}
        onClose={() => setSelectedService(null)}
      />
    </SafeAreaView>
  );
}


