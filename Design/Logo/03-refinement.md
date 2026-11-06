# Stash for macOS: Tinh chinh va Kiem thu (Refinement & Testing)

Tai lieu ghi nhan qua trinh tinh chinh hinh hoc tren he luoi chuan, ket qua chay bo kiem thu da chieu va ly do lua chon bieu tuong cuoi cung cho Stash.

---

## 1. He Luoi Hinh hoc va Kien truc Vector Chuan (Geometric Grid System)

Hai huong phac thao vao chung ket da duoc dung lai hoan toan bang cac phuong trinh hinh hoc vector voi do chinh xac toa do tuyet doi tren canvas 1024x1024 pixel.

### 1.1. Thong so Luoi Quy chuan (MacStash Modular Grid)
- **Kich thuoc Canvas goc**: 1024 x 1024 px.
- **Vung an toan (HIG Safe Zone)**: Vong tron duong kinh 824px tam tai `(512, 512)`. Cac phan tu hinh hoc chinh nam tron ven ben trong ranh gioi tu toa do 100px den 924px tren ca hai truc X va Y.
- **Diem neo goc (Origin Corner Anchor)**: Toa do `(160, 864)` tai goc duoi-trai cua vung an toan (dong bo voi vi tri vat ly cua Hot Corner man hinh macOS).
- **Kien truc Phan tang (Liquid Glass Layer Architecture)**:
  - `layer-background`: Hinh chu nhat 1024x1024 voi gradient chuyen tiep tu Obsidian Slate `#191D26` den Deep Charcoal `#0D0F14`. Tuyet doi khong co mask bo goc san de he thong macOS tu dong cat squircle.
  - `layer-midground`: Vanh ranh truot 90 do ban kinh ngoai 560px, do day 40px cung cac vach chia do (detents) co hoc 0, 30, 45, 60, 90 do.
  - `layer-foreground`: Vanh quat dac (Solid Radial Sector) ban kinh ngoai 560px, ban kinh trong 360px, quet goc 60 do ruc ro voi gradient Cyan/Azure; hat nhan chot goc (origin pin) hai tang tai diem neo.

---

## 2. Ket qua Bo Kiem thu Bat buoc (Multi-Dimensional Test Suite)

Bo kiem thu duoc thuc thi tu dong bang script `scripts/test_icons.py` va ghi nhan toan bo ket qua hinh anh tai thu muc `Design/Logo/exports/tests/`.

### 2.1. Kiem thu Kich thuoc da tang (Multi-Scale Pyramid)
Kiem tra kha nang doc duoc cua bieu tuong tai cac kich thuoc: 1024, 512, 256, 128, 64, 32, 16 px.

| Kich thuoc | Huong 1 (Radial Bloom) | Huong 2 (Aperture Sector) | Danh gia Chuyen mon |
|---|:---:|:---:|---|
| **1024 px** | Dat tuyet doi | Dat tuyet doi | Do sac net vector hoan hao, gradient muot ma, chi tiet co hoc ro net. |
| **512 px** | Dat tuyet doi | Dat tuyet doi | Hien thi chuan xac tren man hinh Retina Finder va App Store. |
| **256 px** | Dat tuyet doi | Dat tuyet doi | Vanh cung va vach detent 45 do giu nguyen tinh xuc giac. |
| **128 px** | Dat tuyet doi | Dat tuyet doi | Kich thuoc mac dinh tren Dock macOS; ty trong thi giac can bang. |
| **64 px** | Dat tuyet doi | Dat | Vanh quat cua Huong 1 van noi bat; Huong 2 bat dau hoi manh khanh. |
| **32 px** | Dat | Dat (ranh gioi) | Huong 1 giu duoc khoi dac hinh quat va hat nhan goc ro rang. |
| **16 px** | **Dat xuat sac** | Khong dat (mo nhat) | **Huong 1 nhan ra duoc trong 1 giay**: hat nhan goc sang va cung tron 60 do tao thanh bieu tuong vanh quay doc dao. Huong 2 bi dut quang va giong vong xoay buffering bi loi. |

