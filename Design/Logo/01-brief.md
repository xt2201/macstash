# Stash for macOS: Design Brief va Nghien cuu Thuong hieu

Tai lieu quy chuan thiet ke thuong hieu, phan tich thi truong va quy dinh ky thuat bieu tuong cho ung dung Stash tren he dieu hanh macOS.

---

## 1. Tong quan ve Ung dung Stash

### 1.1. Tinh nang va Kien truc Ung dung
Stash la mot tien ich he thong cao cap danh cho macOS (menu bar utility app) duoc toi uu hoa cho trai nghiem thao tac khong giandieu khien man hinh rong va da man hinh. Cac tinh nang cot loi gom:
- **Hot Corner Dials (Vong quay goc man hinh)**: Tan dung triet de 4 goc vat ly cua man hinh macOS (Top-Left, Top-Right, Bottom-Left, Bottom-Right) de kich hoat cac dong ho vong cung 1/4 hinh tron (quarter-circle radial dials) thong qua co che re chuot cham (dwell delay 0.2s) voi vung hit-test tieu chuan 5-8 diem nham triet tieu kich hoat nham.
- **Dieu chinh Do sang Da man hinh (Per-Monitor Brightness)**: Tich hop sau voi DDC/CI cho man hinh ngoai vi, Apple Native Display Services cho man hinh Retina tich hop, va co che Software Dimming du phong.
- **Bo dem Focus Pomodoro**: Bo dem tap trung co che don dieu (monotonic clock) chia chu ky lam viec 25 phut va nghi ngan 5 phut, hien thi truc quan tien trinh dang chay truc tiep tren vanh cung radial gauge.
- **Dieu khien He thong Xuc giac**: Dieu chinh am luong tong kem bo chuyen doi thiet bi am thanh nhanh, dieu chinh den nen ban phim (keyboard backlight) va ngan keo ung dung an (Hidden Dock).
- **Phan hoi Xuc giac va Am thanh co hoc**: Mo phong tieng click co khi va nhip rung haptic tinh vi khi xoay qua tung nac thong so.

### 1.2. Tom tat Gia tri trong Mot cau
> **"Stash mang den cac vanh quay dieu khien xuc giac an tai bon goc man hinh macOS, giup nguoi dung dieu chinh do sang da man hinh, am luong va nhip tap trung Pomodoro tuc thi ma khong chiem dung khong gian thi giac hay lam phan tam cong viec."**

### 1.3. He thong Mau va Font hien tai trong Codebase
- **He mau giao dien**: Su dung bang mau trung tinh macOS ket hop voi cac dai mau nhan (accent gradients) mang tinh chuc nang ro rang:
  - Am luong (Volume): Xanh duong cong nghe (`#2E9EFF` den `#0D61F2`).
  - Do sang man hinh (Brightness): Ho phach am ap (`#FFC22E` den `#FF7A00`).
  - Den ban phim (Keyboard): Ngoc lam (Teal/Cyan `#38D9C7` den `#1A99BF`).
  - Pomodoro Timer: Tim tap trung (Amethyst Violet `#C76BFF` den `#7A38F2`).
  - Mau thuong hieu trung tam (Brand Accent): Xanh dien quang Azure (`#0A84FF`) tren nen toi Deep Space Slate (`#16181D`).
- **Font chu**: Typography he thong Apple San Francisco (SF Pro Display cho tieu de va lockup, SF Pro Text cho noi dung, SF Mono cho thong so ky thuat va bo dem).

---

## 2. Dinh vi Thuong hieu

### 2.1. Tinh cach Thuong hieu (Brand Personality)
- **Tinh gon (Lean)**: Khong ton tai bat ky chi tiet thua thai nao. Khong icon mau me, khong giao dien cong kenh.
- **Sieu toc (Instantaneous)**: Thao tac phan hoi duoi 16ms (60-120fps), xuat hien ngay khi cham goc man hinh va bien mat em ai khi roi chuot.
- **Chinh xac co hoc (Mechanical Precision)**: Cac vach chia (ticks), kim chi, vanh chia do tao cam giac nhu mot dong ho do do dac Thuy Si hoac ong kinh may anh Leica.
- **Tinh te va Khong on ao (Subtle & Calm)**: Hoat dong nhu mot phan tu nhien cua he dieu hanh macOS, ton trong su tap trung tuyet doi cua nguoi dung.

