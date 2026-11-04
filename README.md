# منصة التوظيف — نظام المصادقة والصلاحيات

المشروع مؤسس باستخدام Next.js App Router وTypeScript وSupabase Auth/PostgreSQL وRLS وZod وVitest.

## التشغيل
1. استخدم Node.js 20.9 أو أحدث.
2. انسخ `.env.example` إلى `.env.local` وأدخل عنوان Supabase ومفتاح Publishable.
3. نفّذ `npm install` ثم `npm run dev`.
4. الفحوصات: `npm run typecheck` و`npm test`.

لا تضع مفاتيح `service_role` أو `sb_secret_*` في المستودع أو متغيرات `NEXT_PUBLIC_*`.

## الأدوار
candidate وcompany وrecruiter وadmin. يمنح التسجيل العام دور candidate فقط. لا يُسمح بإسناد admin من بيانات المستخدم.

## قاعدة البيانات
راجع `supabase/migrations`. تحتوي على users وroles وpermissions وuser_roles وrole_permissions وsessions وrefresh_tokens وauth_attempts. جداول refresh_tokens وauth_attempts بلا سياسات للمستخدمين العاديين، لذا الوصول إليها مرفوض افتراضيًا.

## نقاط API
POST /api/v1/auth/register, /login, /logout, /forgot-password, /reset-password; GET /api/v1/auth/verify-email; GET /api/v1/me, /me/roles, /me/permissions.

## ملاحظات أمنية
يستخدم النظام Supabase Auth لتدوير وإبطال Refresh Tokens. جدول refresh_tokens يحفظ بصمة فقط ولا يخزن التوكن الخام. جدول sessions سجل وصفي ولا يحل محل جلسات Supabase. تحديد معدل محاولات الدخول يحتاج خدمة تخزين ذرية موثوقة قبل الإنتاج. يجب ضبط SMTP وروابط إعادة التوجيه في لوحة Supabase.