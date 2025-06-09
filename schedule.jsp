<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.time.*" %>
<%@ page import="java.time.format.*" %>
<%
    if (session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp?error=Please log in to view schedule");
        return;
    }

    String userId = (String) session.getAttribute("userId");
    String jdbcURL = "jdbc:sqlite:C:/apache-tomcat-10.1.34/webapps/Attendify/attendify.db";
    Connection connection = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Schedule - Attendify</title>
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
        .schedule-card {
            transition: transform 0.2s;
        }
        .schedule-card:hover {
            transform: translateY(-5px);
        }
        .day-header {
            background-color: #007bff;
            color: white;
            padding: 10px;
            border-radius: 10px 10px 0 0;
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
        <h2 class="text-center mb-4">Weekly Schedule</h2>
        
        <div class="row">
            <%
                String[] days = {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday"};
                try {
                    Class.forName("org.sqlite.JDBC");
                    connection = DriverManager.getConnection(jdbcURL);
                    
                    for (String day : days) {
                        %>
                        <div class="col">
                            <div class="card schedule-card mb-4">
                                <div class="day-header text-center">
                                    <h5 class="mb-0"><%= day %></h5>
                                </div>
                                <div class="card-body p-2">
                                    <%
                                        pstmt = connection.prepareStatement(
                                            "SELECT cs.course_code, c.course_name, c.year_level, c.semester " +
                                            "FROM course_selections cs " +
                                            "JOIN courses c ON cs.course_code = c.course_code " +
                                            "WHERE cs.student_id = ? " +
                                            "ORDER BY c.year_level, c.semester"
                                        );
                                        pstmt.setString(1, userId);
                                        rs = pstmt.executeQuery();
                                        
                                        while (rs.next()) {
                                            %>
                                            <div class="p-2 border-bottom">
                                                <small class="d-block text-primary"><%= rs.getString("course_code") %></small>
                                                <small class="d-block"><%= rs.getString("course_name") %></small>
                                                <small class="d-block text-muted">
                                                    Year <%= rs.getInt("year_level") %>, 
                                                    Semester <%= rs.getInt("semester") %>
                                                </small>
                                            </div>
                                            <%
                                        }
                                    %>
                                </div>
                            </div>
                        </div>
                        <%
                    }
                } catch (Exception e) {
                    out.println("<div class='alert alert-danger'>Error loading schedule: " + e.getMessage() + "</div>");
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
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
