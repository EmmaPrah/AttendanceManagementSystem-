<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.time.*" %>
<%@ page import="java.time.format.*" %>
<%@ page import="java.util.*" %>
<%
    if (session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp?error=Please log in to view attendance report");
        return;
    }

    String userId = (String) session.getAttribute("userId");
    String jdbcURL = "jdbc:sqlite:C:/apache-tomcat-10.1.34/webapps/Attendify/attendify.db";
    Connection connection = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    // Get selected course and date range from parameters
    String selectedCourse = request.getParameter("course");
    String startDate = request.getParameter("startDate");
    String endDate = request.getParameter("endDate");

    // Default to current month if no dates selected
    if (startDate == null || endDate == null) {
        LocalDate now = LocalDate.now();
        startDate = now.withDayOfMonth(1).toString();
        endDate = now.withDayOfMonth(now.lengthOfMonth()).toString();
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Attendance Report - Attendify</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        body { background-color: #f0f8ff; }
        .navbar { background-color: #007bff; }
        .card {
            border: none;
            border-radius: 15px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
        }
        .attendance-summary {
            background-color: #e9ecef;
            border-radius: 10px;
            padding: 15px;
            margin-bottom: 20px;
        }
        .stat-card {
            background: white;
            padding: 15px;
            border-radius: 10px;
            text-align: center;
            margin: 10px 0;
        }
        .stat-number {
            font-size: 24px;
            font-weight: bold;
            color: #007bff;
        }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark">
        <div class="container">
            <a class="navbar-brand" href="index.jsp">
                <i class="fas fa-chalkboard-teacher me-2"></i>Attendify
            </a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav ms-auto">
                    <li class="nav-item">
                        <a class="nav-link" href="student-dashboard.jsp">Dashboard</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="course_selection.jsp">Course Selection</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="student-check-in.jsp">Check-in</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="index.jsp">Logout</a>
                    </li>
                </ul>
            </div>
        </div>
    </nav>

    <div class="container mt-5">
        <h2 class="text-center mb-4">Attendance Report</h2>
        
        <!-- Filters -->
        <div class="card mb-4">
            <div class="card-body">
                <form method="get" class="row g-3">
                    <div class="col-md-4">
                        <label for="course" class="form-label">Course</label>
                        <select class="form-select" id="course" name="course">
                            <option value="">All Courses</option>
                            <%
                                try {
                                    Class.forName("org.sqlite.JDBC");
                                    connection = DriverManager.getConnection(jdbcURL);
                                    pstmt = connection.prepareStatement(
                                        "SELECT DISTINCT cs.course_code, c.course_name " +
                                        "FROM course_selections cs " +
                                        "JOIN courses c ON cs.course_code = c.course_code " +
                                        "WHERE cs.student_id = ?"
                                    );
                                    pstmt.setString(1, userId);
                                    rs = pstmt.executeQuery();
                                    
                                    while (rs.next()) {
                                        String code = rs.getString("course_code");
                                        String name = rs.getString("course_name");
                                        String selected = code.equals(selectedCourse) ? "selected" : "";
                                        %>
                                        <option value="<%= code %>" <%= selected %>><%= code %> - <%= name %></option>
                                        <%
                                    }
                                } catch (Exception e) {
                                    out.println("<option value=''>Error loading courses</option>");
                                }
                            %>
                        </select>
                    </div>
                    <div class="col-md-3">
                        <label for="startDate" class="form-label">Start Date</label>
                        <input type="date" class="form-control" id="startDate" name="startDate" value="<%= startDate %>">
                    </div>
                    <div class="col-md-3">
                        <label for="endDate" class="form-label">End Date</label>
                        <input type="date" class="form-control" id="endDate" name="endDate" value="<%= endDate %>">
                    </div>
                    <div class="col-md-2 d-flex align-items-end">
                        <button type="submit" class="btn btn-primary w-100">Filter</button>
                    </div>
                </form>
            </div>
        </div>

        <!-- Attendance Summary -->
        <div class="row">
            <%
                try {
                    // Calculate total classes
                    String whereClause = selectedCourse != null && !selectedCourse.isEmpty() 
                        ? " AND course_code = ?" : "";
                    
                    pstmt = connection.prepareStatement(
                        "SELECT COUNT(*) as total_attendance, " +
                        "COUNT(DISTINCT course_code) as total_courses, " +
                        "COUNT(DISTINCT DATE(check_in_time)) as total_days " +
                        "FROM attendance " +
                        "WHERE student_id = ? " +
                        "AND DATE(check_in_time) BETWEEN ? AND ?" + whereClause
                    );
                    
                    pstmt.setString(1, userId);
                    pstmt.setString(2, startDate);
                    pstmt.setString(3, endDate);
                    if (selectedCourse != null && !selectedCourse.isEmpty()) {
                        pstmt.setString(4, selectedCourse);
                    }
                    
                    rs = pstmt.executeQuery();
                    if (rs.next()) {
                        int totalAttendance = rs.getInt("total_attendance");
                        int totalCourses = rs.getInt("total_courses");
                        int totalDays = rs.getInt("total_days");
                        %>
                        <div class="col-md-4">
                            <div class="stat-card">
                                <div class="stat-number"><%= totalAttendance %></div>
                                <div>Total Check-ins</div>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <div class="stat-card">
                                <div class="stat-number"><%= totalCourses %></div>
                                <div>Courses Attended</div>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <div class="stat-card">
                                <div class="stat-number"><%= totalDays %></div>
                                <div>Days Present</div>
                            </div>
                        </div>
                        <%
                    }
                } catch (Exception e) {
                    out.println("<div class='alert alert-danger'>Error calculating attendance summary: " + e.getMessage() + "</div>");
                }
            %>
        </div>

        <!-- Detailed Attendance Records -->
        <div class="card mt-4">
            <div class="card-body">
                <h3 class="card-title mb-4">Detailed Attendance Records</h3>
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>Date</th>
                                <th>Course Code</th>
                                <th>Course Name</th>
                                <th>Check-in Time</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                try {
                                    whereClause = selectedCourse != null && !selectedCourse.isEmpty() 
                                        ? " AND a.course_code = ?" : "";
                                        
                                    pstmt = connection.prepareStatement(
                                        "SELECT a.course_code, c.course_name, a.check_in_time " +
                                        "FROM attendance a " +
                                        "JOIN courses c ON a.course_code = c.course_code " +
                                        "WHERE a.student_id = ? " +
                                        "AND DATE(a.check_in_time) BETWEEN ? AND ?" +
                                        whereClause +
                                        " ORDER BY a.check_in_time DESC"
                                    );
                                    
                                    pstmt.setString(1, userId);
                                    pstmt.setString(2, startDate);
                                    pstmt.setString(3, endDate);
                                    if (selectedCourse != null && !selectedCourse.isEmpty()) {
                                        pstmt.setString(4, selectedCourse);
                                    }
                                    
                                    rs = pstmt.executeQuery();
                                    while (rs.next()) {
                                        LocalDateTime checkInTime = LocalDateTime.parse(rs.getString("check_in_time"));
                                        String date = checkInTime.format(DateTimeFormatter.ofPattern("MMM dd, yyyy"));
                                        String time = checkInTime.format(DateTimeFormatter.ofPattern("HH:mm"));
                                        %>
                                        <tr>
                                            <td><%= date %></td>
                                            <td><%= rs.getString("course_code") %></td>
                                            <td><%= rs.getString("course_name") %></td>
                                            <td><%= time %></td>
                                        </tr>
                                        <%
                                    }
                                } catch (Exception e) {
                                    out.println("<tr><td colspan='4' class='text-center text-danger'>Error loading attendance records: " + e.getMessage() + "</td></tr>");
                                } finally {
                                    try {
                                        if (rs != null) rs.close();
                                        if (pstmt != null) pstmt.close();
                                        if (connection != null) connection.close();
                                    } catch (SQLException e) {
                                        // Log the error
                                    }
                                }
                            %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
