# Concurrency test — consolidated results

Run: breaking-point search 2026-09-24T13:11 → 13:45 (mở rộng case 2/3 lúc 13:46-13:54); baseline bổ sung 2026-09-27T11:32 → 11:36

Mỗi case chạy độc lập, tuần tự (không song song với case khác) để kết quả không bị nhiễu lẫn nhau. Log đầy đủ từng bước nằm trong `test/load/logs/`. Case 2 và 3 chạy thêm một pha mở rộng (32→256) vì pha đầu (1→32) chưa tìm ra điểm gãy.

## Latency đo cái gì

Mọi con số latency trong báo cáo này = thời gian tính **từ lúc gửi request (`requests.get/post`) tới lúc nhận đủ response** — tức là thời gian server xử lý (DB/AI) + round-trip mạng giữa máy chạy test và API. **Không tính**:

- Thời gian phía client trước khi tạo request (chọn/nén ảnh trên điện thoại thật; trong bộ test này ảnh fixture đã nạp sẵn vào RAM nên cũng không có I/O đọc đĩa).
- Thời gian tải ảnh mà response chỉ **trỏ tới** — API dish recognition/ingredient detection trả về `image_url`/`annotated_image_url` (lưu trên Ceph), không trả bytes ảnh trực tiếp. Việc tải ảnh đó là một request riêng, tốc độ phụ thuộc mạng của người dùng cuối và việc ảnh đã được cache ở Ceph/CDN hay chưa (lần đầu load chậm hơn, các lần sau nếu cache hit sẽ nhanh hơn nhiều).

→ Độ trễ người dùng thật cảm nhận được **có thể cao hơn vài giây** so với số liệu ở đây, tùy đường truyền và tình trạng cache.

## Tóm tắt

| Case | API | Baseline p50 @ 5 / @ 10 đồng thời | Điểm gãy (đồng thời) | Loại lỗi chiếm ưu thế tại điểm gãy | Ghi chú |
|---|---|---|---:|---|---|
| 1 (GET) | `GET /users/me` | 1.55s / 1.86s | **97** | connection_error | So với STRESS-07: `/recipes/search` (công khai) vỡ ở 40-45, nhưng endpoint có auth này lại chịu tải cao hơn hẳn |
| 1 (PATCH) | `PATCH /users/me` | 1.37s / 1.92s | **95** | connection_error | Gần bằng GET — hợp lý vì cùng tài nguyên |
| 2 | `POST /ai/dish-recognition` | 8.56s / 9.90s | **48** | http_error | Latency đã tăng rất mạnh trước khi gãy (p50 2.7s ở 1 đồng thời → 34.8s ở 48) |
| 3 | `POST /ai/ingredients/detect` | 11.4s / 13.2s | **196** | connection_error | Chịu tải tốt hơn hẳn case 2 dù cùng là AI vision — có nhiễu nhẹ ở mức 128 trước khi vỡ hẳn ở 200+ |
| 4 | `POST /ai/chat/welcome` + `/ai/chat` | 21.0s / 41.5s | **28** | http_error | Thấp nhất trong 4 case — LLM chat là nút thắt cổ chai rõ rệt nhất; latency đã cao ngay cả ở tải trung bình |

Baseline dùng mức tải giả định 5 và 10 người dùng đồng thời (không phải số liệu traffic thực đo được — nếu có Grafana/analytics thực tế nên thay bằng số đó). Case 2-4 chỉ chạy 1 request/worker ở baseline (để tiết kiệm chi phí compute AI thật), nên p95/p99 baseline của các case này chỉ mang tính tham khảo (mẫu nhỏ), không đáng tin bằng các số ở phần tìm điểm gãy (mẫu lớn hơn).

## Case 1 — GET /users/me

- Script: `case1_auth_crud_test.py --mode get`
- Log: `logs\case1_get_20260924_131135.txt`
- Exit code: 0

**Baseline** (`--baseline`, log `logs\case1_get_baseline_20260927_113239.txt`):

```
[   5 concurrent] ok=10/10  error_rate=0%  p50=1554ms p95=1885ms p99=1885ms  throughput=2.85 req/s   [HEALTHY]
[  10 concurrent] ok=20/20  error_rate=0%  p50=1863ms p95=3050ms p99=3050ms  throughput=4.64 req/s   [HEALTHY]
```

**Tìm điểm gãy:**

```
==============================================================================
KET LUAN: muc dong thoi toi da con ON DINH = 97 nguoi dung cung luc
  - Tai 97 dong thoi: error_rate=6%, p50=12239ms, p95=16003ms, p99=17104ms
  - Tai 98 dong thoi bat dau vuot nguong loi (10%): error_rate=12% (ok=173, http_error=0, timeout=0, connection_error=23, job_failed=0)
==============================================================================

(Log day du: E:\VisualStudioCode\FoodHub_Mobile\test\load\logs\case1_get_20260924_131135.txt)
```

