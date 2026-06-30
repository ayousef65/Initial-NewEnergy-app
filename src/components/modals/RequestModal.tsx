import { KeyboardAvoidingView, Modal, Platform, Pressable, ScrollView, Text, View } from "react-native";
import { styles } from "../../styles/appStyles";
import type { RequestDraft, ServiceItem } from "../../types/app";
import { MIcon } from "../common/MIcon";
import { ActionButton, Field } from "../common/ui";

export function RequestModal({
  service,
  draft,
  isSubmitting,
  onChange,
  onSubmit,
  onClose
}: {
  service: ServiceItem | null;
  draft: RequestDraft;
  isSubmitting: boolean;
  onChange: (key: keyof RequestDraft, value: string) => void;
  onSubmit: () => void | Promise<void>;
  onClose: () => void;
}) {
  return (
    <Modal visible={!!service} animationType="slide" transparent onRequestClose={onClose}>
      <KeyboardAvoidingView behavior={Platform.OS === "ios" ? "padding" : "height"} style={styles.modalOverlay}>
        <View style={styles.modalSheet}>
          <View style={styles.modalHandle} />
          <View style={styles.cardTopRow}>
            <View style={styles.requestTitleBlock}>
              <Text style={styles.modalTitle}>{service?.title}</Text>
              <Text style={styles.modalSubtitle}>{service?.description}</Text>
            </View>
            <Pressable accessibilityRole="button" onPress={onClose} style={styles.closeButton}>
              <MIcon name="close" size={22} color="#263238" />
            </Pressable>
          </View>
          <ScrollView
            contentContainerStyle={styles.modalContent}
            keyboardShouldPersistTaps="handled"
            showsVerticalScrollIndicator={false}
          >
            <Field label="الاسم" value={draft.customerName} onChangeText={(value) => onChange("customerName", value)} placeholder="اسم العميل" />
            <Field label="رقم الهاتف" value={draft.phone} onChangeText={(value) => onChange("phone", value)} placeholder="01000000000" keyboardType="phone-pad" />
            <Field label="نوع السيارة" value={draft.vehicle} onChangeText={(value) => onChange("vehicle", value)} placeholder="مثال: BYD / Tesla / Mercedes EQ" />
            <Field label="الموقع" value={draft.location} onChangeText={(value) => onChange("location", value)} placeholder="العنوان أو المنطقة" />
            <Field label="الموعد المفضل" value={draft.preferredDate} onChangeText={(value) => onChange("preferredDate", value)} placeholder="اليوم مساءً / غداً 11 ص" />
            <Text style={styles.fieldLabel}>الأولوية</Text>
            <View style={styles.segmented}>
              {service?.priorityOptions.map((option) => {
                const active = draft.priority === option;
                return (
                  <Pressable
                    key={option}
                    accessibilityRole="button"
                    onPress={() => onChange("priority", option)}
                    style={({ pressed }) => [styles.segment, active && styles.segmentActive, pressed && styles.pressed]}
                  >
                    <Text style={[styles.segmentText, active && styles.segmentTextActive]}>{option}</Text>
                  </Pressable>
                );
              })}
            </View>
            <Field label="تفاصيل إضافية" value={draft.notes} onChangeText={(value) => onChange("notes", value)} placeholder="اكتب المشكلة أو القطعة المطلوبة" multiline />
            <ActionButton
              label={isSubmitting ? "جاري الإرسال" : "تأكيد الطلب"}
              icon={isSubmitting ? "cloud-sync-outline" : "check-circle-outline"}
              onPress={onSubmit}
              disabled={isSubmitting}
            />
          </ScrollView>
        </View>
      </KeyboardAvoidingView>
    </Modal>
  );
}
