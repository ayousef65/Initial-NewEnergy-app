import { ActivityIndicator, Pressable, Text, View } from "react-native";
import type { WordpressProduct } from "../../api/wordpress";
import { styles } from "../../styles/appStyles";
import type { ApiState, ServiceItem, ServiceRequest } from "../../types/app";
import { MIcon } from "../common/MIcon";
import { ActionButton, InfoItem, StatusPill } from "../common/ui";

export function ServiceCard({ item, onPress }: { item: ServiceItem; onPress: () => void }) {
  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [styles.serviceCard, { borderTopColor: item.color }, pressed && styles.pressed]}
    >
      <View style={[styles.serviceIcon, { backgroundColor: item.tint }]}>
        <MIcon name={item.icon} size={28} color={item.color} />
      </View>
      <Text style={styles.serviceTitle}>{item.title}</Text>
      <Text style={styles.serviceDescription}>{item.description}</Text>
    </Pressable>
  );
}

export function RequestCard({
  request,
  onTrack,
  onInvoice
}: {
  request: ServiceRequest;
  onTrack: () => void;
  onInvoice: () => void;
}) {
  return (
    <View style={styles.card}>
      <View style={styles.cardTopRow}>
        <View style={styles.requestTitleBlock}>
          <Text style={styles.cardTitle}>{request.title}</Text>
          <Text style={styles.cardMeta}>{request.id} - {request.createdAt}</Text>
        </View>
        <StatusPill label={request.status} tone="warn" />
      </View>
      <View style={styles.infoGrid}>
        <InfoItem icon="car-electric" label="السيارة" value={request.vehicle || "غير محدد"} />
        <InfoItem icon="map-marker-outline" label="الموقع" value={request.location || "غير محدد"} />
        <InfoItem icon="flash-outline" label="الأولوية" value={request.priority} />
      </View>
      {!!request.notes && <Text style={styles.requestNotes}>{request.notes}</Text>}
      <View style={styles.buttonRow}>
        <ActionButton label="متابعة" icon="timeline-check-outline" onPress={onTrack} variant="secondary" />
        <ActionButton label="الفاتورة" icon="receipt-text-outline" onPress={onInvoice} variant="ghost" />
      </View>
    </View>
  );
}

export function ConnectionBanner({ state, message }: { state: ApiState; message: string }) {
  const connected = state === "connected";
  const checking = state === "checking";
  const local = state === "local";

  return (
    <View
      style={[
        styles.connectionBanner,
        connected && styles.connectionBannerConnected,
        !connected && !checking && styles.connectionBannerWarning
      ]}
    >
      <View style={styles.connectionIcon}>
        {checking ? (
          <ActivityIndicator size="small" color="#157A6E" />
        ) : (
          <MIcon
            name={connected ? "cloud-check-outline" : local ? "cloud-off-outline" : "cloud-alert-outline"}
            size={22}
            color={connected ? "#157A6E" : "#8E5A00"}
          />
        )}
      </View>
      <View style={styles.connectionCopy}>
        <Text style={styles.connectionTitle}>
          {connected ? "WordPress متصل" : checking ? "فحص WordPress" : "وضع محلي"}
        </Text>
        <Text style={styles.connectionText}>{message}</Text>
      </View>
    </View>
  );
}

export function ProductRow({ product, onPress }: { product: WordpressProduct; onPress: () => void }) {
  const rawPrice = Number(product.prices?.price ?? 0);
  const minorUnit = product.prices?.currency_minor_unit ?? 2;
  const visiblePrice =
    rawPrice > 0
      ? `${product.prices?.currency_symbol ?? ""}${(rawPrice / Math.pow(10, minorUnit)).toLocaleString("en-US")}`
      : "من المتجر";

  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [styles.productRow, pressed && styles.pressed]}
    >
      <View style={styles.productIcon}>
        <MIcon name="shopping-outline" size={22} color="#315C9A" />
      </View>
      <View style={styles.productCopy}>
        <Text style={styles.productName} numberOfLines={2}>{product.name}</Text>
        <Text style={styles.productMeta}>{visiblePrice}</Text>
      </View>
      <MIcon name="open-in-new" size={19} color="#65717A" />
    </Pressable>
  );
}
