# Kalantar Three-Person Server

سرور مستقل نسخه سه‌نفره «کلانتر» با Express + Socket.IO + PostgreSQL.

## ویژگی‌ها
- سه کلید احراز داخلی: `person1` / `person2` / `person3`
- برچسب عمومی کاربران همیشه `ناشناس` است.
- پیام‌ها، رسانه‌ها و دفتر مشترک بر اساس Room مشترک نگهداری می‌شوند.
- وضعیت احساسات و نیازهای فعلی هر دستگاه در PostgreSQL ثبت و فقط به صورت شمارش جمعی برگردانده می‌شود.
- عکس، صدا، آهنگ و فایل روی filesystem سرور ذخیره می‌شود.

## اجرای محلی

```bash
npm install
node src/server.js
```

متغیرهای لازم:
- `DATABASE_URL`
- `JWT_SECRET`
- `PERSON1_PASSWORD`
- `PERSON2_PASSWORD`
- `PERSON3_PASSWORD`

برای تولید، `MEDIA_DIR=/data/media` قرار بده و روی Railway یک Volume با همین Mount Path بساز.
