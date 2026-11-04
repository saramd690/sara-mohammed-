# منصة التوظيف — نظام المصادقة والصلاحيات

تأسيس باستخدام Next.js App Router وTypeScript وSupabase Auth/PostgreSQL وRLS وZod وVitest.

## التشغيل المحلي
1. استخدم Node.js 22.
2. انسخ `.env.example` إلى `.env.local`.
3. من إعدادات مشروع Supabase أدخل عنوان المشروع ومفتاح Publishable.
4. أضف `SUPABASE_SERVICE_ROLE_KEY` كمتغير خادم فقط، ولا تستخدم بادئة `NEXT_PUBLIC_` له.
5. أنشئ `AUTH_RATE_LIMIT_SECRET` عشوائيًا بطول 32 بايت على الأقل (مثل `openssl rand -hex 32`).
6. نفّذ `npm install` ثم `npm run dev`.
7. الفحوصات: `npm run typecheck` و`npm run lint` و`npm test` و`npm run build`.

## متغيرات البيئة
- `NEXT_PUBLIC_SUPABASE_URL`: عنوان مشروع Supabase.
- `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`: مفتاح Publishable.
- `SUPABASE_SERVICE_ROLE_KEY`: مفتاح خدمة سري للخادم فقط؛ لا تضعه في Git أو في متغيرات عامة.
- `AUTH_RATE_LIMIT_SECRET`: مفتاح HMAC مستقل عن مفاتيح Supabase.
- `NEXT_PUBLIC_MOCK_AUTH`: يفعّل بيانات العرض الوهمية في بيئة التطوير فقط؛ لا ينشئ جلسة Supabase فعلية.

## الأدوار والصلاحيات
الأدوار: `candidate` و`company` و`recruiter` و`admin`. التسجيل العام يمنح `candidate` فقط. توجد 17 صلاحية أولية. إسناد الأدوار متاح للمسؤول الذي يمتلك `roles:assign` فقط عبر API خادمي.

لإنشاء أول مدير، تحقق يدويًا من هوية المستخدم في لوحة Supabase ثم نفّذ في SQL Editor، مع استبدال UUID بمعرف المستخدم الصحيح:

```sql
insert into public.user_roles(user_id, role_id)
select 'AUTH_USER_UUID'::uuid, id from public.roles where name = 'admin'
on conflict do nothing;
```

## قاعدة البيانات
راجع `supabase/migrations`. الجداول: users وroles وpermissions وuser_roles وrole_permissions وsessions وrefresh_tokens وauth_attempts. كل الجداول مفعّل عليها RLS. الوصول إلى سجلات المحاولات ودفتر refresh_tokens محجوب عن المستخدمين.

Supabase Auth هو المصدر الفعلي لدورة حياة Access/Refresh Tokens والإلغاء. جدول `refresh_tokens` مهيأ كدفتر بصمات/تدقيق للتكامل المستقبلي، ولا يخزن التوكن الخام ولا يدير تدويره بنفسه.

## البريد الإلكتروني
اضبط SMTP وSite URL وRedirect URLs في Supabase. رابط العودة المحلي هو `http://localhost:3000/auth/callback`. أضف رابط callback المطابق لنطاق الإنتاج في إعدادات Auth قبل النشر.

## Rate Limiting
5 محاولات فاشلة لكل بريد و20 لكل IP موثوق خلال 15 دقيقة. يعتمد IP على ترويسة `x-real-ip` التي يجب أن يضبطها Reverse Proxy موثوق ويستبدل قيمتها الواردة من العميل. لا تنشر التطبيق مع تجاوز الوكيل الموثوق.

## CI
GitHub Actions ينفذ typecheck وlint والاختبارات والبناء الإنتاجي على الفرع المخصص.
