# راه‌اندازی کلانتر سه‌نفره روی Railway

این نسخه باید در **Project جداگانه** از برنامه دو نفره Deploy شود.

## سرویس‌ها

در Railway یک Project جدید بساز:

- سرویس برنامه: `kalantar-three-person`
- سرویس دیتابیس: `Postgres`

برای ماندگاری فایل‌ها روی سرویس برنامه یک Volume با Mount Path زیر بساز:

`/data/media`

بدون Volume، فایل‌های آپلودی ممکن است با redeploy از filesystem موقت حذف شوند.

## Variables سرویس برنامه

```env
NODE_ENV=production
DATABASE_URL=${{Postgres.DATABASE_URL}}
JWT_SECRET=یک_رشته_تصادفی_خیلی_طولانی
CORS_ORIGIN=*
MAX_UPLOAD_MB=25
MEDIA_DIR=/data/media
SHARED_ROOM_KEY=kalantar-anonymous-room
ROOM_CODE_TTL_HOURS=24
PERSON1_PASSWORD=رمز-ناشناس-A
PERSON2_PASSWORD=رمز-ناشناس-B
PERSON3_PASSWORD=رمز-ناشناس-C
```

`PERSON1_LABEL` و `PERSON2_LABEL` و `PERSON3_LABEL` لازم نیستند؛ سرور همیشه برچسب عمومی `ناشناس` را نگه می‌دارد.

`PORT` را دستی تعیین نکن؛ Railway آن را فراهم می‌کند.

## Healthcheck

مسیر پیشنهادی:

`/api/health`

بعد از Deploy باید پاسخی شبیه این ببینی:

```json
{"ok":true,"service":"kalantar-three-person","time":"..."}
```

## Domain

در سرویس برنامه از مسیر `Settings → Networking → Public Networking` یک Domain بساز.

آدرس حاصل را هنگام ساخت APK داخل برنامه ثابت کن:

```bash
flutter build apk --release --dart-define=KALANTAR_API_URL=https://YOUR-KALANTAR-DOMAIN.up.railway.app
```

در این حالت کاربر لازم نیست آدرس Railway را در برنامه وارد کند.

## سه ورود ناشناس

سه رمز بالا به سه کلید داخلی وصل هستند:

- `person1` → کلید ناشناس A
- `person2` → کلید ناشناس B
- `person3` → کلید ناشناس C

در چت و نمای اشتراکی، شناسه داخلی یا نام این کلیدها نشان داده نمی‌شود.

## ماندگاری رسانه

عکس، صدای ضبط‌شده، فایل صوتی و آهنگ در جدول `media` ثبت و فایل روی `/data/media` ذخیره می‌شود. Volume را دقیقاً روی همین مسیر قرار بده.
