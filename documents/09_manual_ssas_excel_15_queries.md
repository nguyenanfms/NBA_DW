# Hướng dẫn thực hiện thủ công 15 câu OLAP bằng SSAS và Excel PivotTable

Tài liệu bám theo `08_olap_queries.md` và cấu trúc project `nba_datawarehouse_ssas` hiện tại. Sau phần chuẩn bị, mỗi câu được thực hiện bằng chọn trường, kéo thả, lọc và sắp xếp. SQL và MDX trong phần chuẩn bị chỉ dùng để định nghĩa mô hình/chỉ số một lần trong giao diện thiết kế; không phải 15 câu truy vấn cần chạy.

**Trạng thái cập nhật ngày 15/10/2026:** các bổ sung ở mục 2.2–2.5 đã được áp dụng vào project hiện tại; không cần thêm lại. Bản build gần nhất thành công với 0 lỗi, 10 cảnh báo thiết kế. Nguồn `NBA_DW` đã truy cập được và đã đối chiếu một số truy vấn với cube đang chạy. Sau các thay đổi hierarchy/Attribute Relationships mới nhất, cần Deploy và Process lại để server nhận đúng cấu hình trong project. Tên menu có thể khác nhẹ giữa các phiên bản Visual Studio/Excel.

Bản sao lưu trước thay đổi được giữ cục bộ trong thư mục `backups/` và không đưa lên Git. Các mục chuẩn bị bên dưới mô tả trạng thái ban đầu để giải thích cấu hình và phục vụ thao tác lại trên bản project gốc. Hierarchy và khóa thời gian hiện tại được ghi trong `10_ssas_cube_update_status.md`.

## 1. Các phần đã bổ sung so với cube ban đầu

| Thành phần | Hiện trạng trước khi bổ sung | Phần bổ sung để dùng đủ 15 câu |
| --- | --- | --- |
| Đội và đối thủ | Có `Dim Team`, có `Opponent` cùng dùng `Dim Team.dim` | Giữ hai vai trò riêng khi lọc đối đầu |
| Sân nhà, thắng/thua | Có measures `Is Home`, `Is Win`; chưa có attributes tương ứng | Thêm attributes `Is Home`, `Is Win` vào dimension `Fact Team Game` |
| Mã trận đấu | Có cột `game_id` trong DSV, chưa có attribute | Thêm `Game Id` để gom hai đội của cùng trận |
| Trung bình, tỷ lệ | Chưa thấy MDX script trong file cube | Tạo các calculated measures ở mục 2.4 |
| Cầu thủ–trận | `Player Game` chỉ có quan hệ Regular với Player và Team | Thêm liên kết qua `fact_id` để lọc đúng cầu thủ ra sân trong từng trận |
| Nhãn mùa giải | ETL dùng ép chuỗi `season_id` cho `season_display` | Thêm `Season Label` để chọn chung `2022-23` cho các loại mùa |
| Kỷ nguyên | ETL so sánh trực tiếp mã `season_id`, có thể phân loại sai các loại mùa | Thêm `Era Label` dựa trên năm bắt đầu mùa |

Một dòng `fact_team_game` là **một đội trong một trận**, không phải toàn bộ trận. `Fact Team Game Count` đếm lượt đội; `Unique Games` bên dưới đếm trận không trùng.

## 2. Chuẩn bị một lần trong Visual Studio / SSAS

### 2.1. Mở project và kiểm tra kết nối

1. Mở project `nba_datawarehouse_ssas.dwproj` bằng Visual Studio có extension Analysis Services Projects.
2. Mở **Data Sources → NBA DW.ds → Edit**. Chọn SQL Server Database Engine đang chứa dữ liệu `NBA_DW` của bạn và **Test Connection**.
3. Chuột phải project → **Properties → Deployment**. Chọn instance **Analysis Services Multidimensional** để triển khai; ghi lại tên instance và tên database triển khai.
4. SQL Server chứa bảng và SSAS chứa cube là hai dịch vụ khác nhau. Chuỗi `DESKTOP-AHL2RE7\SQLEXPRESS` trong project hiện là kết nối nguồn quan hệ, không chứng minh đó là địa chỉ SSAS.
5. Mở `NBA DW.cube`. Những phần sẽ dùng: **Cube Structure**, **Dimension Usage**, **Calculations**, **Browser**.

### 2.2. Thêm nhãn mùa giải, kỷ nguyên và bộ đếm dữ liệu hợp lệ

Mở **Data Source Views → NBA DW.dsv**. Chuột phải bảng tương ứng → **New Named Calculation**. Nhập tên và biểu thức dưới đây. Các cột này chỉ nằm trong DSV, không sửa dữ liệu SQL Server.

**Bảng `dim_season`:**

Tên `season_label`:

```sql
CAST(season_id % 10000 AS varchar(4)) + '-'
+ RIGHT('0' + CAST((season_id % 10000 + 1) % 100 AS varchar(2)), 2)
```

Tên `era_label` — giữ các mốc năm mà ETL hiện đang muốn áp dụng:

```sql
CASE
  WHEN season_id % 10000 >= 2014 THEN '3-Point Revolution Era'
  WHEN season_id % 10000 >= 1999 THEN 'Pace Space Era'
  WHEN season_id % 10000 >= 1980 THEN 'Jordan Era'
  ELSE 'Early Pioneer Era'
END
```

Các công thức trên áp dụng cho quy ước mã mùa NBA trong project: phần năm là `season_id % 10000`, ví dụ `22022` là Regular Season bắt đầu năm 2022. Nếu dữ liệu nạp thực tế dùng quy ước khác, kiểm tra mã trước khi dùng.

