# Thực hiện câu 2, 3, 10 bằng SSAS Browser, Excel PivotTable và MDX

MDX là ngôn ngữ truy vấn cube SSAS. SQL truy vấn các bảng của database quan hệ; MDX truy vấn dimensions, members và measures trong cube. Cả hai có SELECT và FROM nhưng cú pháp và cách tổ chức kết quả khác nhau. [Microsoft: MDX Query Fundamentals](https://learn.microsoft.com/en-us/analysis-services/multidimensional-models/mdx/mdx-query-fundamentals-analysis-services?view=sql-analysis-services-2025)

Hướng dẫn sử dụng tên trong file project đã kiểm tra: cube `NBA DW`, các dimensions `Dim Team`, `Dim Date`, `Dim Season`, `Fact Team Game`, `Opponent`. Kết quả câu 2 đã được đối chiếu với PivotTable trước khi đổi khóa thời gian sang khóa ghép. Bản MDX câu 2 dưới đây đã được cập nhật theo khóa tháng `(year_number, month_number)` hiện tại; cần Deploy/Process bản cấu hình này trước khi chạy. Nếu tên đối tượng trên server đã đổi, kéo tên thực tế từ Metadata vào cửa sổ MDX để thay thế.

## 1. Chuẩn bị chung

Cube cần Deploy và Process thành công, database nguồn NBA_DW cần Online và tài khoản đọc nguồn có quyền phù hợp. Tài liệu này không thay đổi cấu hình tài khoản, quyền hoặc tùy chọn Deployment.

### SSAS Browser

1. Visual Studio → Solution Explorer → Cubes → mở `NBA DW.cube`.
2. Chọn Browser → Reconnect.
3. Danh sách metadata ở bên trái. Bên phải là Filter phía trên và Data phía dưới.
4. Với từng câu, kéo attributes phân nhóm và measures vào Data; đặt điều kiện trong Filter.
5. Bấm Execute Query nếu bảng chưa tự cập nhật. Xóa các trường và điều kiện câu trước khi chuyển sang câu tiếp theo.

Browser thường trả bảng phẳng. Để hiển thị dạng ma trận hàng/cột, sử dụng Excel. [Microsoft: Browsing the Cube](https://learn.microsoft.com/en-us/analysis-services/multidimensional-tutorial/lesson-2-6-browsing-the-cube?view=sql-analysis-services-2025)

### Excel PivotTable

1. Tại Browser, chọn biểu tượng Excel / Analyze in Excel để mở PivotTable có sẵn kết nối cube.
2. Nếu chưa có nút tương ứng, trong Excel dùng Data → From Other Sources → From Analysis Services; vị trí menu có thể nằm dưới Get Data hoặc Legacy Wizards tùy phiên bản.
3. Server là `localhost\SSAS2022` nếu Excel chạy trên cùng máy SSAS; chọn database `nba_datawarehouse_ssas`, cube `NBA DW`, rồi PivotTable Report.
4. Bật Field List; tạo ba sheet Q02, Q03, Q10.
5. Với bộ lọc nhiều giá trị: mở dropdown → Select Multiple Items → chọn đúng các members.

Chọn kết nối trực tiếp tới cube để dùng các measures đã tính trong SSAS. [Microsoft: PivotTable từ nguồn bên ngoài](https://support.microsoft.com/en-gb/excel/create-a-pivottable-with-an-external-data-source)

### Cửa sổ MDX

1. Mở SSMS → Connect → Analysis Services.
2. Server name: `localhost\SSAS2022`, dùng tài khoản Windows được cấp quyền.
3. Trong Object Explorer, mở Databases → chuột phải `nba_datawarehouse_ssas` → New Query → MDX.
4. Kiểm tra database đang chọn trên thanh công cụ là `nba_datawarehouse_ssas`.
5. Dán riêng từng câu MDX bên dưới → Execute hoặc F5.

Đây là cửa sổ MDX kết nối Analysis Services; cửa sổ SQL kết nối Database Engine không chạy được các câu MDX này. [Microsoft: mở New Query → MDX](https://learn.microsoft.com/en-us/analysis-services/instances/use-analysis-services-templates-in-sql-server-management-studio?view=sql-analysis-services-2025)

Quy ước: Measures là chỉ số; ON COLUMNS đặt chỉ số hoặc members theo cột; ON ROWS đặt theo hàng; WHERE giới hạn phạm vi; NON EMPTY bỏ các hàng/cột không có dữ liệu. [Microsoft: Basic MDX Query](https://learn.microsoft.com/en-us/analysis-services/multidimensional-models/mdx/mdx-query-the-basic-query?view=sql-analysis-services-2025)

## 2. Câu 2 — Điểm và hiệu số trung bình của ba phân khu, tháng 1–3/2023

Yêu cầu: Pacific, Atlantic, Southeast; tháng 1, 2, 3 trong năm lịch 2023; thống kê điểm và hiệu số điểm trung bình theo phân khu và tháng. Không thêm bộ lọc Season Type.

### A. Manual trong Browser

Kéo vào Data:

- Dim Team → Division.
- Dim Date → Month Number.
- Measures → Avg Points.
- Measures → Avg Plus Minus.

Trong Filter thêm ba dòng:

| Dimension | Hierarchy | Giá trị chọn |
| --- | --- | --- |
| Dim Team | Division | Pacific, Atlantic, Southeast |
| Dim Date | Year Number | 2023 |
| Dim Date | Month Number | 1, 2, 3 |

Chọn operator Equal với danh sách members tương ứng; nếu giao diện có lựa chọn In cho nhiều giá trị thì sử dụng In. Execute Query. Bảng có tối đa chín nhóm phân khu–tháng có dữ liệu.

### B. PivotTable Excel

| Vùng | Trường | Bộ lọc |
| --- | --- | --- |
| Rows | Dim Team.Division | Pacific, Atlantic, Southeast |
| Columns | Dim Date.Month Number | 1, 2, 3 |
| Values | Avg Points, Avg Plus Minus | Định dạng hai chữ số thập phân |
| Filters | Dim Date.Year Number | 2023 |

1. Kéo các trường đúng vùng.
2. Trong dropdown Division và Month Number, chỉ giữ các giá trị cần phân tích.
3. Sắp Month Number tăng dần.
4. So sánh các ô với tổ hợp Division–Month tương ứng trong Browser. Grand Total là chỉ số tính trên toàn phạm vi, không phải trung bình đơn giản của các ô trung bình.

### C. MDX

```mdx
SELECT
  {
    [Measures].[Avg Points],
    [Measures].[Avg Plus Minus]
  } ON COLUMNS,
  NON EMPTY
  CrossJoin(
    {
      [Dim Team].[Division].&[Pacific],
      [Dim Team].[Division].&[Atlantic],
      [Dim Team].[Division].&[Southeast]
    },
    {
      [Dim Date].[Month Number].&[2023]&[1],
      [Dim Date].[Month Number].&[2023]&[2],
      [Dim Date].[Month Number].&[2023]&[3]
    }
  ) ON ROWS
FROM [NBA DW]
WHERE ([Dim Date].[Year Number].&[2023]);
```

CrossJoin tạo các tổ hợp phân khu–tháng. Chọn sẵn members trong tập trên hàng tương đương giới hạn phân khu và tháng; WHERE chọn năm 2023. Bộ lọc nhiều tháng vẫn giữ được điểm trung bình riêng từng tháng.

## 3. Câu 3 — Tỷ lệ thắng sân nhà/sân khách của hai miền mùa 2022-23

Yêu cầu: nhóm theo Conference và Is Home, mùa thi đấu 2022-23. Season Type giữ All, vì câu gốc không chỉ định Regular Season.

### A. Manual trong Browser

Kéo vào Data:

- Dim Team → Conference.
- Dimension Fact Team Game → Is Home.
- Measures → Fact Team Game Count.
- Measures → Win Rate.

Lưu ý chọn Is Home trong dimension Fact Team Game để phân nhóm; measure Is Home chỉ là tổng cờ sân nhà, không thay thế được thuộc tính này.

Filter:

| Dimension | Hierarchy | Giá trị chọn |
| --- | --- | --- |
| Dim Season | Season Label | 2022-23 |
| Dim Team | Conference | Eastern Conference, Western Conference |
| Fact Team Game | Is Home | 0, 1 |

Execute Query. Kết quả có tối đa bốn tổ hợp: Đông–khách, Đông–nhà, Tây–khách, Tây–nhà. Is Home = 0 là sân khách; 1 là sân nhà.

### B. PivotTable Excel

| Vùng | Trường | Bộ lọc |
| --- | --- | --- |
| Rows | Dim Team.Conference | Eastern Conference, Western Conference |
| Columns | Fact Team Game.Is Home | 0, 1 |
| Values | Fact Team Game Count, Win Rate | Win Rate định dạng 0.00% |
| Filters | Dim Season.Season Label | 2022-23 |

1. Nhập các trường và bộ lọc như bảng.
2. Ghi chú 0 = Away, 1 = Home phía trên Pivot.
3. Để minh họa Pivot, chuyển Is Home sang Rows và Conference sang Columns rồi quan sát bố cục thay đổi; các số liệu ở cùng tổ hợp vẫn giữ nguyên.
4. Không dùng Show Values As → % of Grand Total để thay Win Rate. Tỷ lệ thắng đã được tính bằng số thắng chia số lượt đội trong phạm vi tương ứng.

### C. MDX

```mdx
SELECT
  {
    [Measures].[Fact Team Game Count],
    [Measures].[Win Rate]
  } ON COLUMNS,
  NON EMPTY
  CrossJoin(
    {
      [Dim Team].[Conference].&[Eastern Conference],
      [Dim Team].[Conference].&[Western Conference]
    },
    {
      [Fact Team Game].[Is Home].&[0],
      [Fact Team Game].[Is Home].&[1]
    }
  ) ON ROWS
FROM [NBA DW]
WHERE ([Dim Season].[Season Label].&[2022-23]);
```

Mùa thi đấu 2022-23 khác năm lịch 2022: sử dụng Season Label ở cả ba cách, không thay bằng Year Number.

## 4. Câu 10 — Đối đầu Lakers–Celtics trong Playoffs

Yêu cầu: cố định đội chủ thể là Los Angeles Lakers và đối thủ là Boston Celtics, xét tất cả các mùa Playoffs. Đội chủ thể không đồng nghĩa đội chủ nhà.

### A. Manual trong Browser

Kéo vào Data:

- Dim Team → Full Name.
- Opponent → Full Name.
- Measures → Fact Team Game Count.
- Measures → Is Win.
- Measures → Losses.

Filter:

| Dimension | Hierarchy | Giá trị chọn |
| --- | --- | --- |
| Dim Team | Abbreviation | LAL |
| Opponent | Abbreviation | BOS |
| Dim Season | Season Type | Playoffs |

Execute Query. Tên hiển thị của dimension Opponent trên giao diện có thể đi kèm tên Dim Team. Cần chọn đúng vai trò đối thủ, không đặt hai bộ lọc LAL và BOS cùng trên Dim Team.

### B. PivotTable Excel

| Vùng | Trường | Bộ lọc |
| --- | --- | --- |
| Rows | Dim Team.Full Name, Opponent.Full Name | Lakers và Celtics |
| Columns | Để trống | — |
| Values | Fact Team Game Count, Is Win, Losses | Số nguyên |
| Filters | Dim Team.Abbreviation, Opponent.Abbreviation, Dim Season.Season Type | LAL; BOS; Playoffs |

Trong ngữ cảnh này:

- Fact Team Game Count = số trận đối đầu.
- Is Win = số trận Lakers thắng.
- Losses = số trận Celtics thắng.

Không lọc thêm Is Home. Đã cố định một phía là Lakers nên mỗi trận có một dòng Fact phù hợp; không chia số trận cho hai.

### C. MDX

```mdx
SELECT
  {
    [Measures].[Fact Team Game Count],
    [Measures].[Is Win],
    [Measures].[Losses]
  } ON COLUMNS,
  NON EMPTY
  {
    (
      [Dim Team].[Full Name].&[Los Angeles Lakers],
      [Opponent].[Full Name].&[Boston Celtics]
    )
  } ON ROWS
FROM [NBA DW]
WHERE ([Dim Season].[Season Type].&[Playoffs]);
```

Ở câu MDX, chọn trực tiếp Full Name của hai đội tương đương điều kiện LAL/BOS trong dữ liệu danh mục hiện tại. Nếu nhóm đổi caption/name trên server, xác định member tương ứng trong Metadata thay vì tự đoán tên.

Kiểm tra: Is Win + Losses phải bằng Fact Team Game Count.

## 5. Đối chiếu ba cách

1. Dùng cùng cube đã xử lý, cùng điều kiện và cùng measures.
2. Câu 2: đối chiếu theo từng Division–Month Number.
3. Câu 3: đối chiếu theo từng Conference–Is Home.
4. Câu 10: đối chiếu ba chỉ số của cùng cặp Lakers–Celtics.
5. So sánh giá trị trước khi làm tròn nếu cần; Win Rate có thể hiển thị dạng 0–1 hoặc phần trăm tùy định dạng client.
6. Khi chụp ảnh báo cáo: Browser cần có vùng Filter và kết quả; Excel cần có Filters và Pivot; MDX cần có câu lệnh và kết quả. Ghi số liệu thật sau khi chạy, không suy đoán từ số dòng dự kiến.

## 6. Ghi chú về game_id và fact_id

game_id xác định một trận, nhưng Fact Team Game có một dòng cho mỗi đội trong trận đó. Vì thế cặp (game_id, team_id) đã đủ xác định lượt đội–trận nếu dữ liệu tuân thủ grain đã thiết kế. fact_id là khóa thay thế cho cùng lượt đội–trận, không phải thông tin nghiệp vụ bắt buộc phải thêm.

Trong bản cube ban đầu, Player Game chỉ có liên kết Regular với Player và Team; chưa có chiều chung thể hiện trận khi lọc measures Fact qua Player. Vấn đề là cấu hình đường liên kết trong SSAS, không phải bảng player_game thiếu game_id. Phương án fact_id đã áp dụng là một cách sử dụng dimension Fact Team Game sẵn có; có thể thay bằng thiết kế khóa ghép đúng mức chi tiết. Các câu 2, 3 và 10 trong tài liệu này không sử dụng chiều cầu thủ.
