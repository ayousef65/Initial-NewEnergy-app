import { Platform, StyleSheet } from "react-native";

export const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: "#F6F7F9",
    paddingTop: Platform.OS === "android" ? 26 : 0,
    direction: "rtl"
  },
  appShell: {
    flex: 1,
    backgroundColor: "#F6F7F9"
  },
  scrollContent: {
    padding: 18,
    paddingBottom: 112,
    gap: 16
  },
  headerBand: {
    backgroundColor: "#FFFFFF",
    borderRadius: 8,
    padding: 18,
    borderWidth: 1,
    borderColor: "#E2E6EA",
    gap: 14
  },
  brandRow: {
    flexDirection: "row-reverse",
    justifyContent: "space-between",
    alignItems: "center"
  },
  brandText: {
    color: "#15232D",
    fontSize: 20,
    fontWeight: "800",
    textAlign: "right"
  },
  brandSubText: {
    color: "#65717A",
    fontSize: 13,
    marginTop: 2,
    textAlign: "right"
  },
  callButton: {
    width: 44,
    height: 44,
    borderRadius: 8,
    backgroundColor: "#C84630",
    alignItems: "center",
    justifyContent: "center"
  },
  heroTitle: {
    color: "#15232D",
    fontSize: 30,
    lineHeight: 38,
    fontWeight: "900",
    textAlign: "right"
  },
  heroText: {
    color: "#54616B",
    fontSize: 15,
    lineHeight: 23,
    textAlign: "right"
  },
  summaryStrip: {
    flexDirection: "row-reverse",
    alignItems: "stretch",
    borderWidth: 1,
    borderColor: "#E2E6EA",
    backgroundColor: "#FAFBFC",
    borderRadius: 8,
    overflow: "hidden"
  },
  summaryItem: {
    flex: 1,
    paddingVertical: 12,
    paddingHorizontal: 8,
    alignItems: "center",
    justifyContent: "center"
  },
  summaryItemWide: {
    flex: 1.4,
    paddingVertical: 12,
    paddingHorizontal: 8,
    alignItems: "center",
    justifyContent: "center"
  },
  summaryDivider: {
    width: 1,
    backgroundColor: "#E2E6EA"
  },
  summaryValue: {
    color: "#15232D",
    fontSize: 18,
    fontWeight: "800",
    textAlign: "center"
  },
  summaryValueSmall: {
    color: "#15232D",
    fontSize: 13,
    fontWeight: "800",
    textAlign: "center"
  },
  summaryLabel: {
    color: "#65717A",
    fontSize: 12,
    marginTop: 3,
    textAlign: "center"
  },
  sectionHeader: {
    flexDirection: "row-reverse",
    alignItems: "center",
    justifyContent: "space-between"
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: "800",
    color: "#15232D",
    textAlign: "right"
  },
  linkButton: {
    minHeight: 34,
    justifyContent: "center"
  },
  linkButtonText: {
    color: "#157A6E",
    fontSize: 14,
    fontWeight: "700"
  },
  serviceGrid: {
    flexDirection: "row-reverse",
    flexWrap: "wrap",
    gap: 12
  },
  serviceCard: {
    width: "48%",
    minHeight: 168,
    backgroundColor: "#FFFFFF",
    borderRadius: 8,
    borderWidth: 1,
    borderColor: "#E2E6EA",
    borderTopWidth: 4,
    padding: 14,
    gap: 10
  },
  serviceIcon: {
    width: 44,
    height: 44,
    borderRadius: 8,
    alignItems: "center",
    justifyContent: "center"
  },
  serviceTitle: {
    color: "#15232D",
    fontSize: 16,
    lineHeight: 22,
    fontWeight: "800",
    textAlign: "right"
  },
  serviceDescription: {
    color: "#65717A",
    fontSize: 13,
    lineHeight: 19,
    textAlign: "right"
  },
  card: {
    backgroundColor: "#FFFFFF",
    borderRadius: 8,
    borderWidth: 1,
    borderColor: "#E2E6EA",
    padding: 16,
    gap: 14
  },
  cardTopRow: {
    flexDirection: "row-reverse",
    alignItems: "flex-start",
    justifyContent: "space-between",
    gap: 12
  },
  requestTitleBlock: {
    flex: 1
  },
  cardTitle: {
    color: "#15232D",
    fontSize: 17,
    fontWeight: "800",
    lineHeight: 24,
    textAlign: "right"
  },
  cardMeta: {
    color: "#65717A",
    fontSize: 13,
    marginTop: 3,
    textAlign: "right"
  },
  cardBody: {
    color: "#54616B",
    fontSize: 14,
    lineHeight: 22,
    textAlign: "right"
  },
  statusPill: {
    borderRadius: 8,
    backgroundColor: "#EEF1F4",
    paddingHorizontal: 10,
    paddingVertical: 6,
    alignSelf: "flex-start"
  },
  statusText: {
    color: "#54616B",
    fontSize: 12,
    fontWeight: "800"
  },
  statusGood: {
    backgroundColor: "#E0F3EF"
  },
  statusGoodText: {
    color: "#157A6E"
  },
  statusWarn: {
    backgroundColor: "#FFF0CF"
  },
  statusWarnText: {
    color: "#8E5A00"
  },
  statusDanger: {
    backgroundColor: "#FBE8E4"
  },
  statusDangerText: {
    color: "#C84630"
  },
  progressTrack: {
    height: 8,
    backgroundColor: "#E6EAEE",
    borderRadius: 8,
    overflow: "hidden"
  },
  progressFill: {
    width: "48%",
    height: "100%",
    backgroundColor: "#157A6E",
    borderRadius: 8
  },
  buttonRow: {
    flexDirection: "row-reverse",
    gap: 10,
    alignItems: "center"
  },
  singleButtonRow: {
    flexDirection: "row-reverse",
    alignItems: "center"
  },
  actionButton: {
    minHeight: 48,
    flex: 1,
    borderRadius: 8,
    paddingHorizontal: 12,
    flexDirection: "row-reverse",
    alignItems: "center",
    justifyContent: "center",
    gap: 8
  },
  primaryButton: {
    backgroundColor: "#157A6E"
  },
  secondaryButton: {
    backgroundColor: "#315C9A"
  },
  dangerButton: {
    backgroundColor: "#C84630"
  },
  ghostButton: {
    backgroundColor: "#FFFFFF",
    borderWidth: 1,
    borderColor: "#D4DAE0"
  },
  buttonText: {
    color: "#FFFFFF",
    fontSize: 14,
    fontWeight: "800",
    textAlign: "center"
  },
  ghostButtonText: {
    color: "#263238",
    fontSize: 14,
    fontWeight: "800",
    textAlign: "center"
  },
  disabledButton: {
    backgroundColor: "#EEF1F4",
    borderColor: "#E2E6EA"
  },
  disabledButtonText: {
    color: "#87919A"
  },
  pressed: {
    opacity: 0.72
  },
  infoGrid: {
    gap: 10
  },
  infoItem: {
    flexDirection: "row-reverse",
    alignItems: "center",
    gap: 8
  },
  infoTextBlock: {
    flex: 1
  },
  infoLabel: {
    color: "#87919A",
    fontSize: 12,
    textAlign: "right"
  },
  infoValue: {
    color: "#263238",
    fontSize: 14,
    fontWeight: "700",
    textAlign: "right"
  },
  requestNotes: {
    color: "#54616B",
    fontSize: 14,
    lineHeight: 21,
    textAlign: "right"
  },
  connectionBanner: {
    flexDirection: "row-reverse",
    alignItems: "center",
    gap: 10,
    borderWidth: 1,
    borderColor: "#E2E6EA",
    backgroundColor: "#FFFFFF",
    borderRadius: 8,
    padding: 12
  },
  connectionBannerConnected: {
    borderColor: "#DCEFEA",
    backgroundColor: "#F3FBF8"
  },
  connectionBannerWarning: {
    borderColor: "#F5E1AE",
    backgroundColor: "#FFFBF0"
  },
  connectionIcon: {
    width: 38,
    height: 38,
    borderRadius: 8,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "#FFFFFF"
  },
  connectionCopy: {
    flex: 1
  },
  connectionTitle: {
    color: "#15232D",
    fontSize: 14,
    fontWeight: "900",
    textAlign: "right"
  },
  connectionText: {
    color: "#65717A",
    fontSize: 12,
    lineHeight: 18,
    marginTop: 2,
    textAlign: "right"
  },
  productList: {
    gap: 10
  },
  productRow: {
    minHeight: 74,
    flexDirection: "row-reverse",
    alignItems: "center",
    gap: 12,
    backgroundColor: "#FFFFFF",
    borderWidth: 1,
    borderColor: "#E2E6EA",
    borderRadius: 8,
    padding: 12
  },
  productIcon: {
    width: 42,
    height: 42,
    borderRadius: 8,
    backgroundColor: "#E7EEF9",
    alignItems: "center",
    justifyContent: "center"
  },
  productCopy: {
    flex: 1
  },
  productName: {
    color: "#15232D",
    fontSize: 14,
    lineHeight: 20,
    fontWeight: "800",
    textAlign: "right"
  },
  productMeta: {
    color: "#65717A",
    fontSize: 12,
    marginTop: 3,
    textAlign: "right"
  },
  screenHeading: {
    flexDirection: "row-reverse",
    alignItems: "center",
    gap: 12,
    backgroundColor: "#FFFFFF",
    borderRadius: 8,
    borderWidth: 1,
    borderColor: "#E2E6EA",
    padding: 16
  },
  screenIcon: {
    width: 48,
    height: 48,
    borderRadius: 8,
    backgroundColor: "#E0F3EF",
    alignItems: "center",
    justifyContent: "center"
  },
  screenHeadingCopy: {
    flex: 1
  },
  screenTitle: {
    color: "#15232D",
    fontSize: 23,
    lineHeight: 30,
    fontWeight: "900",
    textAlign: "right"
  },
  screenSubtitle: {
    color: "#65717A",
    fontSize: 14,
    lineHeight: 21,
    marginTop: 3,
    textAlign: "right"
  },
  timeline: {
    gap: 0
  },
  timelineRow: {
    flexDirection: "row-reverse",
    alignItems: "stretch",
    gap: 12
  },
  timelineRail: {
    width: 26,
    alignItems: "center"
  },
  timelineDot: {
    width: 24,
    height: 24,
    borderRadius: 12,
    alignItems: "center",
    justifyContent: "center",
    borderWidth: 2,
    borderColor: "#D4DAE0",
    backgroundColor: "#FFFFFF"
  },
  timelineDotDone: {
    backgroundColor: "#157A6E",
    borderColor: "#157A6E"
  },
  timelineDotCurrent: {
    borderColor: "#157A6E",
    backgroundColor: "#E0F3EF"
  },
  timelineDotFuture: {
    borderColor: "#D4DAE0"
  },
  timelineLine: {
    width: 2,
    flex: 1,
    minHeight: 52,
    backgroundColor: "#D4DAE0"
  },
  timelineLineDone: {
    backgroundColor: "#157A6E"
  },
  timelineCopy: {
    flex: 1,
    paddingBottom: 18
  },
  timelineTitleRow: {
    flexDirection: "row-reverse",
    alignItems: "center",
    justifyContent: "space-between",
    gap: 8
  },
  timelineTitle: {
    color: "#263238",
    fontSize: 15,
    fontWeight: "800",
    textAlign: "right",
    flex: 1
  },
  timelineTitleCurrent: {
    color: "#157A6E"
  },
  timelineBody: {
    color: "#65717A",
    fontSize: 13,
    lineHeight: 20,
    marginTop: 4,
    textAlign: "right"
  },
  repairRow: {
    flexDirection: "row-reverse",
    gap: 12,
    backgroundColor: "#FFFFFF",
    borderWidth: 1,
    borderColor: "#E2E6EA",
    borderRadius: 8,
    padding: 14
  },
  repairIcon: {
    width: 40,
    height: 40,
    borderRadius: 8,
    backgroundColor: "#E0F3EF",
    alignItems: "center",
    justifyContent: "center"
  },
  repairCopy: {
    flex: 1,
    gap: 5
  },
  repairIssue: {
    color: "#15232D",
    fontSize: 15,
    fontWeight: "800",
    textAlign: "right",
    flex: 1
  },
  repairFix: {
    color: "#54616B",
    fontSize: 13,
    lineHeight: 20,
    textAlign: "right"
  },
  reportBox: {
    borderWidth: 1,
    borderColor: "#DCEFEA",
    backgroundColor: "#F3FBF8",
    borderRadius: 8,
    padding: 14,
    gap: 6
  },
  reportTitle: {
    color: "#157A6E",
    fontSize: 15,
    fontWeight: "800",
    textAlign: "right"
  },
  reportText: {
    color: "#43515B",
    fontSize: 14,
    lineHeight: 22,
    textAlign: "right"
  },
  invoiceList: {
    borderTopWidth: 1,
    borderTopColor: "#E2E6EA"
  },
  invoiceRow: {
    flexDirection: "row-reverse",
    justifyContent: "space-between",
    gap: 12,
    borderBottomWidth: 1,
    borderBottomColor: "#E2E6EA",
    paddingVertical: 12
  },
  invoiceLabel: {
    color: "#43515B",
    fontSize: 14,
    textAlign: "right",
    flex: 1
  },
  invoiceAmount: {
    color: "#15232D",
    fontSize: 14,
    fontWeight: "800"
  },
  totalRow: {
    flexDirection: "row-reverse",
    justifyContent: "space-between",
    alignItems: "center",
    paddingTop: 4
  },
  totalLabel: {
    color: "#15232D",
    fontSize: 18,
    fontWeight: "900"
  },
  totalAmount: {
    color: "#157A6E",
    fontSize: 19,
    fontWeight: "900"
  },
  paymentPanel: {
    backgroundColor: "#15232D",
    borderRadius: 8,
    padding: 22,
    gap: 8
  },
  paymentAmount: {
    color: "#FFFFFF",
    fontSize: 34,
    lineHeight: 42,
    fontWeight: "900",
    textAlign: "right"
  },
  paymentCaption: {
    color: "#C9D3DA",
    fontSize: 14,
    lineHeight: 21,
    textAlign: "right"
  },
  methodGrid: {
    flexDirection: "row-reverse",
    flexWrap: "wrap",
    gap: 12
  },
  methodCard: {
    width: "48%",
    minHeight: 92,
    backgroundColor: "#FFFFFF",
    borderRadius: 8,
    borderWidth: 1,
    borderColor: "#E2E6EA",
    padding: 14,
    justifyContent: "center",
    alignItems: "center",
    gap: 8
  },
  methodCardActive: {
    borderColor: "#157A6E",
    backgroundColor: "#F3FBF8"
  },
  methodTitle: {
    color: "#54616B",
    fontSize: 14,
    fontWeight: "700",
    textAlign: "center"
  },
  methodTitleActive: {
    color: "#157A6E",
    fontWeight: "900"
  },
  reviewHeader: {
    flexDirection: "row-reverse",
    gap: 12,
    alignItems: "center"
  },
  reviewHeaderCopy: {
    flex: 1
  },
  starRow: {
    flexDirection: "row-reverse",
    justifyContent: "center",
    gap: 6,
    paddingVertical: 4
  },
  starButton: {
    width: 44,
    height: 44,
    borderRadius: 8,
    alignItems: "center",
    justifyContent: "center"
  },
  bottomTabs: {
    position: "absolute",
    bottom: 0,
    left: 0,
    right: 0,
    flexDirection: "row-reverse",
    backgroundColor: "#FFFFFF",
    borderTopWidth: 1,
    borderTopColor: "#DDE3E8",
    paddingHorizontal: 8,
    paddingTop: 8,
    paddingBottom: Platform.OS === "ios" ? 22 : 10,
    gap: 4
  },
  tabButton: {
    flex: 1,
    minHeight: 56,
    borderRadius: 8,
    alignItems: "center",
    justifyContent: "center",
    gap: 3
  },
  tabButtonActive: {
    backgroundColor: "#E0F3EF"
  },
  tabLabel: {
    color: "#65717A",
    fontSize: 11,
    fontWeight: "700",
    textAlign: "center"
  },
  tabLabelActive: {
    color: "#157A6E",
    fontWeight: "900"
  },
  modalOverlay: {
    flex: 1,
    justifyContent: "flex-end",
    backgroundColor: "rgba(20, 28, 34, 0.42)"
  },
  modalSheet: {
    maxHeight: "92%",
    backgroundColor: "#FFFFFF",
    borderTopLeftRadius: 8,
    borderTopRightRadius: 8,
    paddingHorizontal: 18,
    paddingTop: 10,
    paddingBottom: Platform.OS === "ios" ? 24 : 16
  },
  modalHandle: {
    width: 48,
    height: 5,
    borderRadius: 8,
    backgroundColor: "#D4DAE0",
    alignSelf: "center",
    marginBottom: 14
  },
  modalTitle: {
    color: "#15232D",
    fontSize: 20,
    lineHeight: 27,
    fontWeight: "900",
    textAlign: "right"
  },
  modalSubtitle: {
    color: "#65717A",
    fontSize: 13,
    lineHeight: 20,
    marginTop: 3,
    textAlign: "right"
  },
  closeButton: {
    width: 40,
    height: 40,
    borderRadius: 8,
    backgroundColor: "#EEF1F4",
    alignItems: "center",
    justifyContent: "center"
  },
  modalContent: {
    paddingTop: 16,
    gap: 12,
    paddingBottom: 48
  },
  field: {
    gap: 7
  },
  fieldLabel: {
    color: "#263238",
    fontSize: 13,
    fontWeight: "800",
    textAlign: "right"
  },
  input: {
    minHeight: 48,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: "#D4DAE0",
    backgroundColor: "#FAFBFC",
    color: "#15232D",
    fontSize: 15,
    paddingHorizontal: 12,
    textAlign: "right"
  },
  textArea: {
    minHeight: 96,
    paddingTop: 12,
    textAlignVertical: "top"
  },
  segmented: {
    flexDirection: "row-reverse",
    borderWidth: 1,
    borderColor: "#D4DAE0",
    borderRadius: 8,
    backgroundColor: "#FAFBFC",
    overflow: "hidden"
  },
  segment: {
    flex: 1,
    minHeight: 44,
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 8
  },
  segmentActive: {
    backgroundColor: "#157A6E"
  },
  segmentText: {
    color: "#54616B",
    fontSize: 13,
    fontWeight: "800",
    textAlign: "center"
  },
  segmentTextActive: {
    color: "#FFFFFF"
  }
});

