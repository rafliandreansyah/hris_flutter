# 🎨 Design System & Global Theme Guide (Teal Oasis)

Aplikasi **Muratech HRIS (Oasish)** menggunakan sistem desain **"Teal Oasis"** yang disinkronkan langsung dari Google Stitch MCP (**Project ID: `17152850901645837896`**).

---

## 💎 1. Brand Identity & Filosofi
* **Karakter:** Tenang, profesional, modern, dan bernuansa tropis (*Tropical Professional Workspace*).
* **Warna Jangkar:** *Teal Primary* (`#00685F` / `#0D9488`) berpadu dengan aksen hangat *Tertiary* (`#924628`) dan permukaan bersih slate-white.
* **Geometri:** Sudut membulat (*Rounded & Stadium/Pill*) untuk memberikan kesan ramah dan tidak kaku.

---

## 🌓 2. Arsitektur Global Theme (Light & Dark)

Aplikasi telah dikonfigurasi dengan arsitektur **Material 3 Global Theme** di `lib/app/config/app_theme.dart`:
* **`AppTheme.lightTheme`**: Skema warna cerah berlatar `#FAF8FF` / `#F8FAFC` dengan kartu putih bersih (`#FFFFFF`) dan border lembut `1px #E2E8F0`.
* **`AppTheme.darkTheme`**: Skema warna gelap berlatar `#0B1120` / `#0F172A` dengan kartu `#1E293B` dan aksen teal glowing `#6BD8CB`.
* **Registrasi di `main.dart`**:
  ```dart
  MaterialApp.router(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: ThemeMode.light, // atau ThemeMode.system
    routerConfig: AppRouter.router,
  );
  ```

---

## 🎨 3. Palet Warna (Color Palette)

### Brand & Core
| Token | Light Hex | Dark Hex | Deskripsi |
|---|---|---|---|
| `AppColors.primary` | `#00685F` | `#6BD8CB` | Warna utama Material 3 |
| `AppColors.brandTeal` | `#0D9488` | `#14B8A6` | Warna tombol utama & aksen cerah |
| `AppColors.primaryContainer` | `#F0FDFA` | `#005049` | Latar chip & container aktif |
| `AppColors.onPrimaryContainer` | `#115E59` | `#89F5E7` | Teks di atas container teal |
| `AppColors.secondary` | `#006B5F` | `#4FDBC8` | Aksen sekunder |
| `AppColors.tertiary` | `#924628` | `#FFB59A` | Aksen hangat |

### Canvas & Surface Containers
| Token | Light Hex | Dark Hex | Deskripsi |
|---|---|---|---|
| `AppColors.backgroundSubtle` | `#F8FAFC` | `#0F172A` | Latar dasar kanvas aplikasi (*Scaffold*) |
| `AppColors.surfaceContainerLowest` | `#FFFFFF` | `#090D16` | Latar kartu (*Card Surface*) murni |
| `AppColors.outlineMuted` / `border` | `#E2E8F0` | `#1E293B` | Garis tepi halus (1px border) |
| `AppColors.textPrimary` | `#131B2E` | `#F8FAFC` | Teks judul utama & label tebal |
| `AppColors.textSecondary` | `#64748B` | `#94A3B8` | Teks body & keterangan |

---

## 🔤 4. Tipografi (Typography)

Menggunakan keluarga font tunggal **`Plus Jakarta Sans`** via Google Fonts:

```dart
// Headline Large (28px / 36px line height, Bold)
AppTypography.headlineLarge

// Headline Large Mobile (24px / 32px line height, Bold)
AppTypography.headlineLargeMobile

// Headline Medium (20px / 28px line height, SemiBold)
AppTypography.headlineMedium

// Title Medium (18px / 24px line height, SemiBold)
AppTypography.titleMedium

// Title Small (16px / 22px line height, SemiBold)
AppTypography.titleSmall

// Body Large (16px / 24px line height, Regular)
AppTypography.bodyLarge

// Body Medium (14px / 20px line height, Regular)
AppTypography.bodyMedium

// Body Small (12px / 18px line height, Regular)
AppTypography.bodySmall

// Label Medium (12px / 16px line height, SemiBold, +0.5px tracking)
AppTypography.labelMedium

// Label Small (11px / 16px line height, Medium)
AppTypography.labelSmall
```

---

## 🧩 5. Global Reusable Widgets (`lib/core/widgets/`)

Untuk memastikan konsistensi visual dan menghindari duplikasi kode, gunakan widget global berikut di seluruh layar aplikasi:

### 1. `AppButton` (`lib/core/widgets/app_button.dart`)
* **Varian:** `AppButtonVariant.primary`, `secondary`, `outlined`, `ghost`, `danger`.
* **Fitur:** Auto-loading state indicator (`isLoading`), leading & trailing icons, `StadiumBorder` (pill button), full width / hug content.
* **Contoh Penggunaan:**
  ```dart
  AppButton(
    text: 'Login',
    trailingIcon: LucideIcons.arrowRight,
    isLoading: state is AuthLoading,
    onPressed: _onLoginPressed,
  )
  ```

### 2. `AppTextField` (`lib/core/widgets/app_text_field.dart`)
* **Fitur:** Label di atas input, trailing action di baris label (`labelTrailing`), obscure password toggle otomatis (`isPassword: true`), prefix & suffix icons, border radius `12px`, validasi form, dark-mode aware.
* **Contoh Penggunaan:**
  ```dart
  AppTextField(
    label: 'Password',
    labelTrailing: GestureDetector(
      onTap: () => context.push(Routes.RESET),
      child: Text('Forgot Password?', style: TextStyle(color: AppColors.brandTeal)),
    ),
    controller: _passwordController,
    isPassword: true,
    prefixIcon: LucideIcons.lock,
    validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
  )
  ```

---

## 📐 6. Radius Geometri & Spacing

### Corner Radius
* **`AppRadius.sm` (4px):** Badge kecil atau indikator.
* **`AppRadius.md` (8px):** Komponen ringkas.
* **`AppRadius.input` (12px):** Sudut kolom input (*TextField*).
* **`AppRadius.lg` (16px):** Sudut standar kartu (*Card*).
* **`AppRadius.xl` (24px):** Kartu dashboard, dialog, bottom sheet modal.
* **`AppRadius.full` (9999px / Stadium):** Tombol aksi utama (*ElevatedButton*) dan filter chip (*Chips*).

### Grid & Padding
* **Unit Grid:** 4px
* **Mobile Margin:** 16px
* **Card Gutter:** 16px

---

## 💡 7. Rekomendasi Pemakaian Token (Do's & Don'ts)

* ✅ **DO**: Selalu gunakan `AppColors.brandTeal`, `AppColors.primary`, dan `AppTypography.headlineLargeMobile`.
* ✅ **DO**: Gunakan `AppButton` dan `AppTextField` untuk form input dan aksi tombol di semua layar.
* ❌ **DON'T**: Jangan menggunakan *hardcoded color* seperti `Colors.teal` atau `Color(0xFF00685F)` langsung di dalam view UI.
* ❌ **DON'T**: Hindari `ElevatedButton` polos tanpa tema terstandar.
