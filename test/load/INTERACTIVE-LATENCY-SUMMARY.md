# Interactive Latency — 100-sample Summary

Nguồn số liệu: `INTERACTIVE-LATENCY-100-RESULTS.md` (run 2026-10-01T12:33 → 13:46, 100 sample/endpoint, sequential = concurrency 1, parallel = concurrency 100). File này trình bày lại cùng dữ liệu dưới dạng gọn hơn để đưa trực tiếp vào báo cáo/luận văn.

## 1. Interactive Response Time — CRUD / Regular Endpoints

| Endpoint | Role | Sequential p50 | Sequential Err. | Parallel (100) p50 | Parallel Err. | Max Stable Concurrency |
|---|---|---:|---:|---:|---:|---:|
| `POST /auth/login` | Login | 529 ms | 0% | 20.24 s | **94%** | not tested (breaking-point search not run for this endpoint) |
| `GET /users/me` | Load profile | 340 ms | 0% | 357 ms | 0% | **≥ 500** (no break found up to coarse-step ceiling) |
| `PATCH /users/me` | Update profile | 331 ms | 0% | 396 ms | 0% | **≥ 500** (no break found up to coarse-step ceiling) |
| `GET /recipes?limit=20` | Browse recipes | 345 ms | 0% | 2.61 s | 0% | not tested |
| `GET /recipes/search` | Search recipes | 441 ms | 0% | 20.22 s | **79%** | not tested |
| `GET /recipes/{id}` | Recipe detail | 335 ms | 0% | 403 ms | 0% | not tested |
| `GET /favorites` | Favorites | 334 ms | 0% | 423 ms | 0% | not tested |
| `GET /meal-plans/{date}` | Daily meal plan | 243 ms | 0% | 296 ms | 0% | not tested |
| `GET /meal-plans/{date}/shopping-list` | Shopping list | 235 ms | 0% | 302 ms | 0% | not tested |
| `GET /feedback` | Feedback history | 237 ms | 0% | 340 ms | 0% | not tested |

**Nhận xét:** Với 100 mẫu tuần tự, tất cả endpoint đều có p50 < 2 s, đáp ứng NFR2. Tuy nhiên, ở burst 100 concurrent, `POST /auth/login` và `GET /recipes/search` có error rate rất cao, trong khi các endpoint còn lại vẫn 0%. Cột "Max Stable Concurrency" chỉ có số liệu cho `GET`/`PATCH /users/me` (case 1) — 8 endpoint còn lại (case 5) mới chỉ đo ở 2 mức 1 và 100 đồng thời, chưa chạy breaking-point search (coarse ramp + binary search) để tìm điểm gãy thật.

## 2. Interactive Response Time — AI Endpoints

| Endpoint | Role | Sequential p50 | Sequential Err. | Parallel (100) p50 | Parallel Err. | Max Stable Concurrency |
|---|---|---:|---:|---:|---:|---:|
| `POST /ai/dish-recognition` | Dish recognition | 1.86 s | 0% | 37.72 s | **31%** | **48** |
| `POST /ai/ingredients/detect` | Ingredient detection | 1.01 s | 0% | 17.02 s | 0% | **≥ 256** (no break found up to coarse-step ceiling) |
| `/ai/chat/welcome` + `/ai/chat` | AI assistant (gộp welcome+message)¹ | 9.35 s | 0% | 39.07 s | **33%** | **5** |

Max Stable Concurrency lấy từ breaking-point search (`CONCURRENCY-RESULTS.md`, run 2026-10-01) — mức đồng thời cao nhất mà error rate vẫn ≤ 10%. Lưu ý mức này thấp hơn nhiều so với "Parallel (100)" ở trên với dish-recognition (48) và chat (5): bảng Parallel(100) chỉ là 1 điểm đo tại đúng 100 đồng thời (để so chiếu với nhóm CRUD), không phải điểm gãy thật — điểm gãy thật của 2 endpoint này còn thấp hơn hẳn 100.

¹ Hàng này gộp 1 welcome + N message/phiên vào cùng 1 mảng latency nên dễ hiểu lầm — xem bảng 2b bên dưới để thấy welcome và message tách riêng.

### 2b. AI Chat — tách riêng welcome vs. chat message (100 mẫu mỗi loại)

Message đo đúng cách: **mỗi phiên 1 tin nhắn đầu tiên** (100 phiên khác nhau), không nhồi nhiều lượt vào 1 phiên.

