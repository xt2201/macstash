# Stash for macOS: Danh muc Giay phep va Nguon Tai nguyen

Tai lieu ghi nhan nguon goc, ban quyen va giay phep su dung cua toan bo tai nguyen duoc su dung trong qua trinh thiet ke logo va bo nhan dien Stash.

---

## 1. Typography va Wordmark
- **Font chu goc**: Apple San Francisco (SF Pro Display, SF Pro Text, SF Mono).
  - **Nha cung cap**: Apple Inc.
  - **Giay phep su dung**: Apple System Font License (cho phep su dung de thiet ke giao dien, bieu tuong va trai nghiem cho cac san pham hoat dong tren he sinh thai macOS/iOS/iPadOS).
  - **Quy trinh xu ly ky thuat**: Toan bo cac chu cai trong wordmark ("Stash") va cac tai lieu vector deu duoc chuyen doi truc tiep thanh duong cong Bézier doc lap (Vector Outlines / Paths). Khong co file font nhan ban `.ttf` hay `.otf` ben ngoai nao duoc nhung trai phep vao bo cai dat.

---

## 2. He luoi va Thong so Mau (Templates & Grid Specifications)
- **He thong luoi macOS App Icon Grid**:
  - **Nguon tham chieu**: Apple Design Resources (macOS Human Interface Guidelines).
  - **Thong so ap dung**: Canvas 1024x1024 pixel, vung an toan trung tam ban kinh 412pt (duong kinh 824pt), he truc toa do can bang thi giac tren macOS Sequoia / Sonoma.
  - **Kien truc Liquid Glass & Icon Composer**: Tuan thu tai lieu ky thuat WWDC20 va WWDC24 cua Apple Developer ve cau truc layered `.icon`.

---

## 3. Tai nguyen Vector va Do hoa (Graphic Assets)
- **Tinh nguyen ban (Originality)**:
  - 100% cac file vector SVG (gom 6 huong phac thao, 2 huong tinh chinh va bo layer thanh pham) duoc dung hinh hoc tu dau bang cac phep toan vector chinh xac (cung tron, doan thang, toa do so thuc).
  - Khong su dung bat ky clip-art, hinh anh stock, vector thu vien tu ben thu ba (nhu Freepik, Shutterstock, The Noun Project, Iconfinder).
  - Khong su dung emoji trong bat ky file thiet ke, doan ma nguon hay tai lieu huong dan nao.

---

## 4. Cong cu Phan mem va Script Tu dong hoa
- **Engine sinh asset**:
  - `sips` (macOS built-in Scriptable Image Processing System).
  - `qlmanage` (macOS built-in QuickLook Server thumbnail rendering engine).
  - `iconutil` (macOS Developer Tools CLI cho viec tao file `.icns`).
  - Python 3 (cac thu vien he thong tieu chuan dung de kiem tra va xu ly du lieu).
