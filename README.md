# 🚀 Pir-Gost-Legendary
A master-class, multi-instance GOST tunneling script with advanced Linux kernel optimization, Watchdog sentry, and Anti-DPI features

##  Gost Tunnel description
A powerful, modular, and feature-rich Bash script designed to deploy, manage, and optimize multi-instance secure network tunnels using Gost Core. It provides an intuitive terminal UI to establish low-latency, stable, and highly customizable tunnels between servers with enterprise-grade network tuning.


### Fast Setup 
```bash
bash <(curl -sL https://raw.githubusercontent.com/PirMorshed/Pir-Gost-Legendary/main/Pir-Gost-Legendary.sh)
```


### نصب سریع اسکریپت
```bash
bash <(curl -sL https://raw.githubusercontent.com/PirMorshed/Pir-Gost-Legendary/main/Pir-Gost-Legendary.sh)
```


## نکته
> [!IMPORTANT]
> "This version has been customized and exclusively developed for PirMorshed."
> 
> «این نسخه سفارشی‌سازی شده و منحصراً برای پیر مرشد توسعه داده شده است.»


## 
 ## 🛠 ابزارهای بهینه‌سازی داخلی (Feature Toggles)
 ### در زمان نصب و پیکربندی هر نمونه (Instance)، می‌توانید ۶ قابلیت کلیدی زیر را به دلخواه خود فعال یا غیرفعال کنید:

قابلیت TCP Keepalive: پایدار نگه داشتن کانکشن‌های فعال و جلوگیری از قطع شدن زودهنگام ارتباط سرورها.

پشتیبانی از MPTCP (Multipath TCP): امکان استفاده هم‌زمان از چند مسیر شبکه برای افزایش پهنای باند و پایداری.

قابلیت TCP Nodelay: غیرفعال کردن الگوریتم Nagle جهت ارسال آنی پکت‌ها و کاهش محسوس تأخیر شبکه.

تنظیم UDP TTL (Gaming Fix): بهینه‌سازی و اصلاح ساختار پکت‌های UDP جهت بهبود چشمگیر پینگ و رفع مشکلات ریجستر تیر در بازی‌های آنلاین.

بهینه‌سازی حافظه (Memory Optimization): تنظیم خودکار مقدار GOGC=20 جهت مدیریت هوشمند و کاهش چشمگیر مصرف رم سرور توسط هسته گو‌لانگ.

سیستم رفع فیلتر Anti-DPI Refresh: راه‌اندازی مجدد خودکار و نامحسوس تونل در فواصل ۳۰ دقیقه‌ای (RuntimeMaxSec=1800) جهت تغییر کانکشن‌ها و دور زدن سیستم‌های فیلترینگ هوشمند (DPI).  




## ✨ Key FeaturesSmart

Target Management: Save, manage, and switch between multiple destination IPs effortlessly without losing order. Quick-select pre-configured Cloudflare HTTP/HTTPS ports or enter custom port ranges.  11 Transport Protocols Supported: Deploy tunnels using advanced protocols including relay+mtls, relay+grpc, relay+quic, relay+wss, relay+mwss, and more.  Kernel & Network Optimizer: Automatically applies Linux kernel tuning for speed and low ping, including BBR activation, TCP Fast Open ($tcp\_fastopen=3$), and optimized UDP/TCP buffer sizes.  Multi-Instance Dashboard: Seamlessly create, edit, restart, view real-time logs, or perform a deep/root cleanup delete for multiple separate tunnel instances simultaneously.  Pir Sentry (Watchdog): Built-in automated cron-job monitoring system that performs health checks every minute and revives dead tunnel instances instantly.  Anti-DPI & Resource Friendly: Includes a Go-runtime memory optimization toggle (GOGC=20) to save RAM, and an optional 30-minute anti-DPI automated refresh system to bypass deep packet inspection blocks.  Nuclear Uninstaller: Cleanly wipes all instances, cron jobs, configurations, and core binaries with a single click.  

## 🛠 Advanced Feature TogglesWhen

deploying an instance, you can dynamically toggle the following network enhancements:  
TCP Keepalive: Keeps the underlying connection alive and responsive.  
MPTCP Support: Enables Multipath TCP for multi-route performance.  
TCP Nodelay: Disables Nagle's algorithm for immediate packet transmission.  
UDP TTL Fix: Optimized packet routing tailored to fix high ping in online gaming.


## Stargazers over time
[![Stargazers over time](https://starchart.cc/PirMorshed/Pir-Gost-Legendary.svg?background=%23d0d0d0&axis=%23161616&line=%230c00f2)](https://starchart.cc/PirMorshed/Pir-Gost-Legendary)

                    