## Case 1 — PATCH /users/me

- Script: `case1_auth_crud_test.py --mode patch`
- Log: `logs\case1_patch_20260924_131905.txt`
- Exit code: 0

**Baseline** (`--baseline`, log `logs\case1_patch_baseline_20260927_113305.txt`):

```
[   5 concurrent] ok=10/10  error_rate=0%  p50=1368ms p95=2056ms p99=2056ms  throughput=2.97 req/s   [HEALTHY]
[  10 concurrent] ok=20/20  error_rate=0%  p50=1917ms p95=2793ms p99=2793ms  throughput=4.43 req/s   [HEALTHY]
```

**Tìm điểm gãy:**

```
==============================================================================
KET LUAN: muc dong thoi toi da con ON DINH = 95 nguoi dung cung luc
  - Tai 95 dong thoi: error_rate=9%, p50=14385ms, p95=15687ms, p99=16256ms
  - Tai 96 dong thoi bat dau vuot nguong loi (10%): error_rate=19% (ok=156, http_error=0, timeout=0, connection_error=36, job_failed=0)
==============================================================================

(Log day du: E:\VisualStudioCode\FoodHub_Mobile\test\load\logs\case1_patch_20260924_131905.txt)
```

## Case 2 — POST /ai/dish-recognition

- Script: `case2_dish_recognition_test.py`
- Logs: `logs\case2_dish_recognition_20260924_132637.txt` (pha 1: 1-32), `logs\case2_dish_recognition_20260924_134602.txt` (pha 2 mở rộng: 32-256, tìm ra điểm gãy)
- Exit code: 0

**Baseline** (`--baseline`, log `logs\case2_dish_recognition_baseline_20260927_113330.txt`, 1 request/worker):

```
[   5 concurrent] ok=5/5  error_rate=0%  p50=8563ms p95=14739ms p99=14739ms  throughput=0.34 req/s   [HEALTHY]
[  10 concurrent] ok=10/10  error_rate=0%  p50=9897ms p95=24675ms p99=24675ms  throughput=0.41 req/s   [HEALTHY]
```

**Tìm điểm gãy:**

Pha 1 (1→32) không tìm được điểm gãy — mọi mức đều healthy nhưng độ trễ tăng rất mạnh (p50 từ 2.7s lên 25.6s). Chạy tiếp pha 2 từ 32 lên cao hơn:

```
Phase 1 — coarse ramp: [32, 48, 64, 96, 128, 192, 256]

[  32 concurrent] ok=32/32  error_rate=0%  p50=23630ms p95=40470ms p99=40610ms  throughput=0.79 req/s   [HEALTHY]
[  48 concurrent] ok=44  http_error=4/48  error_rate=8%  p50=34770ms p95=53808ms p99=56188ms  throughput=0.85 req/s   [HEALTHY]
[  64 concurrent] ok=45  http_error=19/64  error_rate=30%  p50=40010ms p95=57134ms p99=59335ms  throughput=1.08 req/s   [OVER BUDGET]

Phase 2 — binary search between 48 (healthy) and 64 (unhealthy)

[  56 concurrent] ok=44  http_error=12/56  error_rate=21%  [OVER BUDGET]
[  52 concurrent] ok=44  http_error=8/52   error_rate=15%  [OVER BUDGET]
[  50 concurrent] ok=43  http_error=7/50   error_rate=14%  [OVER BUDGET]
[  49 concurrent] ok=44  http_error=5/49   error_rate=10%  [OVER BUDGET]

==============================================================================
KET LUAN: muc dong thoi toi da con ON DINH = 48 nguoi dung cung luc
  - Tai 48 dong thoi: error_rate=8%, p50=34770ms, p95=53808ms, p99=56188ms
  - Tai 49 dong thoi bat dau vuot nguong loi (10%): error_rate=10% (http_error=5)
==============================================================================
```

Lỗi ở điểm gãy toàn bộ là `http_error` (không phải timeout/connection_error) — nghẽn thể hiện qua response lỗi rõ ràng từ server, không phải treo kết nối.

## Case 3 — POST /ai/ingredients/detect

- Script: `case3_ingredient_detection_test.py`
- Logs: `logs\case3_ingredient_detection_20260924_132927.txt` (pha 1: 1-32), `logs\case3_ingredient_detection_20260924_135405.txt` (pha 2 mở rộng: 32-256, tìm ra điểm gãy)
- Exit code: 0

**Baseline** (`--baseline`, log `logs\case3_ingredient_detection_baseline_20260927_113426.txt`, 1 request/worker):

```
[   5 concurrent] ok=5/5  error_rate=0%  p50=11412ms p95=14574ms p99=14574ms  throughput=0.34 req/s   [HEALTHY]
[  10 concurrent] ok=10/10  error_rate=0%  p50=13218ms p95=25260ms p99=25260ms  throughput=0.40 req/s   [HEALTHY]
```

