import { Text, View } from "react-native";
import { stages } from "../../data/maintenance";
import { styles } from "../../styles/appStyles";
import { MIcon } from "../common/MIcon";
import { StatusPill } from "../common/ui";

export function StageTimeline({ currentIndex }: { currentIndex: number }) {
  return (
    <View style={styles.timeline}>
      {stages.map((stage, index) => {
        const done = index < currentIndex;
        const current = index === currentIndex;
        const future = index > currentIndex;

        return (
          <View key={stage.title} style={styles.timelineRow}>
            <View style={styles.timelineRail}>
              <View
                style={[
                  styles.timelineDot,
                  done && styles.timelineDotDone,
                  current && styles.timelineDotCurrent,
                  future && styles.timelineDotFuture
                ]}
              >
                {done && <MIcon name="check" size={13} color="#FFFFFF" />}
              </View>
              {index !== stages.length - 1 && (
                <View style={[styles.timelineLine, index < currentIndex && styles.timelineLineDone]} />
              )}
            </View>
            <View style={styles.timelineCopy}>
              <View style={styles.timelineTitleRow}>
                <Text style={[styles.timelineTitle, current && styles.timelineTitleCurrent]}>{stage.title}</Text>
                {current && <StatusPill label="الآن" tone="good" />}
              </View>
              <Text style={styles.timelineBody}>{stage.body}</Text>
            </View>
          </View>
        );
      })}
    </View>
  );
}