### 2.2. Kiem thu Nen boi canh (Background Contrast Matrix)
Kiem tra hien thi icon tren 4 boi canh giao dien tieu bieu:
- **Nen Sang (#F5F5F7)**: Nen toi cua icon co vien tu nhien tach biet hoan hao khoi nen trang he thong.
- **Nen Toi (#121212)**: Vanh nhan Precision Cyan va cham pin phat sang noi bat tren boi canh Dark Mode sau tham.
- **Nen Hinh nen Nhieu mau (Sonoma Sunset Gradient)**: Khoi Obsidian Slate dong vai tro khay do (container) bao ve chi tiet vanh quay khong bi loan mau voi hinh nen destop.
- **Nen Thang xam Trung tinh (#808080)**: Tuong phan van duy tri o muc tren 4.5:1.

*File ket qua kiem thu*: `Design/Logo/exports/tests/refined_01_radial_bloom_test_backgrounds.png`

### 2.3. Kiem thu Cac Che do Hien thi macOS (Appearance Modes)
- **Default Mode**: Mau sac day du (Obsidian Slate + Electric Cyan `#00D2FF` + Azure `#0A84FF` + Platinum White `#FFFFFF`).
- **Dark Mode**: Tang do sau, giam 15% do choi nen, nhan manh cac vien quang hoc cua vanh dial.
- **Clear Mode (Kinh trong suốt)**: Thu nghiem voi lop nen kinh mo (frosted glass) va khuc xa anh nen. Cac vien vector duong cong tao ra hieu ung uon cong anh sang thuc su an tuong.
- **Tinted Mode (Thu nghiem 4 tong mau bat buoc)**:
  - *Electric Cyan*: Dong bo voi mau thuong hieu nguyen ban.
  - *Forest Emerald (#34C759)*: Su dung thang xam chuyen doi (grayscale mapping); hinh the giu nguyen 100% tinh nhan dien.
  - *Amber Gold (#FF9500)*: Tong mau sang dac trung; do tuong phan giua vung dac va vung ranh truot van duy tri tren 7:1.
  - *Coral Crimson (#FF3B30)*: Manh me va sac sao, the hien tot o cac trang thai canh bao he thong.

*File ket qua kiem thu*: `Design/Logo/exports/tests/refined_01_radial_bloom_test_modes.png`

### 2.4. Mo phong Mu mau va Do Tuong phan WCAG 2.1
Su dung ma tran bien doi quang hoc Brettel/Viénot:
- **Deuteranopia (Mu mau xanh la / green-weak)**: Mau Cyan chuyen sang tong xanh lam bac, van tuong phan rat manh so voi nen toi.
- **Protanopia (Mu mau do / red-weak)**: Mau Cyan giu nguyen tinh chat phan quang xanh duong dien tu.
- **Do tuong phan Do luong cu the (Contrast Ratio)**:
  - Cyan phan quang (`#00D2FF`) tren nen Obsidian Slate (`#14171F`): **9.95 : 1** (Vuot xa chuan WCAG 2.1 AAA la 7.0:1).
  - Azure chu dao (`#0A84FF`) tren nen Obsidian Slate (`#14171F`): **4.91 : 1** (Vuot chuan WCAG 2.1 AA la 4.5:1).
  - Vach so Platinum (`#FFFFFF`) tren nen Obsidian Slate (`#14171F`): **17.92 : 1** (Vuot xa chuan WCAG 2.1 AAA la 7.0:1).

*File ket qua kiem thu*: `Design/Logo/exports/tests/refined_01_radial_bloom_test_colorblind.png`

### 2.5. Kiem tra Ty trong Thi giac tren Dock Mo phong (Dock Simulation)
Thu nghiem dat canh cac ung dung hang ngay tren thanh Dock macOS: **Finder, Safari, Terminal, Raycast, va Stash**:
- **Ket qua**: Bieu tuong Stash khong bi qua to (khong bi tran ra khoi ranh gioi 824pt nhu cac app thiet ke loi), khong bi qua nho (nho khoi hinh quat dac co dien tich be mat quang hoc can doi voi mat cuoi cua Finder va chiec laban cua Safari).
- Dấu hieu goc khong bi lan at boi cac gradient choi loa cua ben thu ba, mang lai cam giac mot cong cu tien ich he thong di kem macOS chuyen nghiep va dang tin cay.

*File ket qua kiem thu*: `Design/Logo/exports/tests/dock_simulation_comparison.png`

---

## 3. Quyet dinh Cuoi cung va Chon lua Bieu tuong Chinh thuc

### 3.1. Phuong an Duoc Chon lam Bieu tuong Chinh thuc
**Huong 1: The Radial Corner Bloom (Goc No Vanh Cung)** duoc quyet dinh lam nhan dien thuong hieu va app icon chinh thuc cua Stash.

### 3.2. Ly do Chon
1. **Nhan dien 16px vuot troi**: Hinh the khoi hinh quat 60 do va hat nhan goc van doc ro ngay lap tuc o do phan giai cuc nho 16x16 px, trong khi huong 2 bi suy hao thanh nhung hat diem roi rac.
2. **Khop tuyet doi voi Tinh nang San pham**: Khong co hinh anh nao dai dien cho "Hot Corner Dials" va "Stash" trung thuc hon mot vanh quay mo ra tu goc man hinh.
3. **Kha nang chiet xuat sang Menu Bar Icon**: Vanh cung 1/4 hinh tron kem hat nhan goc de dang chuyen doi thanh bieu tuong template don sac 16pt tren Menu Bar voi do nhan dien nhat quan 100%.

### 3.3. Nhung gi Da bo va Ly do
- **Bo Huong 2 (Aperture Sector)**: Hinh the tron trung tam tuy can xung nhung thieu su doc ban ve mat vi tri (khong goi duoc vi tri goc man hinh). O 16px va 32px, phan quat tach roi khien nguoi dung lien tuong toi mot vong quay loading bi dut doan hon la mot dial dieu khien.
- **Loai bo cac vach chia do phu tren Huong 1**: Trong ban phac thao ban dau co 12 vach chia nho doc theo vanh; qua kiem thu thuc te chung gay nhieu o 32px. Ban tinh chinh cuoi da luoc bo cac vach phu, chi giu lai 5 vach detent co hoc chinh tai 0, 30, 45, 60 va 90 do.