Mở `Dim Season.dim` → **Dimension Structure**, kéo hai cột mới từ DSV sang **Attributes**, đặt tên hiển thị `Season Label`, `Era Label`. Các câu bên dưới sử dụng hai attributes này. Không thay `Dim Date.Year Number` bằng `Season Label`: một trường là năm lịch, trường kia là mùa thi đấu.

**Bảng `fact_team_game`:** tạo các Named Calculations sau, rồi mở cube → **Cube Structure → New Measure**, chọn **Sum** cho mỗi cột và đặt tên measure như bảng.

| Tên cột mới | Expression | Tên measure |
| --- | --- | --- |
| `ast_valid` | `CASE WHEN ast IS NULL THEN 0 ELSE 1 END` | `Ast Valid Count` |
| `tov_valid` | `CASE WHEN tov IS NULL THEN 0 ELSE 1 END` | `Tov Valid Count` |
| `fg3m_valid` | `CASE WHEN fg3m IS NULL THEN 0 ELSE 1 END` | `Fg3m Valid Count` |
| `fg3a_valid` | `CASE WHEN fg3a IS NULL THEN 0 ELSE 1 END` | `Fg3a Valid Count` |
| `paint_valid` | `CASE WHEN pts_paint IS NULL THEN 0 ELSE 1 END` | `Paint Valid Count` |
| `fast_break_valid` | `CASE WHEN pts_fast_break IS NULL THEN 0 ELSE 1 END` | `Fast Break Valid Count` |

Những bộ đếm này giúp trung bình khớp `AVG` của SQL khi cột có NULL. Nếu ETL đã thay dữ liệu thiếu bằng 0 trước khi nạp, không thể phân biệt số 0 thật và dữ liệu thiếu bằng các bộ đếm này; kết quả phản ánh dữ liệu đã nạp.

### 2.3. Thêm thuộc tính trận và measure đếm trận

1. Mở `Fact Team Game.dim` → **Dimension Structure**.
2. Từ bảng `fact_team_game` trong DSV, kéo `game_id`, `is_home`, `is_win` sang **Attributes**.
3. Đặt tên hiển thị: `Game Id`, `Is Home`, `Is Win`. Giữ `Fact Id` là khóa dimension. Ba trường mới là các attribute riêng, không tạo hierarchy `Is Home → Is Win`.
4. Kiểm tra `AttributeHierarchyEnabled = True`, `AttributeHierarchyVisible = True` cho các trường mới. Giữ quan hệ thuộc tính từ khóa `Fact Id` tới các attributes mới.
5. Mở cube → **Cube Structure** → chuột phải vùng measures → **New Measure**.
6. Chọn source `fact_team_game.game_id`, **Usage = Distinct count**, đặt tên measure `Unique Games`.
7. SSAS thường tạo measure group riêng cho Distinct Count. Trong **Dimension Usage**, cấu hình nhóm mới theo nguồn `fact_team_game`: Date qua `date_key`, Season qua `season_id`, Team qua `team_id`, Opponent qua `opponent_id`, Arena qua `arena_key`. Với `Fact Team Game`, dùng **Fact relationship**, granularity `Fact Id` qua `fact_id`. Các quan hệ khác là **Regular**, khóa đúng theo dimension tương ứng.

Không lấy `Fact Team Game Count / 2` làm bộ đếm trận dùng chung: phép chia đó chỉ đúng khi tập đang chọn luôn có đủ hai đội mỗi trận.

### 2.4. Tạo các chỉ số trung bình và tỷ lệ

Trong `NBA DW.cube` → **Calculations → New Calculated Member**:

1. **Parent hierarchy = Measures**.
2. **Name** nhập tên trong bảng, có thể đặt trong ngoặc vuông, ví dụ `[Win Rate]`.
3. **Expression** nhập biểu thức tương ứng.
4. **Format string** đặt `0.00%` cho tỷ lệ; `0.00` cho trung bình; `#,##0` cho số đếm.
5. Giữ **Visible = True**. Lặp lại cho tất cả measures cần dùng.
6. Kiểm tra Script View có lệnh `CALCULATE;` trước các lệnh định nghĩa calculated members. Giữ một lệnh, tránh thêm trùng nếu công cụ đã tạo sẵn.

