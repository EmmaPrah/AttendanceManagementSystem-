<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%
    // Ensure user is logged in and is a student
    if (session.getAttribute("userId") == null || !"student".equals(session.getAttribute("userType"))) {
        response.sendRedirect("login.jsp?error=Please log in as a student");
        return;
    }

    String studentId = (String) session.getAttribute("userId");
    String jdbcURL = "jdbc:sqlite:C:/apache-tomcat-10.1.34/webapps/AttendanceManagementSystem/attendify.db";
    Connection connection = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Attendance Records - Attendify</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        .stats-card {
            background: linear-gradient(45deg, #0072ff, #00c6ff);
            color: white;
            border: none;
            border-radius: 15px;
            transition: transform 0.2s;
        }
        .stats-card:hover {
            transform: translateY(-5px);
        }
        .table-container {
            background: white;
            border-radius: 15px;
            padding: 20px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            margin-top: 20px;
        }
        .course-stats {
            background: white;
            border-radius: 15px;
            padding: 15px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
    </style>
</head>
<body class="bg-light">
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
        <div class="container">
            <a class="navbar-brand" href="student-dashboard.jsp">
                <i class="fas fa-user-graduate me-2"></i>Attendify
            </a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav me-auto">
                    <li class="nav-item">
                        <a class="nav-link" href="student-dashboard.jsp">Dashboard</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link active" href="view-attendance-record.jsp">My Attendance</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="student-check-in.jsp">Check In</a>
                    </li>
                </ul>
                <div class="d-flex">
                    <a href="logout.jsp" class="btn btn-light">
                        <i class="fas fa-sign-out-alt me-2"></i>Logout
                    </a>
                </div>
            </div>
        </div>
    </nav>

    <div class="container my-4">
        <div class="row mb-4">
            <div class="col">
                <h2><i class="fas fa-calendar-check me-2"></i>My Attendance Records</h2>
            </div>
        </div>

        <div class="row mb-4">
            <div class="col-md-4">
                <div class="card stats-card">
                    <div class="card-body">
                        <h5 class="card-title">Overall Attendance Rate</h5>
                        <%
                            try {
                                Class.forName("org.sqlite.JDBC");
                                connection = DriverManager.getConnection(jdbcURL);
                                pstmt = connection.prepareStatement(
                                    "SELECT COUNT(*) as total FROM attendance WHERE student_id = ?"
                                );
                                pstmt.setString(1, studentId);
                                rs = pstmt.executeQuery();

                                if (rs.next()) {
                                    int total = rs.getInt("total");
                                    double rate = total > 0 ? 100.0 : 0;
                                    out.println("<h2 class=\"mb-0\">" + String.format("%.1f%%", rate) + "</h2>");
                                }
                            } catch (Exception e) {
                                out.println("<h2 class=\"mb-0\">0%</h2>");
                            }
                        %>
                    </div>
                </div>
            </div>
        </div>

        <div class="table-container">
            <div class="table-responsive">
                <table class="table table-hover">
                    <thead>
                        <tr>
                            <th>Date</th>
                            <th>Course</th>
                            <th>Check-in Time</th>
                            <th>Location</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            try {
                                pstmt = connection.prepareStatement(
                                    "SELECT a.*, c.course_name " +
                                    "FROM attendance a " +
                                    "JOIN courses c ON a.course_code = c.course_code " +
                                    "WHERE a.student_id = ? " +
                                    "ORDER BY a.check_in_date DESC, a.check_in_time DESC"
                                );
                                pstmt.setString(1, studentId);
                                rs = pstmt.executeQuery();

                                while (rs.next()) {
                                    %>
                                    <tr>
                                        <td><%= rs.getString("check_in_date") %></td>
                                        <td><%= rs.getString("course_name") %></td>
                                        <td><%= rs.getString("check_in_time") %></td>
                                        <td>(<%= String.format("%.4f", rs.getDouble("latitude")) %>, <%= String.format("%.4f", rs.getDouble("longitude")) %>)</td>
                                        <td><span class="badge bg-success">Present</span></td>
                                    </tr>
                                    <%
                                }
                            } catch (Exception e) {
                                e.printStackTrace();
                                %>
                                <tr>
                                    <td colspan="5" class="text-center text-muted">
                                        <i class="fas fa-info-circle me-2"></i>No attendance records found
                                    </td>
                                </tr>
                                <%
                            } finally {
                                try {
                                    if (rs != null) rs.close();
                                    if (pstmt != null) pstmt.close();
                                    if (connection != null) connection.close();
                                } catch (SQLException e) {
                                    e.printStackTrace();
                                }
                            }
                        %>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
