import { MaterialCommunityIcons } from "@expo/vector-icons";

type MaterialIconName = keyof typeof MaterialCommunityIcons.glyphMap;

export function MIcon({ name, size = 22, color = "#263238" }: { name: string; size?: number; color?: string }) {
  return <MaterialCommunityIcons name={name as MaterialIconName} size={size} color={color} />;
}
