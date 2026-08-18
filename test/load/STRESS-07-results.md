# STRESS-07 — Kết quả kiểm thử tải đồng thời (Concurrency Test)

**Ngày thực hiện:** 18/08/2026
**Môi trường:** Staging — `https://api.foodhub.io.vn/api/v1`
**Endpoint đo:** `GET /recipes/search` (công khai, chỉ đọc — không ghi/sửa/xoá dữ liệu)
**Công cụ:** Script Python tự viết trong thư mục này (`ThreadPoolExecutor` + thư viện `requests`), không dùng công cụ load-test chuyên dụng (k6/JMeter) vì không có sẵn trên máy thực hiện.

---

## 1. Baseline — 10 người dùng đồng thời

Lệnh chạy: `python concurrent_search_test.py --concurrency 10 --requests 50`

| Chỉ số | Kết quả |
|---|---|
| Thành công | 50/50 (0 lỗi) |
| Throughput | 22.5 request/giây |
| Latency p50 | 352 ms |
| Latency p95 | 743 ms |
| Latency p99 | 838 ms |

Ở mức tải rất nhẹ, hệ thống phản hồi ổn định, chưa có dấu hiệu quá tải.

---

## 2. Ramp test — tăng dần số người dùng đồng thời

Lệnh chạy: `python find_max_concurrency.py`

| Số người dùng đồng thời | Thành công | Tỉ lệ lỗi | p50 | p95 | p99 | Trạng thái |
|---:|---:|---:|---:|---:|---:|---|
| 5   | 20/20   | 0%   | 374 ms | 1,331 ms | 1,331 ms | Ổn định |
| 10  | 40/40   | 0%   | 377 ms | 511 ms   | 540 ms   | Ổn định |
| 20  | 80/80   | 0%   | 368 ms | 657 ms   | 2,492 ms | Ổn định |
| **40**  | **160/160** | **0%**   | **491 ms** | **875 ms**   | **1,093 ms** | **Ổn định — mức cao nhất còn an toàn** |
| 45  | 0/90    | 100% | 60,217 ms (chạm timeout 60s) | — | — | **Gãy — request bị treo, không hoàn thành** |
| 50  | 0/200   | 100% | ~15,300 ms (chạm timeout 15s) | — | — | Gãy |
| 80  | 18/320  | 94%  | 15,196 ms | 15,308 ms | 15,344 ms | Gãy nặng |

**Điểm gãy nằm giữa 40 và 45 người dùng đồng thời.** Đây không phải kiểu "chậm dần đều" mà là **gãy đột ngột** — ở 45 luồng, toàn bộ request bị treo (đã thử chờ tới 60 giây, request vẫn không hoàn thành), khác hẳn với việc chỉ tăng latency từ từ như từ 5→40.

---

## 3. Kiểm tra phục hồi sau khi ngừng tải

Ngay sau đợt test ở mức 45 đồng thời, gửi 2 request đơn lẻ liên tiếp để xác nhận server còn sống:

| Lần | Kết quả | Thời gian phản hồi |
|---|---|---|
| 1 (ngay sau khi dừng tải) | HTTP 200 | 82.7 giây (đang xử lý nốt hàng đợi bị dồn) |
| 2 (vài giây sau) | HTTP 200 | 0.64 giây (trở lại bình thường) |

**→ Server tự phục hồi hoàn toàn, không cần khôi phục dữ liệu hay khởi động lại gì.** Đây là hành vi "hàng đợi bị dồn ứ tạm thời" (backpressure), không phải sập/crash vĩnh viễn.

---

## 4. Kết luận

- **Ngưỡng đồng thời an toàn quan sát được: ~40 người dùng cùng lúc** cho endpoint `/recipes/search` trên môi trường staging hiện tại.
- Vượt ngưỡng này không gây lỗi rải rác tăng dần, mà **toàn bộ request đứng hình cùng lúc** — dấu hiệu giống một giới hạn cứng phía backend (số connection tới DB, số worker xử lý request, hoặc cấu hình pool/rate-limit riêng cho staging) hơn là do thiếu tài nguyên phần cứng tăng dần.
- Hệ thống **không bị hỏng vĩnh viễn** — tự phục hồi sạch trong vòng 1–2 phút sau khi ngừng tải.

## 5. Giới hạn của phép đo này

- Dùng script Python (luồng OS thật qua `ThreadPoolExecutor`), không phải công cụ load-test chuyên dụng như k6 — đủ để tìm điểm gãy rõ ràng, nhưng số liệu latency chi tiết ở mức tải cao có thể có sai số do bản thân công cụ đo (không phải chỉ do server).
- Chỉ đo **1 endpoint đọc** (`/recipes/search`). Các endpoint khác (đăng nhập, tạo công thức, AI...) có thể có ngưỡng khác.
- Chưa xác định được **nguyên nhân gốc** của điểm gãy (cần đội backend xem log/cấu hình server, ví dụ: connection pool size, số worker, rate-limit) — khuyến nghị nhờ backend xác nhận đây là giới hạn thật của app hay giới hạn cấu hình riêng cho môi trường staging (thường staging được cấp tài nguyên thấp hơn production).

## 6. Cách chạy lại

```bash
# Test nhanh ở 1 mức tải cố định
python test/load/concurrent_search_test.py --concurrency 10 --requests 50

# Dò tự động, tăng dần và tự dừng khi phát hiện quá tải
python test/load/find_max_concurrency.py
python test/load/find_max_concurrency.py --steps 45 --timeout 60 --requests-per-worker 2 --max-p95-ms 999999 --max-error-rate 1.1
```
