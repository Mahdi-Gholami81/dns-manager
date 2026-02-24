# 🌐 DNS Manager

A simple PowerShell tool to manage DNS settings on Windows.

---
<p align="center">
  <img src="./assets/demo.jpg" alt="DNS Manager Banner" width="100%">
</p>

## ✨ Features

- **Select & Set DNS** – Apply saved DNS servers to all active adapters
- **Add DNS** – Add custom DNS entries to the list
- **Flush DNS** – Clear DNS cache
- **Reset DNS** – Revert to default (DHCP/Automatic)

---

## 🚀 Usage

1. Right-click `dns-manager.ps1` → **Run with PowerShell**
2. Accept the administrator prompt
3. Choose an option from the menu

---

## 📁 DNS List Format (`servers.ini`)

```ini
Google=8.8.8.8,8.8.4.4
Cloudflare=1.1.1.1,1.0.0.1
Shecan=178.22.122.100,185.51.200.2

    You can edit this file manually or add entries through the app (Option 2).```
---

## ⚠️ Requirements

    Windows 10/11
    PowerShell 5.1+
    Administrator privileges (auto-requested)

## 📜 License

MIT License
<p align="center">Made with ❤️ using PowerShell</p> 