Đây là thao tác tạo calculated members bằng giao diện [Calculations của SSAS](https://learn.microsoft.com/ja-jp/analysis-services/multidimensional-tutorial/lesson-6-1-defining-calculated-members?view=sql-analysis-services-2025).

| Name | Expression | Format |
| --- | --- | --- |
| `Win Rate` | `IIF([Measures].[Fact Team Game Count] = 0, NULL, [Measures].[Is Win] / [Measures].[Fact Team Game Count])` | `0.00%` |
| `Losses` | `[Measures].[Fact Team Game Count] - [Measures].[Is Win]` | `#,##0` |
| `Avg Points` | `IIF([Measures].[Fact Team Game Count] = 0, NULL, [Measures].[Pts] / [Measures].[Fact Team Game Count])` | `0.00` |
| `Avg Plus Minus` | `IIF([Measures].[Fact Team Game Count] = 0, NULL, [Measures].[Plus Minus] / [Measures].[Fact Team Game Count])` | `0.00` |
| `Avg Assists` | `IIF([Measures].[Ast Valid Count] = 0, NULL, [Measures].[Ast] / [Measures].[Ast Valid Count])` | `0.00` |
| `Avg Turnovers` | `IIF([Measures].[Tov Valid Count] = 0, NULL, [Measures].[Tov] / [Measures].[Tov Valid Count])` | `0.00` |
| `Avg 3PM` | `IIF([Measures].[Fg3m Valid Count] = 0, NULL, [Measures].[Fg3m] / [Measures].[Fg3m Valid Count])` | `0.00` |
| `Avg 3PA` | `IIF([Measures].[Fg3a Valid Count] = 0, NULL, [Measures].[Fg3a] / [Measures].[Fg3a Valid Count])` | `0.00` |
| `3P Accuracy` | `IIF([Measures].[Fg3a] = 0, NULL, [Measures].[Fg3m] / [Measures].[Fg3a])` | `0.00%` |
| `3P Attempt Share` | `IIF([Measures].[Fga] = 0, NULL, [Measures].[Fg3a] / [Measures].[Fga])` | `0.00%` |
| `Avg Paint Points` | `IIF([Measures].[Paint Valid Count] = 0, NULL, [Measures].[Pts Paint] / [Measures].[Paint Valid Count])` | `0.00` |
| `FG Accuracy` | `IIF([Measures].[Fga] = 0, NULL, [Measures].[Fgm] / [Measures].[Fga])` | `0.00%` |
| `Avg Fast Break Points` | `IIF([Measures].[Fast Break Valid Count] = 0, NULL, [Measures].[Pts Fast Break] / [Measures].[Fast Break Valid Count])` | `0.00` |

Tỷ lệ được giữ ở thang 0–1 rồi định dạng %. Không nhân thêm 100. `FG Accuracy` và `3P Accuracy` là tỷ lệ các tổng, không phải trung bình các phần trăm từng trận.

### 2.5. Sửa cầu nối để thực hiện đúng câu 14

**Lý do:** theo file cube hiện tại, `Player Game` chỉ nối Regular với `Dim Player` và `Dim Team`. Dùng Team làm chiều chung không xác định được cầu thủ ra sân ở trận nào. Lọc quốc gia có nguy cơ giữ mọi trận của đội từng có cầu thủ quốc tế.

Thực hiện trong DSV, không cần sửa bảng nguồn:

1. Chuột phải bảng `player_game` → **Replace Table → With New Named Query**. Giữ các cột cũ, bổ sung `fact_id` bằng định nghĩa sau:

```sql
SELECT pg.game_id, pg.player_id, pg.team_id, f.fact_id
FROM dbo.player_game AS pg
INNER JOIN dbo.fact_team_game AS f
  ON f.game_id = pg.game_id
 AND f.team_id = pg.team_id
```

2. Trong DSV, tạo relationship `player_game.fact_id` → `fact_team_game.fact_id`, trong đó `fact_team_game.fact_id` là phía khóa duy nhất. Giữ các liên kết Player và Team.
3. Trong **Dimension Usage**, ô `Player Game` × `Fact Team Game`: chọn **Regular**, granularity attribute `Fact Id`, cột nguồn `fact_id`.
4. Ô `Fact Team Game` measure group × `Dim Player`: chọn **Many-to-Many**, intermediate measure group = `Player Game`. Giữ quan hệ Fact giữa measure group chính và dimension `Fact Team Game` ở `Fact Id`.
5. Nếu muốn `Unique Games` phản ứng với lọc Player, ô measure group chứa `Unique Games` × `Dim Player` cũng đặt **Many-to-Many → Player Game**. Nhóm đó phải liên kết với `Fact Team Game` ở `Fact Id` như mục 2.3.
6. Tạo measure **Distinct count** trên `player_game.player_id`, đặt tên `Player Count`. Nếu có measure group mới, cấu hình các quan hệ Regular: Player qua `player_id`, Team qua `team_id`, `Fact Team Game` qua `fact_id`. Câu 14 bên dưới không dùng lọc thời gian cho measure này; nếu bổ sung Date/Season thì phải cấu hình tiếp đường liên kết tương ứng, không để các chiều đó ở trạng thái không liên quan.
7. Bảo đảm dữ liệu nguồn chỉ có một dòng Fact cho mỗi `(game_id, team_id)`. Một dòng player_game phải khớp đúng một Fact; các dòng không khớp bị loại bởi INNER JOIN và cần kiểm tra nếu thiếu số liệu.

SSAS dùng measure group trung gian và dimension chung để xác định [quan hệ many-to-many](https://learn.microsoft.com/en-us/analysis-services/multidimensional-tutorial/lesson-5-3-defining-a-many-to-many-relationship?view=sql-analysis-services-2025). Ở đây chiều chung cần chi tiết đến lượt đội trong trận, tức `Fact Id`.

**Kiểm tra nhanh bằng giao diện:** chọn một đội, một `Game Id` và một cầu thủ đã biết không ra sân trận đó. Các measures Fact phải rỗng khi lọc cầu thủ ấy. Đổi sang cầu thủ có ra sân thì phải có số liệu. Chọn đồng thời hai cầu thủ cùng trận không được nhân đôi điểm/số lượt đội.

### 2.6. Deploy, Process và mở Browser

1. Lưu các thay đổi.
2. Chuột phải project → **Deploy**.
3. Chuột phải cube → **Process → Process Full → Run** nếu quá trình triển khai chưa process đầy đủ.
4. Chỉ tiếp tục khi xử lý thành công. Nếu lỗi quyền nguồn dữ liệu, kiểm tra **Data Source → Impersonation Information** cho tài khoản mà SSAS dùng đọc `NBA_DW`.
5. Mở cube → **Browser → Reconnect**.
6. Nếu dùng SSMS: kết nối **Server type = Analysis Services**, mở database → **Cubes → NBA DW → Browse**.

## 3. Cách thao tác SSAS Browser và Excel

### 3.1. Trong SSAS Browser

Browser tùy phiên bản có giao diện dạng kết quả bảng, không có đủ bốn vùng như PivotTable Excel. Với từng câu bên dưới:

1. Kéo các attributes dùng phân nhóm vào vùng kết quả.
2. Kéo measures cần xem vào vùng dữ liệu/kết quả.
3. Trong vùng **Filter**, chọn **Dimension → Hierarchy → Operator → Filter Expression** và các members cần giữ. Lọc nhiều giá trị bằng danh sách chọn hoặc operator tương ứng mà phiên bản hỗ trợ.
4. Bấm **Execute** nếu giao diện có nút chạy; một số giao diện tự cập nhật.
5. Nếu không có thao tác Columns/Top N/Sort tương ứng, dùng nút **Analyze in Excel / biểu tượng Excel** để mở cùng cube và hoàn tất ở PivotTable. Không coi thao tác chỉ ẩn bớt dòng là một bộ lọc Top N.

Để so sánh theo cột hoặc trình bày dạng ma trận, Microsoft hướng dẫn dùng [Excel để duyệt cube đã triển khai](https://learn.microsoft.com/en-us/analysis-services/multidimensional-tutorial/lesson-3-5-browsing-the-deployed-cube?view=sql-analysis-services-2025).

### 3.2. Kết nối PivotTable trực tiếp tới SSAS

Cách ngắn nhất: từ Browser, bấm biểu tượng **Excel / Analyze in Excel**, chấp nhận kết nối khi được hỏi.

Nếu kết nối từ Excel Windows:

1. **Data → Get Data → From Other Sources → From Analysis Services**; trên bản cũ là **Data → From Other Sources → From Analysis Services**. Nếu không thấy, bật trình hướng dẫn legacy trong **File → Options → Data → Show legacy data import wizards → From Analysis Services**, rồi mở qua **Get Data → Legacy Wizards**.
2. Nhập tên **SSAS instance** đã deploy, dùng Windows Authentication theo quyền tài khoản của bạn.
3. Chọn database SSAS và cube `NBA DW`.
4. Trong màn hình nhập dữ liệu, chọn **PivotTable Report → New Worksheet**.
5. Bật **PivotTable Analyze → Field List** nếu chưa thấy danh sách trường.
6. **Design → Report Layout → Show in Tabular Form**, có thể chọn **Repeat All Item Labels**. Khi cần bảng gọn: **Subtotals → Do Not Show Subtotals**.
7. Lưu workbook, tạo mỗi câu một sheet `Q01` đến `Q15`. Copy sheet mẫu đã xóa hết trường/lọc để tạo Pivot mới.

Đây là [kết nối PivotTable tới nguồn OLAP bên ngoài](https://support.microsoft.com/en-gb/excel/create-a-pivottable-with-an-external-data-source). Chọn đường kết nối Analysis Services trực tiếp để giữ cách tính measures của cube.

**Quy ước bảng hướng dẫn:** `Team` = `Dim Team`, `Date` = `Dim Date`, `Season` = `Dim Season`, `Arena` = `Dim Arena`, `Player` = `Dim Player`, `Fact` = dimension `Fact Team Game`. `Opponent` là dimension riêng đã có trong cube. `Values` luôn chứa measures.

### 3.3. Những thao tác lặp lại

- **Chọn nhiều bộ lọc:** mở dropdown trường trong Filters → **Select Multiple Items** → bỏ Select All → chọn đúng các giá trị.
- **Top N:** dropdown trường Rows cần xếp hạng → **Value Filters → Top 10…** → `Top`, nhập N, `Items`, chọn measure làm tiêu chí → OK. Sau đó chuột phải ô số của measure → **Sort → Largest to Smallest**. [Hướng dẫn bộ lọc PivotTable](https://support.microsoft.com/en-us/excel/get-started/filter-data-in-a-pivottable).
- **Số và tỷ lệ:** dùng **Value Field Settings → Number Format** nếu cần chỉnh hiển thị. Với cube OLAP, cách tổng hợp được định nghĩa trong SSAS; không mặc định có thể đổi một measure Sum thành Average trong Excel.
- **Clear:** trước câu mới, bỏ hết trường cũ và chọn **PivotTable Analyze → Clear → Clear Filters**. Nếu dùng slicer chung cho nhiều Pivot, kiểm tra **Report Connections** để không lọc nhầm các câu khác.
- **Sau khi chỉnh cube:** Browser → Reconnect; Excel → **Data → Refresh All**. Nếu metadata mới chưa xuất hiện, tạo lại Pivot từ kết nối cube.

## 4. Thực hiện đủ 15 câu

### Câu 1 — Top 5 đội miền Tây có tỷ lệ thắng cao nhất trong năm lịch 2022

| Vùng Excel | Trường cần kéo | Giá trị chọn |
| --- | --- | --- |
| Rows | `Team.Full Name` | Từng đội |
| Columns | Để trống | Excel tự hiện các measures cạnh nhau |
| Values | `Fact Team Game Count`, `Is Win`, `Win Rate` | Lượt đội, trận thắng, tỷ lệ thắng |
| Filters | `Team.Conference`, `Season.Season Type`, `Date.Year Number` | `Western Conference`; `Regular Season`; `2022` |

1. Đặt bộ lọc trước.
2. Trên `Full Name`, **Value Filters → Top 10 → Top 5 Items by Win Rate**.
3. Sort `Win Rate` giảm dần.

**SSAS:** thêm Full Name và ba measures, đặt ba bộ lọc tương ứng; mở Excel để áp dụng Top 5 nếu Browser không hỗ trợ.

**Kiểm tra:** đây là các trận diễn ra trong năm 2022, có thể thuộc hai mùa thi đấu; không thay bằng mùa `2022-23`. Mỗi đội: `Is Win / Fact Team Game Count = Win Rate`.

### Câu 2 — Điểm và hiệu số trung bình của ba phân khu trong tháng 1–3/2023

| Vùng Excel | Trường cần kéo | Giá trị chọn |
| --- | --- | --- |
| Rows | `Team.Division` | Pacific, Atlantic, Southeast |
| Columns | `Date.Month Number` | 1, 2, 3 |
| Values | `Avg Points`, `Avg Plus Minus` | Hai chỉ số trung bình |
| Filters | `Date.Year Number` | 2023 |

1. Dropdown Division: chỉ chọn `Pacific`, `Atlantic`, `Southeast`.
2. Dropdown Month Number: chỉ chọn 1, 2, 3; sắp tăng dần.
3. Có thể thêm `Month Name` dưới Month Number nếu muốn tên tháng.

**SSAS:** thêm Division, Month Number và hai measures, lọc Division, tháng và năm như trên. Bảng phẳng tương đương ma trận Excel về nội dung.

**Kiểm tra:** có tối đa 9 tổ hợp phân khu–tháng có dữ liệu. Không chia đều trung bình của các đội để thay cho trung bình trên các dòng Fact.

### Câu 3 — Tỷ lệ thắng sân nhà/sân khách theo miền trong mùa 2022-23

| Vùng Excel | Trường cần kéo | Giá trị chọn |
| --- | --- | --- |
| Rows | `Team.Conference` | Eastern Conference, Western Conference |
| Columns | `Fact.Is Home` | 0 và 1 |
| Values | `Fact Team Game Count`, `Win Rate` | Số lượt đội và tỷ lệ thắng |
| Filters | `Season.Season Label` | 2022-23 |

`0 = Away`, `1 = Home`. Có thể ghi chú nhãn ngay phía trên bảng. Giữ Season Type ở All vì câu SQL gốc không lọc riêng Regular Season.

**SSAS:** thêm Conference, thuộc tính `Fact.Is Home` và hai measures; lọc Season Label = 2022-23. Không kéo measure `Is Home` để thay cho thuộc tính phân nhóm.

**Kiểm tra:** tối đa bốn tổ hợp miền–địa điểm. Tổng/Grand Total của tỷ lệ được tính lại từ tổng thắng/tổng lượt đội.

### Câu 4 — Top 10 đội có kiến tạo trung bình cao nhất ở Playoffs

| Vùng Excel | Trường cần kéo | Giá trị chọn |
| --- | --- | --- |
| Rows | `Team.Full Name` | Từng đội |
| Columns | Để trống | — |
| Values | `Fact Team Game Count`, `Avg Assists`, `Win Rate` | Số trận Playoffs, AST/trận, tỷ lệ thắng |
| Filters | `Season.Season Type` | Playoffs |

Trên Full Name → Top 10 Items by `Avg Assists`; sort giảm dần theo measure này. Không thêm năm/mùa vì đề gốc hỏi toàn bộ giai đoạn Playoffs trong dữ liệu.

**SSAS:** thêm Full Name và các measures, lọc Playoffs; thực hiện Top 10/sort tại Excel nếu cần.

### Câu 5 — Ném 3 điểm qua bốn kỷ nguyên

| Vùng Excel | Trường cần kéo | Giá trị chọn |
| --- | --- | --- |
| Rows | `Season.Era Label` | Bốn nhãn tạo ở mục 2.2 |
| Columns | Để trống | — |
| Values | `Unique Games`, `Avg 3PM`, `Avg 3PA`, `3P Accuracy` | Như SQL minh họa gốc |
| Filters | Không thêm | Tất cả dữ liệu |

Sort `Avg 3PM` giảm dần. Nếu cần đúng chỉ tiêu “tỷ lệ thử ném 3” trong phần mô tả nghiệp vụ, thêm `3P Attempt Share`: SQL gốc chỉ hiển thị độ chính xác ném 3, hai chỉ tiêu này khác nhau.

**SSAS:** thêm Era Label và các measures. Không dùng Era Name cũ khi chưa sửa cách ETL phân loại năm.

**Kiểm tra:** Avg 3PM/Avg 3PA là trung bình **mỗi đội mỗi trận**, theo AVG trong SQL gốc. Unique Games là số trận không trùng. Muốn trung bình tổng hai đội mỗi trận phải tạo chỉ tiêu khác.

### Câu 6 — Điểm cận rổ của năm đội trong năm 2023

| Vùng Excel | Trường cần kéo | Giá trị chọn |
| --- | --- | --- |
| Rows | `Team.Full Name` | Năm đội bên dưới |
| Columns | Để trống | — |
| Values | `Fact Team Game Count`, `Avg Paint Points`, `Avg Points` | Số trận, điểm cận rổ/trận, điểm/trận |
| Filters | `Date.Year Number` | 2023 |

Trong dropdown Full Name chọn đúng: `Los Angeles Lakers`, `Golden State Warriors`, `Boston Celtics`, `Miami Heat`, `Denver Nuggets`. Sort `Avg Paint Points` giảm dần.

**SSAS:** thêm Full Name và các measures; lọc danh sách năm đội và Year Number = 2023.

**Kiểm tra:** dùng năm lịch 2023. Nếu dữ liệu cận rổ rỗng, kiểm tra `Paint Valid Count`; không tự diễn giải giá trị thiếu thành đội không ghi điểm cận rổ.

### Câu 7 — Top 3 đội FG% cao nhất của từng phân khu mùa Regular Season 2022-23

**Cách thủ công chắc chắn:** tạo một Pivot cho từng phân khu. Không dùng một Top 3 toàn giải rồi xem đó là Top 3 mỗi phân khu.

| Vùng Excel | Trường cần kéo | Giá trị chọn |
| --- | --- | --- |
| Rows | `Team.Full Name` | Từng đội trong phân khu được chọn |
| Columns | Để trống | — |
| Values | `FG Accuracy`, `Is Win` | FG%, số trận thắng |
| Filters | `Team.Division`, `Season.Season Label`, `Season.Season Type` | Một phân khu; 2022-23; Regular Season |

1. Chọn phân khu đầu tiên, ví dụ Atlantic.
2. Sort FG Accuracy giảm dần; ghi nhận ba **mức FG% phân biệt** cao nhất nếu cần khớp `DENSE_RANK` trong SQL.
3. Dùng Value Filter `FG Accuracy >= ngưỡng mức thứ ba` để giữ cả các đội đồng hạng. Có thể chọn thủ công các đội ở ba mức đó khi dropdown không có toán tử phù hợp.
4. Nếu chỉ cần đúng ba đội và không có đồng hạng, Top 3 Items by FG Accuracy cho cùng kết quả.
5. Copy Pivot năm lần, đổi Division lần lượt: Central, Southeast, Northwest, Pacific, Southwest. Đặt cả sáu bảng trong sheet Q07 hoặc các sheet Q07_Atlantic, ...

**SSAS:** làm lần lượt mỗi Division, hiển thị Full Name, FG Accuracy, Is Win rồi lọc/sắp xếp qua Excel. Nếu muốn minh họa drill-down chung, thêm Division trước Full Name vào Rows của một Pivot phụ và mở rộng từng phân khu.

**Kiểm tra:** SQL dùng `DENSE_RANK <= 3`, nên có thể nhiều hơn ba đội khi đồng hạng; đừng loại đội cùng mức FG% chỉ để đủ 18 dòng. Xét giá trị đầy đủ trước khi làm tròn hiển thị.

### Câu 8 — Mất bóng trong trận thắng so với trận thua, năm lịch 2018–2023

| Vùng Excel | Trường cần kéo | Giá trị chọn |
| --- | --- | --- |
| Rows | `Season.Season Label` | Các mùa có trận trong khoảng năm đã lọc |
| Columns | `Fact.Is Win` | 0 = thua, 1 = thắng |
| Values | `Avg Turnovers` | TOV trung bình |
| Filters | `Date.Year Number` | 2018, 2019, 2020, 2021, 2022, 2023 |

Sort Season Label giảm dần. Bên cạnh Pivot, nếu cột B là thua và cột C là thắng, tạo cột `TOV Difference` với `=B6-C6` cho dòng dữ liệu đầu tiên, kéo xuống và định dạng hai chữ số. Nếu ô một phía rỗng thì để kết quả chênh lệch rỗng, không tự thay bằng 0.

**SSAS:** thêm Season Label, thuộc tính Fact.Is Win và Avg Turnovers; lọc sáu năm lịch. Chuyển Is Win sang Columns ở Excel để minh họa thao tác Pivot.

**Kiểm tra:** theo SQL gốc, khoảng thời gian là năm lịch rồi mới nhóm theo mùa. Vì vậy có thể xuất hiện mùa 2017-18 với dữ liệu chỉ từ 01/01/2018, hoặc mùa cuối chưa đủ trận. Nếu muốn so sánh các mùa trọn vẹn thì đó là điều chỉnh yêu cầu.

### Câu 9 — Top 10 trận có tổng điểm hai đội cao nhất

**Xếp hạng trước theo Game Id, sau đó bổ sung mô tả trận.**

| Vùng Excel | Trường cần kéo | Giá trị chọn |
| --- | --- | --- |
| Rows | `Fact.Game Id` | Một dòng/trận |
| Columns | Để trống | — |
| Values | `Pts`, `Fact Team Game Count` | Tổng điểm hai đội, số dòng Fact |
| Filters | Không thêm | Toàn bộ dữ liệu |

1. Trên Game Id → Top 10 Items by `Pts`; sort Pts giảm dần.
2. Mỗi trận phải có `Fact Team Game Count = 2` trước khi diễn giải Pts là tổng hai đội. Nếu khác 2, kiểm tra dữ liệu thiếu/trùng.
3. Thêm `Date.Full Date`, `Arena.Arena Name`, `Arena.City` vào Rows dưới Game Id. Dùng Tabular Form để đọc nhãn.
4. Tắt **Show items with no data**. Kiểm tra tổng điểm từng Game Id vẫn giữ nguyên và mỗi trận chỉ có một ngày/sân.
5. Nếu hai dòng Fact của cùng trận mang hai arena khác nhau, bảng sẽ tách thành hai nhánh: dùng tổng ở cấp Game Id để xếp hạng, kiểm tra lại gán sân trong ETL trước khi ghi một arena đại diện. Không xếp hạng theo điểm từng nhánh arena.

**SSAS:** thêm Game Id, Pts, Fact Team Game Count trước; lọc Top 10 tại Excel rồi thêm ngày và arena. Không dùng Fact Id thay Game Id vì Fact Id chỉ đại diện một đội.

**Giới hạn dữ liệu:** arena trong mô hình nguồn gắn với đội, nên cần xác minh có phản ánh địa điểm lịch sử của trận hay chỉ là thông tin sân của đội trong danh mục hiện tại.

### Câu 10 — Đối đầu Lakers–Celtics trong Playoffs

| Vùng Excel | Trường cần kéo | Giá trị chọn |
| --- | --- | --- |
| Rows | `Team.Full Name`, `Opponent.Full Name` | Lakers và Celtics |
| Columns | Để trống | — |
| Values | `Fact Team Game Count`, `Is Win`, `Losses` | Số trận; Lakers thắng; Celtics thắng |
| Filters | `Team.Abbreviation`, `Opponent.Abbreviation`, `Season.Season Type` | LAL; BOS; Playoffs |

Lọc `Dim Team.Abbreviation = LAL` và **Opponent.Abbreviation = BOS** ở hai dimension khác nhau. Giữ các mùa ở All.

**SSAS:** thêm Full Name của Team và Opponent, ba measures, đặt ba bộ lọc như trên.

**Kiểm tra:** `Is Win + Losses = Fact Team Game Count`. Do đã cố định một phía là Lakers, mỗi trận chỉ được đếm một lần; không chia số trận cho 2.

### Câu 11 — Top 5 sân có điểm chủ nhà trung bình cao nhất, 2015–2023

Đề gốc có điều kiện **ít nhất 50 trận sân nhà**. Phải lọc điều kiện này trước khi chọn Top 5.

| Vùng Excel | Trường cần kéo | Giá trị chọn |
| --- | --- | --- |
| Rows | `Arena.Arena Name`, `Arena.City` | Sân và thành phố |
| Columns | Để trống | — |
| Values | `Fact Team Game Count`, `Avg Points` | Số trận sân nhà; điểm chủ nhà/trận |
| Filters | `Fact.Is Home`, `Date.Year Number` | 1; các năm 2015 đến 2023 |

1. Đặt bộ lọc sân nhà và chín năm.
2. Ở Arena Name → **Value Filters → Greater Than Or Equal To → Fact Team Game Count → 50**.
3. Ghi lại các sân đủ điều kiện. Xóa value filter vừa dùng và chọn lại chính danh sách sân đủ điều kiện bằng checkbox trong Arena Name. Đây là bước giữ tập ứng viên trước Top N.
4. **PivotTable Options → Totals & Filters → Allow multiple filters per field** nếu cần giữ lọc chọn tay cùng lọc giá trị.
5. Trên Arena Name áp dụng **Top 5 Items by Avg Points**, sort giảm dần. Kiểm tra cả năm sân đều còn ít nhất 50 trận.

**SSAS:** thêm Arena Name, City, hai measures; lọc Is Home = 1 và năm 2015–2023. Hoàn tất điều kiện 50 trận và Top 5 tại Excel theo thứ tự trên.

**Kiểm tra:** không chỉ chọn Top 5 rồi bỏ các sân dưới 50 trận, vì như vậy có thể thiếu những sân hợp lệ nằm tiếp theo trong bảng xếp hạng. Đây là năm lịch theo SQL minh họa.

### Câu 12 — Số trận theo quý và điểm trung bình ngày thường/cuối tuần từ 2020

| Vùng Excel | Trường cần kéo | Giá trị chọn |
| --- | --- | --- |
| Rows | `Date.Year Number`, `Date.Quarter Number` | Năm rồi quý |
| Columns | `Date.Is Weekend` | False/0 = Weekday, True/1 = Weekend |
| Values | `Unique Games`, `Avg Points` | Số trận không trùng; điểm mỗi đội mỗi trận |
| Filters | Lọc ngay dropdown Year Number | Các năm >= 2020 đang có dữ liệu |

1. Chọn các năm từ 2020 trở đi trong Year Number.
2. Sort năm giảm dần; quý tăng dần.
3. Có thể thu gọn quý để minh họa roll-up, sau đó mở rộng lại để xem chi tiết.

**SSAS:** thêm Year Number, Quarter Number, Is Weekend và hai measures. Không cần dùng các hierarchy tên `Hierarchy`, `Hierarchy 1`, ... hiện có vì chúng đang là các hierarchy đơn cấp trong file dimension.

**Kiểm tra:** toàn giải, không lọc đội/sân nhà: tổng Fact Team Game Count thường gấp đôi Unique Games nếu mỗi trận đủ hai dòng. Avg Points vẫn là trung bình cho một đội, không phải tổng điểm hai đội.

### Câu 13 — Top 10 đội có điểm phản công nhanh trung bình cao nhất mùa 2022-23

| Vùng Excel | Trường cần kéo | Giá trị chọn |
| --- | --- | --- |
| Rows | `Team.Full Name` | Từng đội |
| Columns | Để trống | — |
| Values | `Avg Fast Break Points`, `Avg Points`, `Win Rate` | Điểm phản công/trận; điểm/trận; tỷ lệ thắng |
| Filters | `Season.Season Label` | 2022-23 |

Top 10 Items by `Avg Fast Break Points`; sort giảm dần. Season Type giữ All để khớp SQL gốc.

**SSAS:** thêm Full Name và ba measures, lọc Season Label, hoàn tất Top 10 ở Excel nếu cần.

**Kiểm tra:** nếu nhiều ô rỗng, kiểm tra `Fast Break Valid Count` để biết có thống kê phản công nhanh hay không.

### Câu 14 — Cầu thủ quốc tế và tỷ lệ thắng của đội khi có cầu thủ quốc tế ra sân

Chỉ làm sau khi hoàn tất mục 2.5. Tỷ lệ thắng trong SQL gốc bị lặp một dòng Fact cho mỗi cầu thủ phù hợp, nên thực chất bị gia quyền theo số cầu thủ quốc tế ra sân. Hướng dẫn này tính tỷ lệ thắng trên **các lượt đội–trận không nhân bản**, phù hợp mục tiêu phân tích sự hiện diện cầu thủ quốc tế.

| Vùng Excel | Trường cần kéo | Giá trị chọn |
| --- | --- | --- |
| Rows | `Team.Full Name` | Từng đội |
| Columns | Để trống | — |
| Values | `Player Count`, `Fact Team Game Count`, `Is Win`, `Win Rate` | Cầu thủ quốc tế khác nhau; trận có họ; số thắng; tỷ lệ thắng |
| Filters | `Player.Country` | Các quốc gia hợp lệ khác USA |

1. Mở Country → Select Multiple Items; bỏ `USA`, giá trị trống và Unknown. Kiểm tra cách mã hóa quốc gia thực tế trước khi chọn.
2. Trên Team.Full Name → Top 10 Items by `Player Count`; sort giảm dần.
3. Với mỗi đội, `Fact Team Game Count` là số trận có ít nhất một cầu thủ trong tập đã chọn ra sân. Có thể thêm `Unique Games` để kiểm tra; ở từng đội, nó phải bằng Fact Team Game Count.
4. `Player Game Count` đếm lượt cầu thủ ra sân, không phải cầu thủ khác nhau, nên không dùng để thay Player Count.

**SSAS:** thêm Full Name và bốn measures, lọc Country theo danh sách, hoàn tất Top 10 tại Excel.

**Kiểm tra:** không cộng các dòng Country để ra số trận của đội vì cùng trận có nhiều quốc tịch. Không cộng Player Count các đội để suy ra cầu thủ toàn giải vì một cầu thủ có thể thi đấu cho nhiều đội.

Nếu giảng viên yêu cầu chỉ xét **trận thắng**, thêm `Fact.Is Win = 1`; lúc đó Win Rate luôn 100% và đây là một biến thể khác với SQL gốc. Để Player Count cũng chỉ đếm cầu thủ xuất hiện trong các trận thắng, cần quan hệ Regular với Fact Id của nhóm Player Count như mục 2.5.

### Câu 15 — Đối đầu khác miền theo năm, 2018–2023

Điều kiện `Team.Conference <> Opponent.Conference` không phải một checkbox so sánh hai trường. Dùng hai Pivot, mỗi Pivot cố định một chiều đối đầu.

| Vùng Excel | Trường cần kéo | Giá trị chọn |
| --- | --- | --- |
| Rows | `Date.Year Number` | 2018–2023 |
| Columns | Để trống | — |
| Values | `Fact Team Game Count`, `Is Win`, `Win Rate`, `Avg Plus Minus` | Số trận đối đầu; số thắng; tỷ lệ thắng; hiệu số trung bình |
| Filters | `Team.Conference`, `Opponent.Conference` | Theo từng Pivot dưới đây |

1. Pivot A: Team.Conference = **Eastern Conference**; Opponent.Conference = **Western Conference**.
2. Year Number chỉ chọn 2018–2023; sort giảm dần.
3. Copy sang Pivot B: Team.Conference = **Western Conference**; Opponent.Conference = **Eastern Conference**.
4. Đặt hai Pivot cạnh nhau trong Q15, ghi tiêu đề `Eastern vs Western` và `Western vs Eastern`.
5. Không chọn đồng thời cả hai miền ở cả hai Filters, vì cách đó giữ cả đối đầu cùng miền.

**SSAS:** làm hai lượt với hai cặp bộ lọc đảo chiều, hiển thị Year Number và bốn measures. Hai bảng thể hiện đầy đủ nhóm `(year, team_conference)` trong SQL gốc.

**Kiểm tra:** cùng một năm, nếu dữ liệu đủ hai phía, số trận A = B; thắng A + thắng B = số trận A; Win Rate A + Win Rate B = 100%; Avg Plus Minus A và B đối dấu. Không cộng số trận hai bảng rồi gọi đó là số trận duy nhất toàn giải.

## 5. Lưu kết quả để làm báo cáo

1. Mỗi sheet Q01–Q15 ghi tên câu hỏi, chỉ tiêu, thời gian và các bộ lọc ngay phía trên Pivot.
2. Khi chụp hình, để cả vùng Filters và bảng kết quả trong ảnh. Với Q07 và Q15, cần đủ các bảng thành phần.
3. Nếu cần minh chứng thao tác SSAS riêng, chụp Browser có attributes/measures/bộ lọc trước khi chuyển Excel. Ghi rõ bước Top N hoàn tất tại Excel nếu Browser không có chức năng đó.
4. Định dạng tỷ lệ hai chữ số %, trung bình hai chữ số thập phân, số trận không có phần lẻ.
5. Lưu workbook `.xlsx`; ghi lại SSAS instance, database, cube và thời điểm refresh để mở lại đúng nguồn.

## 6. Khi kết quả không đúng kỳ vọng

| Dấu hiệu | Kiểm tra trước | Cách xử lý |
| --- | --- | --- |
| Không thấy 2022-23 | Season Display đang là mã 22022/... | Dùng Season Label mới, deploy/process và refresh |
| Không kéo được sân nhà/thắng thua vào Columns | Đang chọn measure thay vì attribute | Chọn Is Home/Is Win bên trong dimension Fact Team Game |
| Average bị vô hiệu hóa trong Excel | Measure đang lấy từ cube OLAP | Dùng calculated measure đã tạo trong SSAS |
| Số trận toàn giải gấp đôi | Dùng Fact Team Game Count | Dùng Unique Games khi cần số trận thực |
| Lọc quốc gia nhưng vẫn giữ cả trận cầu thủ không tham gia | Bridge mới chỉ chung Team | Hoàn tất liên kết Fact Id ở mục 2.5 |
| Số liệu không thay đổi khi lọc | Dimension Usage không có đường liên kết đến measure group | Kiểm tra từng nhóm, đặc biệt các nhóm Distinct Count mới |
| Câu 7 chỉ có 3 đội toàn giải | Top N áp dụng toàn tập | Tách theo từng Division |
| Câu 11 có sân dưới 50 trận | Chọn Top N trước điều kiện số trận | Chọn tập sân đủ điều kiện rồi Top 5 |
| Câu 9 mỗi trận tách hai sân | Hai dòng Fact gán arena khác nhau | Giữ xếp hạng ở cấp Game Id và kiểm tra ETL gán sân |

Các kết quả chỉ mô tả dữ liệu đã nạp. Conference/Division trong dim_team và thông tin arena có thể là danh mục hiện tại được áp dụng cho trận lịch sử; nếu báo cáo lịch sử cần đúng theo thời điểm thi đấu, phải bổ sung mô hình theo thời gian.
