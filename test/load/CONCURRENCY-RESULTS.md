# Concurrency test — consolidated results

Run: breaking-point search 2026-09-24T13:11 → 13:45 (mở rộng case 2/3 lúc 13:46-13:54); baseline bổ sung 2026-09-27T11:32 → 11:36 (mức 1 đồng thời chạy lúc 12:02-12:03); **re-run sạch 2026-10-01T12:33 → 13:19** (xem [Run 2026-10-01](#run-2026-10-01--re-run-sạch-kèm-eval_metrics) bên dưới — đây là số liệu mới nhất, dùng số này thay vì bảng 2026-09-24 ở ngay dưới đây khi hai bên khác nhau).

Mỗi case chạy độc lập, tuần tự (không song song với case khác) để kết quả không bị nhiễu lẫn nhau. Log đầy đủ từng bước nằm trong `test/load/logs/`. Case 2 và 3 chạy thêm một pha mở rộng (32→256) vì pha đầu (1→32) chưa tìm ra điểm gãy.

> **Lưu ý:** có một lần chạy lại vào 2026-09-30 bị nhiễu do một session Claude Code khác (`foodhub-mobile-a7`) vô tình chạy cùng bộ test song song, khiến tải cộng dồn gấp đôi trên cùng 1 API/tài khoản. Toàn bộ số liệu lần đó (điểm gãy case1-PATCH tụt xuống 17, case4 tụt xuống 11 rồi 3, case3 lúc gãy ở 47 lúc không gãy tới 256) đã bị **loại bỏ**, không đưa vào báo cáo này. Số liệu dùng được gần nhất là lần chạy sạch 2026-10-01 bên dưới.

## Latency đo cái gì

Mọi con số latency trong báo cáo này = thời gian tính **từ lúc gửi request (`requests.get/post`) tới lúc nhận đủ response** — tức là thời gian server xử lý (DB/AI) + round-trip mạng giữa máy chạy test và API. **Không tính**:

- Thời gian phía client trước khi tạo request (chọn/nén ảnh trên điện thoại thật; trong bộ test này ảnh fixture đã nạp sẵn vào RAM nên cũng không có I/O đọc đĩa).
- Thời gian tải ảnh mà response chỉ **trỏ tới** — API dish recognition/ingredient detection trả về `image_url`/`annotated_image_url` (lưu trên Ceph), không trả bytes ảnh trực tiếp. Việc tải ảnh đó là một request riêng, tốc độ phụ thuộc mạng của người dùng cuối và việc ảnh đã được cache ở Ceph/CDN hay chưa (lần đầu load chậm hơn, các lần sau nếu cache hit sẽ nhanh hơn nhiều).

→ Độ trễ người dùng thật cảm nhận được **có thể cao hơn vài giây** so với số liệu ở đây, tùy đường truyền và tình trạng cache.

## Tóm tắt

| Case | API | Baseline p50 @ 1 / @ 5 / @ 10 đồng thời | Điểm gãy (đồng thời) | Loại lỗi chiếm ưu thế tại điểm gãy | Ghi chú |
|---|---|---|---:|---|---|
| 1 (GET) | `GET /users/me` | 0.32s / 1.55s / 1.86s | **97** | connection_error | So với STRESS-07: `/recipes/search` (công khai) vỡ ở 40-45, nhưng endpoint có auth này lại chịu tải cao hơn hẳn |
| 1 (PATCH) | `PATCH /users/me` | 0.38s / 1.37s / 1.92s | **95** | connection_error | Gần bằng GET — hợp lý vì cùng tài nguyên |
| 2 | `POST /ai/dish-recognition` | 1.72s / 8.56s / 9.90s | **48** | http_error | Latency đã tăng rất mạnh trước khi gãy (p50 2.7s ở 1 đồng thời → 34.8s ở 48) |
| 3 | `POST /ai/ingredients/detect` | 0.82s / 11.4s / 13.2s | **196** | connection_error | Chịu tải tốt hơn hẳn case 2 dù cùng là AI vision — có nhiễu nhẹ ở mức 128 trước khi vỡ hẳn ở 200+ |
| 4 | `POST /ai/chat/welcome` + `/ai/chat` | 3.78s / 21.0s / 41.5s | **28** | http_error | Thấp nhất trong 4 case — LLM chat là nút thắt cổ chai rõ rệt nhất; latency đã cao ngay cả ở tải trung bình |

Baseline dùng mức tải giả định 1, 5 và 10 người dùng đồng thời (không phải số liệu traffic thực đo được — nếu có Grafana/analytics thực tế nên thay bằng số đó). Case 2-4 chỉ chạy 1 request/worker ở baseline (để tiết kiệm chi phí compute AI thật), nên p95/p99 baseline của các case này chỉ mang tính tham khảo (mẫu nhỏ), không đáng tin bằng các số ở phần tìm điểm gãy (mẫu lớn hơn).

## Case 1 — GET /users/me

- Script: `case1_auth_crud_test.py --mode get`
- Log: `logs\case1_get_20260924_131135.txt`
- Exit code: 0

**Baseline** (`--baseline`, log `logs\case1_get_baseline_20260927_113239.txt`):

```
[   1 concurrent] ok=2/2  error_rate=0%  p50=315ms p95=315ms p99=315ms  throughput=3.51 req/s   [HEALTHY]
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
[   1 concurrent] ok=2/2  error_rate=0%  p50=381ms p95=381ms p99=381ms  throughput=2.79 req/s   [HEALTHY]
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
[   1 concurrent] ok=1/1  error_rate=0%  p50=1722ms p95=1722ms p99=1722ms  throughput=0.58 req/s   [HEALTHY]
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
[   1 concurrent] ok=1/1  error_rate=0%  p50=823ms p95=823ms p99=823ms  throughput=1.21 req/s   [HEALTHY]
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
[   1 concurrent] ok=3/3  error_rate=0%  p50=3779ms p95=9857ms p99=9857ms  throughput=0.20 req/s   [HEALTHY]
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

---

## Run 2026-10-01 — re-run sạch (kèm eval_metrics)

Chạy lại toàn bộ 5 case, **tuần tự hoàn toàn trong 1 tiến trình duy nhất** (không case nào chạy song song với case khác, không có session Claude nào khác chạy cùng lúc — đã kiểm tra bằng `ListAgents` trước khi chạy). Case 2 và 3 lần này gọi API với `eval=true` để lấy thêm `eval_metrics` (CPU/RAM phía server, model `EvalMetricsModel`) — case 1 và case 4 không trả field này (đã kiểm tra trực tiếp, case 4 trả `eval_metrics: null` dù có truyền `eval:true`) nên không có cột này.

### Tóm tắt

| Case | API | Điểm gãy (đồng thời) | So với 2026-09-24 | Loại lỗi chiếm ưu thế | Ghi chú |
|---|---|---:|---|---|---|
| 1 (GET) | `GET /users/me` | **không gãy tới 500** | tốt hơn nhiều (97 → ≥500) | — | Healthy toàn bộ dải coarse-steps mặc định, p50 cao nhất chỉ 1.45s @ 300 đồng thời |
| 1 (PATCH) | `PATCH /users/me` | **không gãy tới 500** | tốt hơn nhiều (95 → ≥500) | — | Tương tự GET |
| 2 | `POST /ai/dish-recognition` | **48** | giống hệt (48 → 48) | http_error | Điểm gãy ổn định qua 2 lần đo cách nhau 1 tuần; `system_ram_percent` tăng liên tục 54%→61% trong suốt lần chạy — nghi rò rỉ RAM tích lũy |
| 3 | `POST /ai/ingredients/detect` | **không gãy tới 256** | tốt hơn (196 → ≥256) | — | `system_ram_percent` tăng tiếp 59%→70% (nối từ case2) — cùng mẫu hình rò rỉ |
| 4 | `POST /ai/chat/welcome` + `/ai/chat` | **5** | **tệ đi rất nhiều** (28 → 5) | http_error | Đáng lo nhất: điểm gãy giảm còn ~1/5 so với 1 tuần trước, dù lần đo này sạch (không nhiễu). Cần điều tra phía backend (model LLM chậm đi, hoặc giới hạn tài nguyên bị siết lại) |

eval_metrics cho thấy mỗi request dish-recognition/ingredient-detect chạy **trên CPU** (không có GPU, `device: "cpu"`), dish-recognition chiếm ~700% CPU (bão hòa ~7/10 core) mỗi request, ingredient-detect nhẹ hơn (~520%). `system_ram_percent` không hề giảm giữa các mức tải trong cả case2 lẫn case3 (tăng liên tục từ 54% lên 70% suốt ~15 phút chạy AI liên tục) — cần theo dõi thêm xem có tự giải phóng sau khi ngừng tải hay là leak thật.

### Case 1 — GET /users/me (2026-10-01)

- Log: `logs\case1_get_20261001_123335.txt`

```
Phase 1 — coarse ramp: [5, 10, 20, 40, 80, 150, 300, 500]

[   5 concurrent] ok=10/10  error_rate=0%  avg=350ms p50=370ms p95=417ms p99=417ms    [HEALTHY]
[  10 concurrent] ok=20/20  error_rate=0%  avg=356ms p50=345ms p95=576ms p99=576ms    [HEALTHY]
[  20 concurrent] ok=40/40  error_rate=0%  avg=341ms p50=336ms p95=417ms p99=425ms    [HEALTHY]
[  40 concurrent] ok=80/80  error_rate=0%  avg=352ms p50=347ms p95=417ms p99=442ms    [HEALTHY]
[  80 concurrent] ok=160/160 error_rate=0%  avg=391ms p50=385ms p95=479ms p99=632ms   [HEALTHY]
[ 150 concurrent] ok=300/300 error_rate=0%  avg=517ms p50=518ms p95=696ms p99=762ms   [HEALTHY]
[ 300 concurrent] ok=600/600 error_rate=0%  avg=1569ms p50=1446ms p95=3506ms p99=4854ms [HEALTHY]
[ 500 concurrent] ok=1000/1000 error_rate=0% avg=1316ms p50=794ms p95=3344ms p99=4525ms [HEALTHY]

Chua tim thay diem qua tai trong dai coarse-steps da thu — tang them moc lon hon de do tiep.
```

### Case 1 — PATCH /users/me (2026-10-01)

- Log: `logs\case1_patch_20261001_123507.txt`

```
Phase 1 — coarse ramp: [5, 10, 20, 40, 80, 150, 300, 500]

[   5 concurrent] ok=10/10  error_rate=0%  avg=321ms p50=326ms
[  10 concurrent] ok=20/20  error_rate=0%  avg=329ms p50=322ms
[  20 concurrent] ok=40/40  error_rate=0%  avg=360ms p50=367ms
[  40 concurrent] ok=80/80  error_rate=0%  avg=355ms p50=359ms
[  80 concurrent] ok=160/160 error_rate=0% avg=373ms p50=371ms
[ 150 concurrent] ok=300/300 error_rate=0% avg=655ms p50=587ms  p95=1354ms p99=1653ms
[ 300 concurrent] ok=600/600 error_rate=0% avg=1049ms p50=830ms p95=2059ms p99=2605ms
[ 500 concurrent] ok=1000/1000 error_rate=0% avg=1518ms p50=1308ms p95=3587ms p99=4517ms

Chua tim thay diem qua tai trong dai coarse-steps da thu — tang them moc lon hon de do tiep.
```

### Case 2 — POST /ai/dish-recognition (2026-10-01)

- Log: `logs\case2_dish_recognition_20261001_123637.txt`

```
Phase 1 — coarse ramp: [1, 2, 4, 8, 16, 32, 48, 64, 96, 128, 192, 256]

[eval_metrics n=1]  latency=1139ms cpu=694% sys_cpu=71% ram=2085MB sys_ram=4286MB (54%)
[   1 concurrent] ok=1/1   error_rate=0%  avg=1868ms p50=1868ms  [HEALTHY]
[eval_metrics n=32] latency=10704ms cpu=703% sys_cpu=73% ram=2103MB sys_ram=4440MB (56%)
[  32 concurrent] ok=32/32 error_rate=0%  avg=19127ms p50=19670ms p95=35289ms  [HEALTHY]
[eval_metrics n=44] latency=11903ms cpu=703% sys_cpu=73% ram=2124MB sys_ram=4520MB (57%)
[  48 concurrent] ok=44  http_error=4/48  error_rate=8%  avg=26395ms p50=28725ms  [HEALTHY]
[eval_metrics n=47] latency=11688ms cpu=704% sys_cpu=73% ram=2133MB sys_ram=4552MB (57%)
[  64 concurrent] ok=47  http_error=17/64 error_rate=27% avg=28996ms p50=31665ms  [OVER BUDGET]

Phase 2 — binary search between 48 (healthy) and 64 (unhealthy)
[  56 concurrent] http_error=12/56  error_rate=21%  [OVER BUDGET]
[  52 concurrent] http_error=8/52   error_rate=15%  [OVER BUDGET]
[  50 concurrent] http_error=6/50   error_rate=12%  [OVER BUDGET]
[  49 concurrent] http_error=5/49   error_rate=10%  [OVER BUDGET]

==============================================================================
KET LUAN: muc dong thoi toi da con ON DINH = 48 nguoi dung cung luc
  - Tai 48 dong thoi: error_rate=8%, p50=28725ms, p95=47771ms, p99=49965ms
  - Tai 49 dong thoi bat dau vuot nguong loi (10%): error_rate=10% (ok=44, http_error=5)
==============================================================================
```

Điểm gãy **giống hệt lần đo 2026-09-24** (48 cả hai lần) — đây là con số ổn định, đáng tin cậy nhất trong cả 5 case. `system_ram_percent` tăng đều 54%→61% từ lúc 1 đồng thời tới lúc binary-search xong (~9 phút chạy liên tục).

### Case 3 — POST /ai/ingredients/detect (2026-10-01)

- Log: `logs\case3_ingredient_detection_20261001_124542.txt`

```
Phase 1 — coarse ramp: [1, 2, 4, 8, 16, 32, 48, 64, 96, 128, 192, 256]

[eval_metrics n=1]   latency=146ms  cpu=542% sys_cpu=56% ram=634MB sys_ram=4678MB (59%)
[   1 concurrent] ok=1/1 error_rate=0% avg=786ms p50=786ms
[eval_metrics n=96]  latency=1343ms cpu=512% sys_cpu=59% ram=667MB sys_ram=4942MB (62%)
[  96 concurrent] ok=96/96 error_rate=0% avg=11782ms p50=12213ms p95=18825ms
[eval_metrics n=192] latency=1759ms cpu=515% sys_cpu=59% ram=718MB sys_ram=5263MB (66%)
[ 192 concurrent] ok=192/192 error_rate=0% avg=21559ms p50=22163ms p95=35847ms
[eval_metrics n=256] latency=1920ms cpu=515% sys_cpu=59% ram=752MB sys_ram=5529MB (70%)
[ 256 concurrent] ok=256/256 error_rate=0% avg=28957ms p50=29543ms p95=48188ms p99=49460ms  [HEALTHY]

Chua tim thay diem qua tai trong dai coarse-steps da thu — tang them moc lon hon de do tiep.
```

Không gãy tới 256 (tốt hơn điểm gãy 196 của lần 2026-09-24) — nhưng `system_ram_percent` tiếp tục tăng từ 59% lên 70%, nối thẳng từ mức 61% cuối case 2 (cùng tiến trình server, không reset giữa 2 case) → tổng cộng RAM hệ thống tăng từ 54% lên 70% suốt cả case2+case3, không giảm lần nào. Đây là dấu hiệu rõ nhất của leak, cần backend team kiểm tra.

### Case 4 — POST /ai/chat/welcome + /ai/chat (2026-10-01)

- Log: `logs\case4_llm_chat_20261001_125118.txt`

```
Phase 1 — coarse ramp: [1, 2, 4, 8, 16, 32]

[   1 concurrent] ok=3/3   error_rate=0%  avg=20995ms p50=5919ms   p95=56266ms   [HEALTHY]
[   2 concurrent] ok=6/6   error_rate=0%  avg=36967ms p50=4306ms   p95=106548ms  [HEALTHY]
[   4 concurrent] ok=12/12 error_rate=0%  avg=56260ms p50=104281ms p95=113496ms  [HEALTHY]
[   8 concurrent] ok=20  http_error=4/24  error_rate=17% avg=68979ms p50=104727ms p95=125223ms [OVER BUDGET]

Phase 2 — binary search between 4 (healthy) and 8 (unhealthy)
[   6 concurrent] http_error=2/18 error_rate=11%  [OVER BUDGET]
[   5 concurrent] http_error=1/15 error_rate=7%   [HEALTHY]

==============================================================================
KET LUAN: muc dong thoi toi da con ON DINH = 5 nguoi dung cung luc
  - Tai 5 dong thoi: error_rate=7%, p50=95640ms, p95=125323ms, p99=125323ms
  - Tai 6 dong thoi bat dau vuot nguong loi (10%): error_rate=11% (ok=16, http_error=2)
==============================================================================
```

**Regression đáng chú ý:** điểm gãy tụt từ 28 (2026-09-24) xuống còn **5** đồng thời — chỉ còn 1/5. Lần đo này sạch (1 tiến trình duy nhất, không session khác chạy cùng, đã xác nhận qua `ListAgents`), nên khác với lần 2026-09-30 bị nhiễu, con số 5 này **đáng tin**. p50 ở ngay mức 4 đồng thời đã là 104s — LLM chat đang là nút thắt nghiêm trọng nhất trong cả hệ thống, cần ưu tiên điều tra (model quá tải, hết quota provider, hay giới hạn tài nguyên bị siết). Lưu ý: ở chế độ **tuần tự** (1 user, 100 tin nhắn liên tiếp — xem bảng Interactive Latency), latency vẫn ổn (p50 ~9.4s/tin nhắn, 0% lỗi) — vấn đề nằm ở **nhiều session đồng thời**, không phải bản thân model chậm.

