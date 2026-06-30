import type { ReactNode } from "react";
import { Pressable, Text, TextInput, View, type KeyboardTypeOptions } from "react-native";
import { styles } from "../../styles/appStyles";
import type { TabKey } from "../../types/app";
import { MIcon } from "./MIcon";

export function SectionTitle({ title, action }: { title: string; action?: ReactNode }) {
  return (
    <View style={styles.sectionHeader}>
      <Text style={styles.sectionTitle}>{title}</Text>
      {action}
    </View>
  );
}

export function ActionButton({
  label,
  icon,
  onPress,
  variant = "primary",
  disabled = false
}: {
  label: string;
  icon: string;
  onPress: () => void | Promise<void>;
  variant?: "primary" | "secondary" | "danger" | "ghost";
  disabled?: boolean;
}) {
  const isGhost = variant === "ghost";

  return (
    <Pressable
      accessibilityRole="button"
      disabled={disabled}
      onPress={onPress}
      style={({ pressed }) => [
        styles.actionButton,
        variant === "primary" && styles.primaryButton,
        variant === "secondary" && styles.secondaryButton,
        variant === "danger" && styles.dangerButton,
        variant === "ghost" && styles.ghostButton,
        disabled && styles.disabledButton,
        pressed && !disabled && styles.pressed
      ]}
    >
      <MIcon name={icon} size={19} color={disabled ? "#87919A" : isGhost ? "#263238" : "#FFFFFF"} />
      <Text style={[isGhost ? styles.ghostButtonText : styles.buttonText, disabled && styles.disabledButtonText]}>
        {label}
      </Text>
    </Pressable>
  );
}

export function StatusPill({
  label,
  tone = "neutral"
}: {
  label: string;
  tone?: "neutral" | "good" | "warn" | "danger";
}) {
  return (
    <View
      style={[
        styles.statusPill,
        tone === "good" && styles.statusGood,
        tone === "warn" && styles.statusWarn,
        tone === "danger" && styles.statusDanger
      ]}
    >
      <Text
        style={[
          styles.statusText,
          tone === "good" && styles.statusGoodText,
          tone === "warn" && styles.statusWarnText,
          tone === "danger" && styles.statusDangerText
        ]}
      >
        {label}
      </Text>
    </View>
  );
}

export function InfoItem({ icon, label, value }: { icon: string; label: string; value: string }) {
  return (
    <View style={styles.infoItem}>
      <MIcon name={icon} size={18} color="#54616B" />
      <View style={styles.infoTextBlock}>
        <Text style={styles.infoLabel}>{label}</Text>
        <Text style={styles.infoValue}>{value}</Text>
      </View>
    </View>
  );
}

export function ScreenHeading({ title, subtitle, icon }: { title: string; subtitle: string; icon: string }) {
  return (
    <View style={styles.screenHeading}>
      <View style={styles.screenIcon}>
        <MIcon name={icon} size={28} color="#157A6E" />
      </View>
      <View style={styles.screenHeadingCopy}>
        <Text style={styles.screenTitle}>{title}</Text>
        <Text style={styles.screenSubtitle}>{subtitle}</Text>
      </View>
    </View>
  );
}

export function TabButton({
  tab,
  activeTab,
  icon,
  label,
  onPress
}: {
  tab: TabKey;
  activeTab: TabKey;
  icon: string;
  label: string;
  onPress: (tab: TabKey) => void;
}) {
  const active = tab === activeTab;

  return (
    <Pressable
      accessibilityRole="tab"
      onPress={() => onPress(tab)}
      style={({ pressed }) => [styles.tabButton, active && styles.tabButtonActive, pressed && styles.pressed]}
    >
      <MIcon name={icon} size={22} color={active ? "#157A6E" : "#65717A"} />
      <Text style={[styles.tabLabel, active && styles.tabLabelActive]}>{label}</Text>
    </Pressable>
  );
}

export function Field({
  label,
  value,
  onChangeText,
  placeholder,
  multiline = false,
  keyboardType = "default"
}: {
  label: string;
  value: string;
  onChangeText: (value: string) => void;
  placeholder: string;
  multiline?: boolean;
  keyboardType?: KeyboardTypeOptions;
}) {
  return (
    <View style={styles.field}>
      <Text style={styles.fieldLabel}>{label}</Text>
      <TextInput
        value={value}
        onChangeText={onChangeText}
        placeholder={placeholder}
        placeholderTextColor="#87919A"
        multiline={multiline}
        keyboardType={keyboardType}
        textAlign="right"
        style={[styles.input, multiline && styles.textArea]}
      />
    </View>
  );
}
