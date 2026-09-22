import { describe, expect, test } from "@jest/globals";
import {
  getMaintenanceStageIndex,
  localizeRepairStatus,
  localizeStatus
} from "../formatting";

describe("status formatting", () => {
  test("localizes known request and repair statuses", () => {
    expect(localizeStatus("inspection")).toBe("الفحص الفني");
    expect(localizeRepairStatus("fixed")).toBe("تم الإصلاح");
  });

  test("preserves unknown statuses for forward compatibility", () => {
    expect(localizeStatus("awaiting_customer")).toBe("awaiting_customer");
    expect(localizeRepairStatus("custom_status")).toBe("custom_status");
  });

  test("maps maintenance states to timeline positions", () => {
    expect(getMaintenanceStageIndex("تم التسجيل")).toBe(0);
    expect(getMaintenanceStageIndex("اختبار الجودة")).toBe(4);
    expect(getMaintenanceStageIndex("تم السداد")).toBe(5);
  });
});
