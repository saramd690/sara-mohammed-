# واجهات API

كل الاستجابات بصيغة { success, data, error }.

| الطريقة | المسار | الوظيفة |
|---|---|---|
| POST | /api/v1/auth/register | إنشاء حساب candidate وتفعيل البريد |
| POST | /api/v1/auth/login | تسجيل الدخول |
| POST | /api/v1/auth/logout | إنهاء الجلسة |
| POST | /api/v1/auth/forgot-password | إرسال رابط الاستعادة |
| POST | /api/v1/auth/reset-password | تحديث كلمة المرور بعد التحقق |
| GET | /api/v1/auth/verify-email | التحقق من token_hash وtype |
| GET | /api/v1/me | بيانات المستخدم الحالي |
| GET | /api/v1/me/roles | أدوار المستخدم |
| GET | /api/v1/me/permissions | صلاحيات المستخدم |

رموز HTTP: 200 نجاح، 201 إنشاء، 400 مدخلات غير صحيحة، 401 غير مسجل، 403 غير مصرح، 500 خطأ داخلي.
