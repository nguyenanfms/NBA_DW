# Trạng thái bổ sung cube NBA DW — 15/10/2026

Project đã được bổ sung để thực hiện các câu OLAP bằng SSAS Browser, Excel PivotTable và MDX. Bản build gần nhất trong Visual Studio xác nhận **Build succeeded: 0 errors, 10 warnings**. Nguồn `NBA_DW` đã truy cập được; các truy vấn đối chiếu trên cube đã chạy thành công. Các thay đổi Attribute Relationships của Dim Team mới nhất mới được lưu và build trong project, chưa được triển khai/xử lý thay người dùng.

| Phần bổ sung | Nội dung | Dùng cho |
| --- | --- | --- |
| Thuộc tính trận | `Game Id`, `Is Home`, `Is Win` trong dimension `Fact Team Game` | Gom trận, so sánh sân nhà/sân khách, thắng/thua |
| Nhãn mùa và kỷ nguyên | `Season Label`, `Era Label` trong `Dim Season` | Chọn mùa 2022-23 và phân loại kỷ nguyên bằng năm mùa |
| Bộ đếm không trùng | `Unique Games`, `Player Count`, mỗi measure có nhóm riêng | Đếm số trận và cầu thủ không bị lặp |
| Dữ liệu hợp lệ | Sáu measures `* Valid Count` | Tính trung bình với mẫu số loại NULL |
| Các chỉ số phân tích | 13 calculated measures trong tab Calculations | Tỷ lệ thắng, trung bình, FG%, 3P%, số trận thua |
| Cầu nối cầu thủ | Named Query thêm `fact_id` bằng cặp `(game_id, team_id)` | Lọc đúng cầu thủ có tham gia từng lượt đội–trận |
| Hierarchy thời gian | Year Number → Quarter Number → Month Number → Date Key | Drill-down/roll-up theo lịch |
| Hierarchy đội | Conference → Division → State → Team Id | Duyệt địa lý và lấy Top 3 đội trong từng Division |

Các file đã chỉnh trong phần bổ sung SSAS: `NBA DW.dsv`, `Fact Team Game.dim`, `Dim Season.dim`, `Dim Date.dim`, `Dim Team.dim`, `NBA DW.cube`, `NBA DW.partitions` trong thư mục `nba_datawarehouse_ssas`. Tùy chọn Deployment/Processing giữ mặc định ban đầu; không sử dụng DoNotProcess.

Các calculated measures: `Win Rate`, `Losses`, `Avg Points`, `Avg Plus Minus`, `Avg Assists`, `Avg Turnovers`, `Avg 3PM`, `Avg 3PA`, `3P Accuracy`, `3P Attempt Share`, `Avg Paint Points`, `FG Accuracy`, `Avg Fast Break Points`.

## Kiểm tra đã hoàn tất

- Visual Studio mở được cube cùng bốn measure groups và hiển thị đủ calculated measures trong Calculations.
- Build thành công, không có lỗi cấu hình chặn build.
- Kiểm tra các ColumnBinding mới khớp cột trong DSV; tham chiếu measures trong MDX khớp measures đã định nghĩa.
- Bảng nguồn có đủ 30 đội, sáu Division, không còn Conference/Division Unknown hoặc NULL tại thời điểm kiểm tra.
- Đối chiếu đủ chín nhóm của câu 2 giữa MDX và ảnh PivotTable; chạy câu 15 được 12 dòng và Top 3 Win Rate theo Division được 18 đội trên phiên bản cube đã xử lý ở thời điểm kiểm tra.
- Các bản sao lưu được giữ cục bộ trong `backups/`, không nằm trong nội dung push lên Git.

Mười cảnh báo ở bản build gần nhất liên quan tới thuộc tính hiển thị, loại quan hệ Flexible/Rigid, các dimension chưa có hierarchy, Time dimension và provider nguồn dữ liệu. Chúng không chặn build; vẫn cần kiểm tra Process sau khi triển khai các thay đổi mới nhất.

## Khóa và quan hệ hierarchy

- Quarter Number: KeyColumns = `year_number`, `quarter_number`; NameColumn = `quarter_number`.
- Month Number: KeyColumns = `year_number`, `month_number`; NameColumn = `month_name`.
- Chuỗi quan hệ thời gian: Date Key → Month Number → Quarter Number → Year Number.
- Chuỗi quan hệ đội: Team Id → State → Division → Conference, Relationship Type = Flexible. Giữ các thuộc tính Full Name, Abbreviation và City.
- Member MDX của tháng dùng khóa ghép, ví dụ tháng 1/2023 là `[Dim Date].[Month Number].&[2023]&[1]`. Member quý cũng dùng năm và quý tương ứng.
- fact_id trong cầu nối là khóa thay thế cho lượt đội–trận. Cặp `(game_id, team_id)` đã đủ xác định lượt này theo grain dữ liệu; fact_id được dùng để tái sử dụng dimension Fact Team Game sẵn có.

## Chạy trên máy khác sau khi clone

1. Tạo/nạp `NBA_DW` bằng quy trình ETL của project. Chỉ chạy script tạo bảng sau khi xác nhận không có dữ liệu cần giữ: script hiện có các lệnh DROP TABLE.
2. Trong `NBA DW.ds`, chọn server/database nguồn trên máy chạy SSAS. Kết nối lưu trong project hiện là `DESKTOP-AHL2RE7\SQLEXPRESS`, database `NBA_DW`, nên cần điều chỉnh theo môi trường của từng thành viên. Tài khoản dùng để Process cần quyền đọc nguồn; login và quyền trên máy khác không được tạo tự động khi clone Git.
3. Kiểm tra mỗi `(game_id, team_id)` có một dòng Fact và các lượt cầu thủ nối được sang Fact. Xác nhận NULL trong thống kê chưa bị đổi thành 0 nếu muốn trung bình loại dữ liệu thiếu.
4. Deploy tới SSAS `localhost\SSAS2022`, database `nba_datawarehouse_ssas`, rồi Process Full.
5. Browser → Reconnect; kết nối Excel tới cube `NBA DW`. Làm theo mục 4 của `09_manual_ssas_excel_15_queries.md`.

`Player Count` và `Player Game Count` hiện có quan hệ với Player, Team và Fact Team Game. Không sử dụng bộ lọc Date/Season trực tiếp cho hai nhóm này khi chưa bổ sung đường liên kết tương ứng; câu 14 hiện không yêu cầu bộ lọc thời gian. Các measures Fact và Unique Games vẫn có liên kết thời gian qua nhóm nguồn Fact.