**Tìm điểm gãy:**

Pha 1 (1→32) cũng không tìm được điểm gãy (p50 từ 1.8s lên 10.4s, vẫn 0% lỗi). Chạy tiếp pha 2:

```
Phase 1 — coarse ramp: [32, 48, 64, 96, 128, 192, 256]

[  32 concurrent] ok=32/32   error_rate=0%  p50=7911ms  p95=9853ms   throughput=3.19 req/s   [HEALTHY]
[  48 concurrent] ok=48/48   error_rate=0%  p50=11762ms p95=14998ms  throughput=3.19 req/s   [HEALTHY]
[  64 concurrent] ok=64/64   error_rate=0%  p50=15046ms p95=19315ms  throughput=3.27 req/s   [HEALTHY]
[  96 concurrent] ok=96/96   error_rate=0%  p50=14379ms p95=22846ms  throughput=3.84 req/s   [HEALTHY]
[ 128 concurrent] ok=122  connection_error=6/128    error_rate=5%   throughput=3.85 req/s   [HEALTHY]
[ 192 concurrent] ok=192/192  error_rate=0%  p50=18169ms p95=26803ms  throughput=4.51 req/s   [HEALTHY]
[ 256 concurrent] ok=144  connection_error=112/256  error_rate=44%  throughput=6.04 req/s   [OVER BUDGET]

Phase 2 — binary search between 192 (healthy) and 256 (unhealthy)

[ 224 concurrent] ok=142  connection_error=82/224  error_rate=37%  [OVER BUDGET]
[ 208 concurrent] ok=154  connection_error=54/208  error_rate=26%  [OVER BUDGET]
[ 200 concurrent] ok=136  connection_error=64/200  error_rate=32%  [OVER BUDGET]
[ 196 concurrent] ok=179  connection_error=17/196  error_rate=9%   [HEALTHY]
[ 198 concurrent] ok=177  connection_error=21/198  error_rate=11%  [OVER BUDGET]
[ 197 concurrent] ok=172  connection_error=25/197  error_rate=13%  [OVER BUDGET]

==============================================================================
KET LUAN: muc dong thoi toi da con ON DINH = 196 nguoi dung cung luc
  - Tai 196 dong thoi: error_rate=9%, p50=15399ms, p95=22351ms, p99=24136ms
  - Tai 197 dong thoi bat dau vuot nguong loi (10%): error_rate=13% (connection_error=25)
==============================================================================
```

Lưu ý: có nhiễu nhẹ (128 lỗi 5% rồi 192 lại về 0% lỗi) trước khi thật sự vỡ ở dải 200+ — không phải suy giảm tuyến tính đều, giống kiểu "vỡ" của STRESS-07 hơn là suy giảm dần. Lỗi ở điểm gãy là `connection_error` (mất kết nối), không phải `http_error` như case 2.

## Case 4 — POST /ai/chat/welcome + /ai/chat

- Script: `case4_llm_chat_test.py `
- Log: `logs\case4_llm_chat_20260924_133116.txt`
- Exit code: 0

**Baseline** (`--baseline`, log `logs\case4_llm_chat_baseline_20260927_113524.txt`, welcome + 2 tin nhắn/worker):

```
[   5 concurrent] ok=15/15  error_rate=0%  p50=20984ms p95=47846ms p99=47846ms  throughput=0.20 req/s   [HEALTHY]
[  10 concurrent] ok=30/30  error_rate=0%  p50=41490ms p95=94981ms p99=95040ms  throughput=0.23 req/s   [HEALTHY]
```

Đáng chú ý: dù 0% lỗi (chưa "gãy"), p95 đã lên tới **95 giây** chỉ với 10 người dùng đồng thời — tệ hơn nhiều so với p95=54s tại 28 đồng thời trong pha tìm điểm gãy dưới đây (baseline chỉ gửi 1 tin nhắn/worker cùng lúc nên có thể trùng giờ cao điểm ngẫu nhiên của model; nên chạy lại baseline này vài lần vào các thời điểm khác nhau trước khi kết luận chắc chắn).

**Tìm điểm gãy:**

```
==============================================================================
KET LUAN: muc dong thoi toi da con ON DINH = 28 nguoi dung cung luc
  - Tai 28 dong thoi: error_rate=8%, p50=35186ms, p95=53915ms, p99=58970ms
  - Tai 29 dong thoi bat dau vuot nguong loi (10%): error_rate=15% (ok=67, http_error=12, timeout=0, connection_error=0, job_failed=0)
==============================================================================

(Log day du: E:\VisualStudioCode\FoodHub_Mobile\test\load\logs\case4_llm_chat_20260924_133116.txt)
```

