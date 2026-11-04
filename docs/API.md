# واجهات API

كل الردود بصيغة موحدة: `{ success, data, error }`.

| الطريقة | المسار | الوظيفة |
|---|---|---|
| POST | /api/v1/auth/register | إنشاء حساب candidate وتأكيد البريد |
| POST | /api/v1/auth/login | تسجيل الدخول مع حد المحاولات وتسجيل الجلسة |
| POST | /api/v1/auth/logout | إنهاء الجلسة وإبطال سجلها |
| POST | /api/v1/auth/forgot-password | إرسال رابط الاستعادة برسالة عامة لا تكشف وجود البريد |
| POST | /api/v1/auth/reset-password | تحديث كلمة المرور بعد تحقق رابط الاستعادة |
| POST | /api/v1/auth/change-password | تغيير كلمة المرور للمستخدم المسجل |
| GET/POST | /api/v1/auth/verify-email | تفعيل البريد باستخدام رمز Supabase |
| GET | /api/v1/me | بيانات المستخدم الحالي وتحديث نشاط الجلسة |
| GET | /api/v1/me/roles | أدوار المستخدم الحالي |
| GET | /api/v1/me/permissions | صلاحيات المستخدم الحالي |
| POST | /api/v1/admin/users/:userId/roles | إسناد دور؛ يتطلب roles:assign |
| DELETE | /api/v1/admin/users/:userId/roles | إزالة دور؛ يتطلب roles:assign |
| POST | /api/v1/mock/login | بيانات وهمية في التطوير فقط وليست جلسة حقيقية |

## إدارة الأدوار
يجب أن يكون المستخدم المنفذ حاملًا لصلاحية `roles:assign`. أول مسؤول للمنصة يُمنح الدور يدويًا بعد التحقق من هويته من خلال لوحة تحكم Supabase، وليس من واجهة التسجيل.

## رموز HTTP
200 نجاح، 201 إنشاء، 400 مدخلات غير صحيحة، 401 غير مسجل، 403 غير مصرح، 429 تجاوز حد المحاولات (مع ترويسة Retry-After)، 500/503 خطأ داخلي أو خدمة غير متاحة.
