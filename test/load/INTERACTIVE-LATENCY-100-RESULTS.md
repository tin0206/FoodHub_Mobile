# Interactive latency — 100 samples/endpoint (sequential + parallel)

Run: 2026-10-01T12:33 → 13:46, chạy trong **1 tiến trình duy nhất, hoàn toàn tuần tự** (từng endpoint/case chạy xong mới sang cái kế tiếp — không có 2 phép đo nào diễn ra cùng lúc), không có session Claude nào khác chạy song song (đã xác nhận qua `ListAgents` trước khi chạy). Tài khoản test: 1 tài khoản duy nhất (`test/load/.env.test`, gitignored).

Đây là bản mở rộng của bảng "Interactive Response Time (NFR2)" gốc (5 sample/endpoint) — nay đo **100 sample/endpoint**, và với **2 chế độ** cho mỗi endpoint:

- **Tuần tự (sequential)**: `concurrency=1`, 100 request nối tiếp nhau trên cùng 1 phiên — đúng cách bảng NFR2 gốc đo, chỉ tăng số mẫu.
- **Song song (parallel)**: `concurrency=100`, 100 request bắn ra cùng lúc — mô phỏng một đợt burst 100 người dùng chạm vào cùng 1 endpoint cùng một thời điểm.

Độ trễ đo = thời gian từ lúc gửi request tới lúc nhận đủ response (xem chi tiết ở `CONCURRENCY-RESULTS.md#latency-đo-cái-gì`); **bao gồm cả các request lỗi/timeout** trong tính avg/p50 (timeout tính theo đúng giá trị timeout của client, không loại trừ).

## Bảng chính — CRUD / đọc thường (case 1 + case 5)

| Endpoint | Vai trò | Seq avg (ms) | Seq p50 (ms) | Seq err% | Par(100) avg (ms) | Par(100) p50 (ms) | Par(100) err% | Max Stable Concurrency |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| `POST /auth/login` | Đăng nhập | 535 | 529 | 0% | 19070 | 20241 | **94%** | chưa đo (chưa chạy breaking-point search) |
| `GET /users/me` | Tải hồ sơ | 360 | 340 | 0% | 358 | 357 | 0% | **≥ 500** (không gãy tới trần coarse-steps) |
| `PATCH /users/me` | Lưu hồ sơ | 337 | 331 | 0% | 398 | 396 | 0% | **≥ 500** (không gãy tới trần coarse-steps) |
| `GET /recipes?limit=20` | Duyệt công thức | 421 | 345 | 0% | 2527 | 2605 | 0% | chưa đo |
| `GET /recipes/search` | Tìm kiếm công thức | 450 | 441 | 0% | 16146 | 20224 | **79%** | chưa đo |
| `GET /recipes/{id}` | Chi tiết công thức | 386 | 335 | 0% | 412 | 403 | 0% | chưa đo |
| `GET /favorites` | Danh sách yêu thích | 335 | 334 | 0% | 421 | 423 | 0% | chưa đo |
| `GET /meal-plans/{date}` | Kế hoạch bữa ăn trong ngày | 244 | 243 | 0% | 295 | 296 | 0% | chưa đo |
| `GET /meal-plans/{date}/shopping-list` | Danh sách mua sắm | 236 | 235 | 0% | 302 | 302 | 0% | chưa đo |
| `GET /feedback` | Lịch sử phản hồi | 243 | 237 | 0% | 354 | 340 | 0% | chưa đo |

**Tất cả median (p50) tuần tự đều dưới ngân sách 2s của NFR2** (cao nhất là login ở 529ms), kể cả với 100 mẫu thay vì 5 — xác nhận lại kết luận của bảng gốc với mẫu lớn hơn nhiều.

