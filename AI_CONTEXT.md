Status: Verified
Last Updated: 2026-08-30
Source: Codebase inspection

# AI Context - ApliBhaji Admin App

This document provides a quick reference guide for AI coding agents to navigate the admin codebase efficiently and maintain system architecture constraints.

---

## 1. Project Identity

- **Framework**: Flutter (Targeting Android, iOS, Desktop)
- **Backend**: Supabase (PostgreSQL Database, Realtime, Auth, RPC)
- **State Management**: Riverpod (StateNotifierProvider, StreamProvider, FutureProvider)
- **Local Database**: SQLite (`sqflite` for mobile, `sqflite_common_ffi` for desktop)
- **Architecture**: Synchronous database updates with live Supabase upserting and local SQLite fallback

---

## 2. Navigation Architecture

- **Main Screen**: [`lib/features/dashboard/main_navigation_shell.dart`](file:///C:/Users/ojast/Downloads/37/aplibhaji_admin/lib/features/dashboard/main_navigation_shell.dart)
- **Home Navigation (Bottom Bar)**: Shows **Dashboard** and **Orders** for quick store operations.
- **Top-Left 3-Dot Menu & Drawer**: Quick navigation to **Products**, **Areas & Routes**, **Categories**, **Customers**, **Delivery & Settings**, **Notifications**, **Dashboard**, and **Orders**.

---

## 3. Delivery & Store Settings

- **Settings Screen**: [`lib/features/settings/settings_screen.dart`](file:///C:/Users/ojast/Downloads/37/aplibhaji_admin/lib/features/settings/settings_screen.dart)
- **Settings State Provider**: [`lib/features/settings/settings_provider.dart`](file:///C:/Users/ojast/Downloads/37/aplibhaji_admin/lib/features/settings/settings_provider.dart)
- **Key Setting Keys**:
  - `delivery_charge`: Standard Home Delivery Fee (₹)
  - `free_delivery_threshold`: Standard Free Delivery Minimum Amount (₹)
  - `order_now_delivery_charge`: Quick Order (Order Now) Delivery Fee (₹)
  - `order_now_free_delivery_threshold`: Quick Order Free Delivery Minimum (₹)
  - `order_now_status`: Store status for Quick Order (`open`, `coming_soon`, `closed`)
  - `store_name`: Store Name
  - `store_phone`: Store Phone Number
  - `store_address`: Store Physical Address
