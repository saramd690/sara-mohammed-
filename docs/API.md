# واجهات API

جميع الردود بصيغة موحدة: `{ success, data, error }`.

| الطريقة | المسار | الوظيفة |
|---|---|---|
| POST | /api/v1/auth/register | إنشاء حساب candidate |
| POST | /api/v1/auth/login | تسجيل الدخول وتسجيل بيانات الجلسة |
| POST | /api/v1/auth/logout | إنهاء الجلسة وإبطال سجلها المحلي |
| POST | /api/v1/auth/forgot-password | إرسال رابط الاستعادة |
| POST | /api/v1/auth/reset-password | تحديث كلمة المرور عبر جلسة استعادة موثقة |
| POST | /api/v1/auth/change-password | تغيير كلمة المرور لمستخدم مسجل |
| GET/POST | /api/v1/auth/verify-email | تفعيل البريد باستخدام token_hash |
| GET | /api/v1/me | بيانات المستخدم وتحديث آخر نشاط للجلسة |
| GET | /api/v1/me/roles | أدوار المستخدم الحالي |
| GET | /api/v1/me/permissions | صلاحيات المستخدم الحالي |
| POST | /api/v1/mock/login | هوية تجريبية في بيئة التطوير فقط |

رموز HTTP: 200 نجاح، 201 إنشاء، 400 مدخلات غير صحيحة، 401 غير مسجل، 403 غير مصرح، 500 خطأ داخلي.