**Phát hiện mới ở chế độ song song:** `POST /auth/login` và `GET /recipes/search` sụp đổ nghiêm trọng khi 100 request bắn cùng lúc — lần lượt **94%** và **79%** timeout (client timeout 20s), trong khi 8 endpoint còn lại (kể cả 2 endpoint AI-nhẹ như `/meal-plans/{date}/shopping-list`) vẫn 0% lỗi ở cùng mức tải. Hai endpoint lỗi đều là **public, không yêu cầu auth** — khả năng cao là đang bị rate-limit riêng (theo IP hoặc global) chứ không phải do tải hệ thống chung, vì các endpoint auth khác (favorites, feedback, meal-plans — đều cần Bearer token) hoàn toàn khỏe ở cùng mức 100 đồng thời. Cần kiểm tra cấu hình rate-limit cho `/auth/login` và `/recipes/search` ở phía backend/gateway.

Cột **Max Stable Concurrency** lấy từ breaking-point search thật (coarse ramp + binary search, xem `CONCURRENCY-RESULTS.md` — run 2026-10-01) — mức đồng thời cao nhất mà error rate vẫn ≤ 10%. Cột này chỉ có số liệu cho `GET`/`PATCH /users/me` (case 1); 8 endpoint còn lại (case 5) mới chỉ đo ở đúng 2 mức 1 và 100 đồng thời (bảng Par(100) ở trên), **chưa chạy breaking-point search** nên chưa biết điểm gãy thật — ví dụ `/auth/login` và `/recipes/search` lỗi nặng ngay ở 100 nhưng điểm gãy thật của chúng gần như chắc chắn còn thấp hơn hẳn 100.

## Case 2-4 (AI) — cùng phương pháp, kèm eval_metrics khi có

| Endpoint | Vai trò | Seq avg (ms) | Seq p50 (ms) | Seq err% | Par(100) avg (ms) | Par(100) p50 (ms) | Par(100) err% | Max Stable Concurrency |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| `POST /ai/dish-recognition` | Nhận diện món ăn (AI vision) | 1949 | 1855 | 0% | 40324 | 37719 | **31%** | **48** |
| `POST /ai/ingredients/detect` | Nhận diện nguyên liệu (AI vision) | 1065 | 1013 | 0% | 16245 | 17021 | 0% | **≥ 256** (không gãy tới trần coarse-steps) |
| `/ai/chat/welcome` + `/ai/chat` ×100 | Trợ lý AI chat (gộp welcome+message) | 10801 | 9353 | 0% (101/101) | 36168 | 39072 | **33%** (127/190) | **5** |

Ba endpoint này nặng hơn hẳn nhóm CRUD (giây thay vì mili-giây), đúng như kỳ vọng với AI compute. Lưu ý Max Stable Concurrency của dish-recognition (48) và chat (5) đều **thấp hơn nhiều** so với mức 100 đo ở cột Par(100) — cột Par(100) chỉ là 1 điểm đo tại đúng 100 đồng thời để so chiếu với nhóm CRUD, không phải điểm gãy thật.

### Case 4 — tách riêng welcome vs. chat message (100 mẫu mỗi loại)

Hàng "Trợ lý AI chat" ở bảng trên **gộp chung** 1 welcome + 100 message/phiên vào cùng 1 mảng latency, nên p50 9.35s/39.07s dễ gây hiểu lầm (tưởng welcome mất 9s). Chạy lại tách riêng (`case4b_welcome_vs_message_test.py --samples 100`), với **message dùng mỗi phiên 1 tin nhắn đầu tiên** (không nhồi nhiều lượt vào 1 phiên) để đo đúng latency "gửi 1 tin, nhận 1 trả lời":

| Thao tác | Mode | avg | p50 | p95 | p99 | err% |
|---|---|---:|---:|---:|---:|---:|
| `POST /ai/chat/welcome` | sequential (100 phiên mới, nối tiếp) | 616 ms | 610 ms | 719 ms | 896 ms | 0% |
| `POST /ai/chat/welcome` | parallel (100 phiên mới, cùng lúc) | 16.3 s | 16.3 s | 30.7 s | 31.8 s | 0% |
| `POST /ai/chat` (1 tin/phiên mới) | sequential (100 phiên khác nhau, lần lượt từng phiên 1 tin) | 2.07 s | **2.42 s** | 2.65 s | 2.77 s | **0%** |
| `POST /ai/chat` (1 tin/phiên mới) | parallel (100 phiên khác, bắn 1 tin/phiên cùng lúc) | 45.8 s | **45.6 s** | 74.3 s | 77.9 s | **52%** |

