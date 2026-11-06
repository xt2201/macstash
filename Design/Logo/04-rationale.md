# Stash for macOS: Co so Thiet ke va Quy chuan Thuong hieu (Brand Rationale)

Tai lieu thiet lap co so y tuong, he thong hinh hoc quy chuan, bang mau chuc nang va quy tac su dung bieu tuong Stash.

---

## 1. Y tuong Cot loi va Triet ly Thiet ke

Bieu tuong Stash duoc xay dung dua tren triet ly: **"Thao tac Vong quay Xuc giac tai Goc Toa do Vat ly" (Tactile Corner Kinematics)**.

### Ba Yeu to Cau thanh bieu tuong:
1. **Diem neo Goc (Origin Anchor Pin)**: Toa do `(0,0)` tai goc man hinh - noi theo Dinh luat Fitts co dien tich cham vo han boi vi con tro chuot khong the vuot ra ngoai ria man hinh vat ly. Day la chot dinh vi duy nhat giup nguoi dung re chuot khong can ngam ban.
2. **Vanh Cung Xuc giac (Radial Dial Sector)**: Khoi hinh quat 60 do phat xuat tu diem neo goc, mo phong chinh xac chuyen dong xoay nhe cua co tay khi nguoi dung dieu chinh do sang man hinh, am luong hoac thoi gian Pomodoro.
3. **Nac Co hoc (Mechanical Detents)**: Cac vach chia do tai cac goc dac biet (0, 30, 45, 60, 90 do) goi cam giac ve nhung chiec dong ho tinh gio hoac ong kinh may anh Leica cao cap.

---

## 2. He Luoi va Hinh hoc Xay dung (Construction Geometry)

Toan bo bieu tuong duoc dung dua tren he truc toa do goc vuong va phuong trinh hinh hoc cung tron:

### 2.1. Thong so Toa do Chuan tren Canvas 1024x1024
- **Diem tam goc (Anchor Center)**: `P0 = (160, 864)` (goc duoi-trai cua vung an toan macOS).
- **Ban kinh Vanh quat Chinh (Active Sector)**:
  - Ban kinh ngoai: `R_outer = 560 px` (tuong duong 54.7% kich thuoc canvas).
  - Ban kinh trong: `R_inner = 360 px` (tuong duong 35.1% kich thuoc canvas).
  - Do day thanh quat: `Delta_R = 200 px`.
  - Goc quet: 60 do tu truc thang dung (tu goc 90 do den goc 30 do tren he truc toa do cuc).
- **Vanh Ranh truot Inactive (Track Channel)**:
  - Ban kinh tam: `560 px`, do day net stroke: `40 px`.
  - Quet tron ven 90 do tu truc thang dung `(160, 304)` den truc nam ngang `(720, 864)`.
- **Hat nhan Goc (Anchor Node)**:
  - Vanh ngoai: Ban kinh `120 px`, vien stroke `16 px`.
  - Vanh loi quang: Ban kinh `56 px`.
  - Diem sang tam: Ban kinh `24 px`.
- **Diem chi 45 do (Focal Detent Pip)**:
  - Toa do tam: `(485, 539)`.
  - Ban kinh ngoai: `28 px` (Platinum White).
  - Ban kinh loi: `14 px` (Azure Core).

---

## 3. Bang Mau Chuc nang va Gia tri Quy chuan

Bang mau duoc kiem toa chat che, su dung khong gian mau tieu chuan Display P3 va sRGB:

| Mau sac | Ma Hex | RGB (sRGB) | Ty le Su dung | Vai tro va Y nghia |
|---|---|---|:---:|---|
| **Obsidian Slate** | `#191D26` | `(25, 29, 38)` | 55% | Mau nen tren cua gradient hop chua (container); tao chieu sau khong gian toi macOS. |
| **Deep Charcoal** | `#0D0F14` | `(13, 15, 20)` | 30% | Mau nen duoi cua gradient hop chua; tao cam giac be mat kim loai anot hoa (anodized metal). |
| **Precision Cyan** | `#00D2FF` | `(0, 210, 255)` | 8% | Mau phan quang phia truoc cua vanh quay active; do tuong phan cao nhat (9.95:1) dam bao nhan dien o 16px. |
| **Electric Azure** | `#0A84FF` | `(10, 132, 255)` | 5% | Mau nhan he thong Apple macOS; ket noi tu nhien voi he sinh thai giao dien goc. |
| **Platinum White** | `#FFFFFF` | `(255, 255, 255)` | 2% | Mau cac vach chia do co hoc va diem sang loi; do tuong phan toi da (17.92:1). |

---

## 4. Quy tac Su dung Bieu tuong (Brand Usage Guidelines)

### 4.1. Khoang trong An toan (Clear Space)
- **Quy tac `X`**: Khoang trong an toan xung quanh bieu tuong hoac logo lockup duoc xac dinh bang chieu rong cua hat nhan goc (Anchor Pin diameter = `X = 112 px` tren canvas 1024, tuong duong khoang 12% tong chieu rong).
- Khong duoc de bat ky van ban, thanh phan do hoa hay ranh gioi khung cua so nao xam pham vao vung an toan `X` nay.

### 4.2. Kich thuoc Toi thieu (Minimum Sizing)
- **Dau hieu doc lap (Standalone Mark)**: Kich thuoc hien thi toi thieu la **16 x 16 px** (hoac 16 x 16 pt tren man hinh Retina). O kich thuoc nay, cac vach chia do sieu nho tu dong an di, chi giu lai vanh quat dac va hat nhan goc.
- **Lockup Logo Ngang (Mark + Wordmark "Stash")**: Kich thuoc hien thi toi thieu la **24 pt** ve chieu cao (chieu dai tuong ung khoang 96 pt) de dam bao chu "Stash" luon doc ro.

### 4.3. Cac Dieu Tuyet doi Cam (Do-Nots)
1. **Cam xoay huong bieu tuong**: Khong duoc xoay goc bieu tuong sang cac huong khac trong logo chinh thuc. Diem neo phai luon nam o goc phu hop voi quy chuan da duoc phe duyet.
2. **Cam bop meo ty le (No Distort / Stretch)**: Phai luon phong to / thu nho dong ty le 1:1.
3. **Cam tu ve them bong do hoac vien kinh gia**: He thong macOS Liquid Glass va Icon Composer se tu dong sinh bong do quang hoc. Khong them drop shadow thu cong vao file SVG.
4. **Cam doi mau tuy tien**: Khong su dung cac dai gradient cau vong hoac gradient tim-hong ngoai quy chuan bang mau da neu tai Muc 3.
5. **Cam dat bieu tuong tren nen kho doc**: Khong dat bieu tuong khong hop chua truc tiep tren cac hinh nen co hoa tiet phuc tap hoac nen co do tuong phan duoi 4.5:1.
