# Stash for macOS: Huong dan Dung file .icon bang Apple Icon Composer

Tai lieu huong dan tung buoc quy trinh lap rap va cau hinh file `.icon` chuan Apple Liquid Glass bang ung dung Apple Icon Composer (macOS 15 Sequoia / Xcode 16+).

---

## 1. Cac File Layer San sang (Prepared Layer Assets)
Cac file SVG nguon nam tai `Design/Logo/source/`:
1. `stash_icon_background.svg`: Tang nen khong cat mask (1024x1024), gradient Obsidian Slate den Deep Charcoal.
2. `stash_icon_foreground.svg`: Tang vanh quat quang hoc (Cyan/Azure), hat nhan goc va cac vach detent co hoc.
3. `stash_icon_mono.svg`: Ban hinh hoc don sac (Monochrome Silhouette) voi cac muc alpha tuong ung cho do phan xa quang hoc va che do Tinted.

---

## 2. Quy trinh Tung buoc trong Icon Composer

### Buoc 1: Tao Du an Icon moi (New Icon Document)
1. Mo **Icon Composer** tren macOS.
2. Chon **File > New** (hoac bam `Command + N`).
3. Chon template **macOS App Icon** (Canvas 1024 x 1024).

### Buoc 2: Thiet lap Tang Nen (Background Layer)
1. Keo tha file `Design/Logo/source/stash_icon_background.svg` vao o **Background** trong ngan Layer Stack ben trai.
2. Hoac chon tuy chon **Native Solid / Gradient** trong Inspector panel ben phai:
   - Type: `Linear Gradient` (goc 135 do).
   - Start Color: `#191D26` (Obsidian Slate).
   - End Color: `#0D0F14` (Deep Charcoal).

### Buoc 3: Thiet lap Nhom Tien canh (Foreground Group)
1. Keo tha file `Design/Logo/source/stash_icon_foreground.svg` vao o **Foreground**.
2. Trong Inspector panel:
   - **Blend Mode**: Chon `Normal`.
   - **Material Type**: Chon `Liquid Glass / Specular Glass`.
   - **Refraction Index**: Chon `1.15` (tao do cong uon quang hoc nhe quanh mep vanh dial).
   - **Specular Highlights**: Chon `Automatic` (he thong tu dong phan chieu vach sang theo chieu chieu sang doc cua macOS).

### Buoc 4: Gan Ban Hinh hoc Don sac (Monochrome Representation)
1. Chon slot **Monochrome / Tint Representation**.
2. Keo tha file `Design/Logo/source/stash_icon_mono.svg`.
3. Icon Composer se su dung cac muc do alpha cua file nay de ap dung mau sac khi nguoi dung bat che do **Tinted Mode** trong phan cai dat hien thi macOS.

### Buoc 5: Kiem tra Truc quan 4 Che do Hien thi (Variants Inspection)
Trong thanh Preview toolbar cua Icon Composer, lan luot chuyen doi giua:
- **Default**: Kiem tra do phan xa anh sang tren mat kinh vanh dial.
- **Dark**: Kiem tra do sau cua be mat Obsidian va tinh phat quang cua hat nhan Cyan.
- **Clear**: Xac nhan rang hinh anh hinh nen ben duoi duoc khuc xa tu nhien qua khoi kinh.
- **Tinted**: Kiem tra voi cac mau mau (vang, xanh la, do) xem khoi hinh hoc co bi mat tuong phan hay khong.

### Buoc 6: Xuat Asset (Export)
1. Chon **File > Export...**.
2. Dinh dang xuat: `.icon` hoac keo tha truc tiep vao Xcode Asset Catalog (`Assets.xcassets/AppIcon.icon`).

---

## 3. Ghi chu ve Moi truong Thuc thi
- Trong moi truong may chu dong lenh (CLI headless runner), ung dung do hoa Icon Composer khong duoc cai dat san trong `/Applications`.
- Du an su dung pipeline tu dong hoa doc lap `scripts/render_icons.sh` de sinh bo `AppIcon.appiconset` va `MacStash.icns` du phong chuan muc, dam bao ung dung luon hien thi day du icon tren moi phien ban macOS tu macOS 13 tro len.