**Kết luận rõ ràng:**
- `welcome` **rất nhanh và ổn định khi tuần tự** (p50 0.6s, 0% lỗi) — không phải nguồn gây ra con số 9.35s.
- `welcome` **chậm hẳn khi 100 phiên mở cùng lúc** (p50 16.3s, dù vẫn 0% lỗi) — bản thân việc khởi tạo phiên cũng không chịu tải tốt.
- **Trả lời 1 tin nhắn đầu tiên của phiên mới rất nhanh và hoàn toàn ổn định khi tuần tự: p50 2.42s, 0% lỗi** — tốt hơn nhiều so với con số 9.35s ở bảng gộp phía trên.
  > Lưu ý phương pháp: lần đo đầu tiên (đã bỏ) dùng **1 phiên duy nhất nhồi 100 tin nhắn liên tiếp**, ra p50=9.3s và **22% lỗi** — context hội thoại tích lũy qua nhiều lượt khiến model chậm và dễ lỗi dần, không phản ánh đúng trải nghiệm thực tế (đa số người dùng chỉ trao đổi vài lượt/phiên). Đo lại đúng cách — **100 phiên khác nhau, mỗi phiên 1 tin đầu** — cho kết quả tốt hơn hẳn (2.42s, 0% lỗi), nên đây mới là con số dùng để đánh giá latency "gửi 1 tin, nhận 1 trả lời" của case 4.
- Vấn đề thật sự của case 4 vẫn là **concurrency**, không phải latency 1 lượt chat: 100 phiên khác nhau bắn tin cùng lúc → p50 45.6s, **52% lỗi** — khớp với điểm gãy rất thấp (5 đồng thời) đo được ở `CONCURRENCY-RESULTS.md`.

### eval_metrics (server-side, chỉ case 2 & 3 — case 1/4/5 không trả field này)

Lấy từ `output_payload.eval_metrics` khi gọi kèm `eval=true` (model `EvalMetricsModel`). Trung bình trên các mẫu `ok`:

| Case | Mode | n | device | server latency (ms) | cpu% (process) | system cpu% | ram (MB) | system ram% |
|---|---|---:|---|---:|---:|---:|---:|---:|
| dish-recognition | sequential | 100 | cpu | 1120 | 705% | 72% | 2173 | 69% |
| dish-recognition | parallel(100) | 69 | cpu | 12180 | 700% | 73% | 2174 | 68% |
| ingredients/detect | sequential | 100 | cpu | 151 | 539% | 56% | 794 | 68% |
| ingredients/detect | parallel(100) | 100 | cpu | 1249 | 521% | 59% | 778 | 69% |

Cả 2 model đều chạy **trên CPU** (không có GPU), không đổi qua các mức tải. `system_ram_percent` đã ở mức 68-69% ngay từ đầu bước B (nối tiếp từ RAM đã tăng lên trong bước A chạy trước đó cùng phiên server — xem ghi chú leak RAM trong `CONCURRENCY-RESULTS.md`), không giảm giữa sequential và parallel dù cách nhau vài phút — củng cố thêm nghi vấn RAM không được giải phóng giữa các lượt gọi.

## Nguồn dữ liệu

- Case 1 (GET/PATCH `/users/me`): `case1_auth_crud_test.py --baseline --baseline-levels 1|100 --requests-per-worker 100|1`
- Case 2 (`dish-recognition`), Case 3 (`ingredients/detect`): tương tự, cộng `eval_metrics` (sửa trong `loadtest_lib.build_ai_job_request_fn` + `summarize_eval_metrics`)
- Case 4 (`chat`): `case4_llm_chat_test.py --baseline --baseline-levels 1|100 --requests-per-worker 100|1`
- Case 5 (8 endpoint còn lại): script mới `case5_interactive_endpoints_test.py --samples 100`
- Log đầy đủ: `test/load/logs/*_baseline_20261001_*.txt` và `test/load/logs/case5_interactive_endpoints_20261001_133859.txt`
