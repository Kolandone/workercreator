## اسکریپت مدیریت ورکر کلودفلر با ترموکس 
## Cloudflare worker management script with Termux 
---

### برای نصب این ورکر میتونید با استفاده از اسکریپت سلکتور و گزینه ۷ نصب و اجراش کنید ، بعد از نصب اولیه با استفاده از گزینه ۸ میتونید اجراش کنید
#### درتمام مراحل نصب و استفاده فیلترشکن شما باید روشن باشه
ا### اسکریپت سلکتور :

```
bash <(curl -fsSL https://raw.githubusercontent.com/Kolandone/Selector/main/Sel.sh)
```

---
## قابلیت ها :
### ۱ - مشاهده لیست ورکر ها و در صورت نیاز دریافت لینک مشاهده ورکر
### ۲ - حذف ورکر مورد نظر
### ۳ - ساخت ورکر با اسم دلخواه ، ساخت kv با اسم دلخواه ، اضافه کردن بایندیگ بین kv و ورکر با variable دلخواه ، منتشر کردن (publish) ورکر روی ساب دامین workers.dev و ارائه visit link ورکر
