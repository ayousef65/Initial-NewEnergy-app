import type { ServiceItem } from "../types/app";

export const services: ServiceItem[] = [
  {
    id: "maintenance",
    title: "حجز الصيانة",
    description: "موعد مركز الخدمة مع تشخيص وفحص شامل.",
    icon: "car-wrench",
    color: "#157A6E",
    tint: "#E0F3EF",
    priorityOptions: ["عادي", "قريب", "عاجل"]
  },
  {
    id: "home-visit",
    title: "طلب زيارة منزلية",
    description: "فني يصل للعميل للفحص أو التركيب.",
    icon: "home-map-marker",
    color: "#315C9A",
    tint: "#E7EEF9",
    priorityOptions: ["عادي", "قريب", "عاجل"]
  },
  {
    id: "emergency-visit",
    title: "طلب زيارة طوارئ",
    description: "استجابة سريعة للأعطال المفاجئة.",
    icon: "alert-circle-outline",
    color: "#C84630",
    tint: "#FBE8E4",
    priorityOptions: ["طوارئ", "فوري", "أقرب فني"]
  },
  {
    id: "spare-parts",
    title: "شراء قطعة غيار",
    description: "طلب قطع أصلية أو بدائل معتمدة.",
    icon: "cog-outline",
    color: "#8E5A00",
    tint: "#FFF0CF",
    priorityOptions: ["عرض سعر", "متوفر الآن", "طلب خاص"]
  },
  {
    id: "charger-accessory",
    title: "شراء شاحن أو اكسسوار",
    description: "شواحن منزلية، كابلات، ومحولات.",
    icon: "ev-plug-type2",
    color: "#5D58A6",
    tint: "#ECEBFA",
    priorityOptions: ["عرض سعر", "تركيب", "استلام"]
  },
  {
    id: "tow",
    title: "طلب ونش طوارئ",
    description: "نقل السيارة لأقرب مركز خدمة.",
    icon: "tow-truck",
    color: "#0F6B7A",
    tint: "#E0F2F5",
    priorityOptions: ["فوري", "خلال ساعة", "حسب المتاح"]
  }
];