| Thao tác | Mode | p50 | p95 | Err. |
|---|---|---:|---:|---:|
| `POST /ai/chat/welcome` | Sequential (100 phiên mới, nối tiếp) | 0.61 s | 0.72 s | 0% |
| `POST /ai/chat/welcome` | Parallel (100 phiên mới, cùng lúc) | 16.3 s | 30.7 s | 0% |
| `POST /ai/chat` (1 tin/phiên mới) | Sequential (100 phiên khác nhau, lần lượt từng phiên) | **2.42 s** | 2.65 s | **0%** |
| `POST /ai/chat` (1 tin/phiên mới) | Parallel (100 phiên khác, 1 tin/phiên cùng lúc) | **45.6 s** | 74.3 s | **52%** |

**Kết luận:** welcome tự nó rất nhanh và ổn định khi tuần tự (0.61s, 0% lỗi) nhưng chậm hẳn khi 100 phiên mở cùng lúc (16.3s). Con số "9.35s" trong bảng gộp phía trên thực chất bị kéo lên bởi một lỗi phương pháp ban đầu: nhồi 100 tin nhắn liên tiếp vào **cùng 1 phiên** (context hội thoại tích lũy → chậm dần, lỗi dần, ra 22% lỗi) — không phản ánh đúng cách người dùng thật trò chuyện. Đo lại đúng cách (100 phiên khác nhau, mỗi phiên 1 tin đầu) cho kết quả **tốt hơn hẳn: p50 2.42s, 0% lỗi** — latency 1 lượt chat thực ra khá nhanh và ổn định. Vấn đề thật sự của case 4 nằm hoàn toàn ở **concurrency**: khi 100 phiên khác nhau bắn tin cùng lúc, p50 vọt lên 45.6s và lỗi tới **52%**, khớp với điểm gãy rất thấp (5 đồng thời) đo được trong breaking-point search.

## 3. Server-side eval_metrics

| Case | Mode | Samples | Device | Server Latency | CPU / request | RAM / request | System RAM |
|---|---|---:|---|---:|---:|---:|---:|
| Dish recognition | Sequential | 100 | CPU | 1.12 s | 705% | 2.17 GB | 69% |
| Dish recognition | Parallel 100 | 69 | CPU | 12.18 s | 700% | 2.17 GB | 68% |
| Ingredient detection | Sequential | 100 | CPU | 151 ms | 539% | 794 MB | 68% |
| Ingredient detection | Parallel 100 | 100 | CPU | 1.25 s | 521% | 778 MB | 69% |

## 4. Bảng kết luận ngắn cho NFR2

| Nhóm | Sequential | Parallel (100) | Max Stable Concurrency | Nhận định |
|---|---|---|---:|---|
| CRUD / Regular (`/users/me`) | p50 331–340 ms, 0% lỗi | 357–396 ms, 0% lỗi | **≥ 500** | Đáp ứng tốt cả tuần tự lẫn đồng thời cao |
| CRUD / Regular (còn lại) | p50 235–529 ms, 0% lỗi | Hầu hết <500 ms, 0% lỗi (trừ login/search) | chưa đo | login/search lỗi nặng khi burst 100, chưa rõ điểm gãy thật thấp tới đâu |
| Dish recognition | p50 1.86 s, 0% lỗi | p50 37.72 s, 31% lỗi | **48** | Chi phí CPU cao, suy giảm mạnh khi concurrent |
| Ingredient detection | p50 1.01 s, 0% lỗi | p50 17.02 s, 0% lỗi | **≥ 256** | Chậm hơn đáng kể dưới tải nhưng chưa phát sinh lỗi |
| AI Chat (gộp welcome+message) | p50 9.35 s, 0% lỗi | p50 39.07 s, 33% lỗi | **5** | Số liệu gộp bị lệch do lỗi phương pháp (nhồi 100 tin vào 1 phiên) — xem bảng 2b: đo đúng cách thì sequential rất nhanh (2.42s, 0% lỗi), vấn đề thật sự chỉ nằm ở concurrency (parallel 45.6s, 52% lỗi) |

Một điểm rất đáng đưa vào luận văn: bảng này giúp phân biệt rõ latency của một người dùng và khả năng chịu tải đồng thời. Đặc biệt, khi tách riêng welcome và message với đúng phương pháp — **mỗi phiên 1 tin nhắn đầu tiên** (bảng 2b): welcome nhanh và ổn định ở chế độ tuần tự (0.61s, 0% lỗi), và trả lời chat (1 tin/phiên mới) **cũng nhanh và ổn định không kém** — p50 2.42s, 0% lỗi. Vấn đề chỉ xuất hiện khi 100 phiên khác nhau bắn tin nhắn cùng lúc: p50 vọt lên 45.6s, lỗi 52%. Vì vậy vấn đề được quan sát chủ yếu là **concurrency/scalability**, không phải single-request latency hay độ ổn định của bản thân việc trả lời chat.