### 2.2. Doi tuong Nguoi dung Muc tieu (Target Audience)
- Cac chuyen gia sang tao, ky su phan mem, nha thiet ke giao dien, quan ly du an va nguoi dung macOS lam viec chuyen sau tu 8 den 14 gio moi ngay.
- Nguoi dung su dung thiet lap da man hinh (MacBook ket hop tu 1 den 3 man hinh 4K/5K Studio Display hoac man hinh chuyen do hoa ngoai vi).
- Nguoi dung de cao chu nghia toi gian, thich su gon gang cua Menu Bar, uu tien phim tat va cu chi thay vi phai mo tung cua so cai dat phuc tap.

### 2.3. Diem Khac biet Cot loi (Key Differentiators)
- **Khai thac khong gian goc vat ly (Zero-Pixel Invisibility)**: Thay vi chen chuc them bieu tuong vao thanh Menu Bar von da qua tai, Stash dat diem cham truc tiep tai cac ria ngoai man hinh - noi chuot co the vung toi ma khong can ngam ban toa do (Fitts's Law).
- **Giao dien Cung tron Radial Dial**: Thay the thanh truu truot (slider) tuyen tinh don dieu bang vanh tron xuc giac dong tam phat xuat tu dinh goc man hinh.

---

## 3. Phan tich Doi thu va Boi canh Truc quan

Nghien cuu 8 ung dung tien ich pho bien nhat tren macOS trong phan khuc Menu Bar, Hot Corner, Quan ly Man hinh va Nang suat:

| STT | Ten Ung dung | Hinh khoi chu dao | Bang mau chu dao | Diem manh | Diem yeu / Diem nham (Cliché) |
|---|---|---|---|---|---|
| 1 | **MonitorControl** | Man hinh phang LCD voi mat troi / loa o giua | Trang, Xam, Xanh duong macOS co dien | Bieu dat truc dien chuc nang dieu khien man hinh ngoai vi. | Qua co dien, mo ta phan cung man hinh tho so, thieu tinh cao cap cua mot phan mem hien dai. |
| 2 | **BetterDisplay** | Man hinh cach dieu kem ma tran diem anh / khung chia do | Xanh neon dam tren nen toi carbon | Tao cam giac ky thuat chuyen nghiep, phu hop cho chuyen gia hien thi. | Ranh gioi nhieu chi tiet nho; thu nho o 16px bi nhoe thanh mot khoi chu nhat dac. |
| 3 | **Lunar** | Mat trang da chieu (Moon phases) voi be mat go ghe | Xanh dem cuc quang, Vang trang, Bac | Hinh tuong mat trang rat dep, mang tinh tho va gan lien voi ten goi. | Khong goi mo bat ky lien he nao toi goc man hinh, do sang hay phan cung khi nhin thoang qua. |
| 4 | **Bartender** | Coc cocktail voi mieng chanh / binh lac ruou | Mau cam amber, Thuy tinh trong suot, Vang | Nhan dien manh me, choi chu xuat sac tu cai ten "Bartender". | Phep an du do uong khong lien quan den he thong; khong the mo rong cho tien ich chuyen sau ve phan cung. |
| 5 | **Raycast** | Chu R goc canh / tia sang goc cheo dong hoc | Do son tra (Crimson Red) tren nen den xam | Nhan dien cuc manh, don gian, tao cam giac toc do vuot troi. | Thien huong launcher / terminal; mang tinh gay gat va nang ve goc nhon, khong goi su em ai cua dial. |
| 6 | **Dropover** | Chiec hop / khay giay mo nap voi mui ten roi | Xanh la sang (Cyan/Lime), Xam ngoc | The hien xuat sac hanh dong tha va luu tru tam thoi (drop & stash). | Qua thien ve hanh dong file-drop; de gay hieu lam rang app chi la noi luu file tam. |
| 7 | **Rectangle** | Khung cua so chu nhat chia doi / chia tu | Xanh lam nhat tren nen trang ngoc | Don gian, ro rang cho tinh nang chia khung cua so. | Qua don dieu, thieu chieu sau va khong the hien duoc tinh chat dynamic cua cong cu xuc giac. |
| 8 | **DisplayBuddy** | Bieu tuong mat troi cach dieu ben trong man hinh | Xanh duong sapphire va Vang cam | Mau sac tuoi sang, dong bo voi phong cach Apple macOS Sonoma. | Bieu tuong mat troi long trong man hinh la loi mon thiet ke cua hau het cac app monitor tren App Store. |

### Khoang trong Nhap dien (Visual Whitespace) cho Stash
- **Tranh tuyet doi**: Khong ve hinh man hinh LCD, khong ve mat troi/bong den truyen thong, khong ve coc nuoc/hop luu tru kieu cu, khong dung dai gradient tim-hong cua phong trao AI phong trao.
- **Khoang trong doc ban**: Bieu tuong cua Stash can the hien duoc **su giao thoa giua "Goc vuong man hinh" (The Corner Anchor) va "Cung tron vanh quay mo rong" (The Radial Expansion Arc)**. Day la mot hinh the hoc thuan khiet, co the doc duoc trong 1 giay, dai dien cho ca thao tac cham goc (hot corner), hanh dong cat/goi mo (stash) va vanh do chinh xac (radial dial).

---

## 4. Xu huong Thiet ke Icon Apple va Yeu cau Ky thuat

Nghien cuu doi chieu voi tai lieu Apple Developer (Human Interface Guidelines > App Icons; phien WWDC20 va WWDC24 ve Icon Composer va he thong Liquid Glass tren macOS Sequoia / macOS 15+):

### 4.1. Nguyen tac HIG dang co Hieu luc tren macOS
- **He khung hinh Squircle (Superellipse)**: Canvas tieu chuan la 1024x1024 pixel. Apple su dung duong cong lien tuc bac cao khong dut doan goc (continuous curvature).
- **Quy tac Quan trong ve Masking**: Designer tuyet doi **khong tu ve vien bo goc, khong xuat canvas mask** vao file asset. He thong macOS se tu dong cat mat na squircle va ap dung do bong drop shadow phu hop voi tung boi canh (Dock, Finder, App Switcher).
- **Ty trong Thi giac (Visual Weight)**: Vung an toan (Safe Zone) nam trong hinh tron duong kinh ~824px hoac hinh vuong bo goc 824x824px tam giua canvas 1024px. Dấu hieu khong duoc tran ra sat mep 1024px de tranh bi mat na cua he dieu hanh cat pham.

### 4.2. He thong Liquid Glass va Icon Composer (WWDC24 / macOS 15+)
- **Kien truc phan tang (Layered Architecture)**: Icon hien dai khong con la mot anh bitmap PNG phang. File `.icon` bao gom cac tang doc lap:
  1. `Background Layer`: Mau nen hoac gradient dong nhat.
  2. `Midground / Foreground Groups`: Cac hinh khoi vector chinh.
  3. `Monochrome / Silhouette Representation`: Ban hinh hoc don sac (chi dung alpha) de he thong tinh toan do phan xa anh sang va ap dung cac che do hien thi.
- **Xu ly Hieu ung theo thoi gian thuc (Real-time System Rendering)**:
  - Do sau (Depth), phan chieu (Specular Highlights), khuc xa (Refraction) va bong do (Dynamic Shadows) deu do nhan do hoa cua macOS tu dong sinh ra.
  - **Cam chi dinh san hieu ung**: Khong duoc tu ve highlight gia, khong ve vien sang nhan tao (fake glow), khong do bong cung truc tiep tren vector.
- **4 Che do Bien the He thong Bat buoc**:
  - `Default (Light)`: Hien thi day du mau sac tieu chuan voi chat lieu kinh phan xa tu nhien.
  - `Dark`: Mau nen ha tong tram, chat lieu kinh hap thu anh sang xung quanh.
  - `Clear (Kinh trong)`: Nen tro nen trong suot hoac ban trong, cac khoi noi lam cong mat anh nen phia sau.
  - `Tinted`: He thong phu mot lop mau don sac tuy chon cua nguoi dung len toan bo icon; cac khoi hinh hoc phai giu duoc do tuong phan va hinh khoi ro rang.

---

## 5. Chot Rang buoc Thiet ke cho Stash

1. **Hinh hoc chu dao**: Mot dau hieu hinh hoc co the nhan dien tuc thi o moi kich thuoc tu 1024px xuong 16px.
2. **Kien truc Layer chuan Apple**: Tach rieng `background.svg`, `foreground.svg`, va `mono.svg`.
3. **Bang mau kiem toa**:
   - Mau nen: Deep Space Graphite `#14171F` den Obsidian Navy `#0E1017`.
   - Mau nhan chu dao: Precision Cyan / Azure `#0A84FF` ket hop phien ban phan quang Electric Cyan `#00D2FF`.
   - Mau vach so: Pure Platinum `#FFFFFF` (opacity phan tang tu 15% den 90%).
4. **Kha nang mo rong**:
   - Bieu tuong Menu Bar phai la template image don sac 16x18pt hoat dong hoan hao tren ca nen sang, toi va trong suot.
   - Lockup logo ngang ket hop font chu SF Pro duoc vector hoa hoan toan.
5. **Quy tac nghiem ngat**:
   - Khong emoji.
   - Khong chi tiet clip-art hoac hieu ung kinh gia.
   - Giay phep minh bach cho moi tai nguyen duoc su dung.
