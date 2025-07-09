# 📦 FiveM Standalone Inventory System

A modern, flexible **inventory system** for FiveM that works **standalone**, supports **dynamic item slots**, and is compatible with both **MySQL** and **MongoDB**.

---

## 🌟 Features

- ✅ **Standalone**: No dependency on ESX, QBCore, or other frameworks.
- 🔁 **Dual database support**: Works with both MySQL and MongoDB.
- 📦 **Dynamic item slots**: Customizable slot limits per inventory.
- 🎯 **Fast slots**: Assign and use quick-access slots with hotkeys.
- 🧠 **Smart UI**: Drag & drop interface via NUI (requires frontend).
- 📤 **Ground drops**: Support for dropping and picking up items in the world.
- 🔒 **Server-side validation**: Protection against cheating or spoofing.

---

## 🔧 Installation

### 1. Download and place the resource
Put the folder (e.g., `r01_inventory`) in your `resources/` directory.

### 2. Add it to `server.cfg`
```cfg
ensure r01_inventory
