declare const process: {
  env?: Record<string, string | undefined>;
};

const env = process.env ?? {};

export const WORDPRESS_BASE_URL = (
  env.EXPO_PUBLIC_WORDPRESS_BASE_URL ?? "https://newenergyeg.com"
).replace(/\/$/, "");

export const WORDPRESS_APP_TOKEN = env.EXPO_PUBLIC_NEWENERGY_APP_TOKEN ?? "";

export const IS_WORDPRESS_CONFIGURED = WORDPRESS_APP_TOKEN.trim().length > 0;

export const REVIEW_LINKS = {
  facebook: env.EXPO_PUBLIC_FACEBOOK_REVIEW_URL ?? "https://www.facebook.com/newenergyeg",
  googleMaps:
    env.EXPO_PUBLIC_GOOGLE_MAPS_REVIEW_URL ??
    "https://www.google.com/maps/search/?api=1&query=New%20Energy%20Egypt"
};
