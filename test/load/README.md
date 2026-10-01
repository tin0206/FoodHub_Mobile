# Concurrency test suite

Tìm ngưỡng đồng thời tối đa (max concurrent users) mà API còn chịu được, cho
4 nhóm API. Tất cả dùng chung thuật toán: ramp thô rồi binary-search để chốt
đúng con số, xem [loadtest_lib.py](loadtest_lib.py) — logic này bê nguyên từ
[find_max_concurrency.py](find_max_concurrency.py) (case đầu tiên, xem kết quả
mẫu ở [STRESS-07-results.md](STRESS-07-results.md)).

## Setup

```bash
cp test/load/.env.test.example test/load/.env.test
# rồi điền TEST_USER_1_EMAIL / TEST_USER_1_PASSWORD (tài khoản test trên staging)
```

`.env.test` bị gitignore — không commit password thật. Thêm `TEST_USER_2_EMAIL`
/ `_PASSWORD`, `_3_`, ... nếu API giới hạn quota AI theo từng tài khoản (case
2-4), để tránh nhầm lỗi quota với ngưỡng concurrency thật.

## 4 case

| Case | Script | API | Fail khi |
|---|---|---|---|
| 1 | `case1_auth_crud_test.py --mode get\|patch` | `GET`/`PATCH /users/me` | error_rate (http_error/timeout/connection_error) > `--max-error-rate` (mặc định 10%) |
| 2 | `case2_dish_recognition_test.py` | `POST /ai/dish-recognition` | như trên **+ job_failed** (HTTP 200 nhưng `status != "completed"`) |
| 3 | `case3_ingredient_detection_test.py` | `POST /ai/ingredients/detect` | như case 2 |
| 4 | `case4_llm_chat_test.py` | `POST /ai/chat/welcome` + `/ai/chat` | như case 2, tính trên cả welcome lẫn từng tin nhắn |

**Vì sao có `job_failed` riêng:** các API AI đều là một HTTP call chặn duy nhất
(server giữ kết nối tới khi job AI xong), và trả **HTTP 200 ngay cả khi job
fail** — báo lỗi qua field `status` trong body, không qua status code. Coi
điều này ngang một lỗi thật khi tính error_rate.

Case 2-4 dùng ảnh cố định trong `fixtures/` để kết quả giữa các mức tải so
sánh được với nhau (không lấy ảnh ngẫu nhiên mỗi lần).

**Latency đo từ lúc gửi request tới lúc nhận đủ response** — không tính thời
gian client chuẩn bị ảnh trước khi gửi, cũng không tính thời gian tải ảnh kết
quả (`image_url`/`annotated_image_url` trỏ tới Ceph) sau đó. Xem phần "Latency
đo cái gì" trong [CONCURRENCY-RESULTS.md](CONCURRENCY-RESULTS.md) để biết chi
tiết và vì sao độ trễ người dùng thật cảm nhận có thể cao hơn.

## Chạy

Mỗi script có 2 chế độ:

- **Mặc định** — ramp + binary-search để tìm điểm gãy (số đồng thời tối đa).
- **`--baseline`** — chỉ báo cáo p50/p95/p99/error_rate ở vài mức tải cố định
  (mặc định 5 và 10 đồng thời, đổi bằng `--baseline-levels`), không tìm điểm
  gãy. Dùng để biết trải nghiệm ở tải "bình thường" khác gì với lúc gần vỡ.

```bash
# Case 1 — nhẹ, có thể dùng coarse-steps mặc định (tới hàng trăm)
python test/load/case1_auth_crud_test.py --mode get
python test/load/case1_auth_crud_test.py --mode patch
python test/load/case1_auth_crud_test.py --mode get --baseline

# Case 2-4 — tốn compute AI thật, mặc định coarse-steps nhỏ (1,2,4,8,16,32)
python test/load/case2_dish_recognition_test.py
python test/load/case3_ingredient_detection_test.py
python test/load/case4_llm_chat_test.py
python test/load/case2_dish_recognition_test.py --baseline
```

Luôn chạy **staging trước**, tải thấp trước, rồi mới tăng dần — xem
STRESS-07-results.md mục "Cách chạy lại" để biết cách dò nhanh 1 mức cố định
trước khi để script tự binary-search. Chỉ chuyển sang production khi đã có
sự đồng ý của backend team (case 2-4 đặc biệt: có thể tạo tải lớn lên model
AI tự host, ảnh hưởng người dùng thật đang dùng chung).

Log đầy đủ mỗi lần chạy được ghi vào `test/load/logs/<script>_<timestamp>.txt`
(gitignored).

## Giới hạn đã biết

- Case 2-4 đo trên **1 tài khoản test mặc định** trừ khi bạn cấu hình thêm —
  nếu backend rate-limit theo user, ngưỡng đo được có thể là quota per-user
  chứ không phải sức chịu tải thật của hệ thống. So sánh lại với nhiều tài
  khoản nếu nghi ngờ.
- Ingredient detection còn có API WebSocket streaming
  (`wss://.../ai/ingredients/stream`) — chưa test, cần phương pháp riêng (đếm
  số kết nối đồng thời, không phải request/s).
- Chưa đo được resource phía server (CPU/GPU/DB pool) vì backend không nằm
  trong repo này — chỉ suy luận qua hành vi phía client (lỗi/timeout/latency).
