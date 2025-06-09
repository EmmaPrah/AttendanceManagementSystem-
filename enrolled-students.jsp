<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%
    // Ensure user is logged in and is a lecturer
    if (session.getAttribute("userId") == null || !"lecturer".equals(session.getAttribute("userType"))) {
        response.sendRedirect("login.jsp?error=Please log in as a lecturer");
        return;
    }

    String lecturerId = (String) session.getAttribute("userId");
    String fullName = (String) session.getAttribute("fullName");
    String jdbcURL = "jdbc:sqlite:C:/apache-tomcat-10.1.34/webapps/AttendanceManagementSystem/attendify.db";
    Connection connection = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    // Get filter parameters
    String selectedCourse = request.getParameter("courseCode");
    String selectedDepartment = request.getParameter("department");
    String selectedLevel = request.getParameter("level");
    
    // Get list of departments and levels for filters
    Set<String> departments = new HashSet<>();
    Set<Integer> levels = new HashSet<>();
    
    try {
        Class.forName("org.sqlite.JDBC");
        connection = DriverManager.getConnection(jdbcURL);
        
        // Get departments and levels from students enrolled in lecturer's courses
        pstmt = connection.prepareStatement(
            "SELECT DISTINCT u.department, u.level FROM users u " +
            "JOIN course_selections cs ON u.user_id = cs.student_id " +
            "JOIN courses c ON cs.course_code = c.course_code " +
            "WHERE c.lecturer_id = ? AND u.department IS NOT NULL AND u.department != '' " +
            "ORDER BY u.department, u.level"
        );
        pstmt.setString(1, lecturerId);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            String dept = rs.getString("department");
            int level = rs.getInt("level");
            if (dept != null && !dept.isEmpty()) {
                departments.add(dept);
            }
            if (level > 0) {
                levels.add(level);
            }
        }
    } catch (Exception e) {
        // Error handling
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Enrolled Students - Attendify</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        body { 
            background-color: #f0f8ff;
            min-height: 100vh;
        }
        .navbar { 
            background-color: #007bff;
        }
        .card {
            border: none;
            border-radius: 15px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
            margin-bottom: 20px;
            transition: transform 0.2s;
        }
        .card:hover {
            transform: translateY(-5px);
        }
        .student-card {
            transition: all 0.3s ease;
        }
        .student-card:hover {
            background-color: #f8f9fa;
        }
        .attendance-badge {
            font-size: 0.9rem;
            padding: 0.4rem 0.6rem;
        }
        .attendance-high {
            background-color: #28a745;
        }
        .attendance-medium {
            background-color: #ffc107;
            color: #212529;
        }
        .attendance-low {
            background-color: #dc3545;
        }
        .filter-card {
            background-color: #f8f9fa;
        }
        .filter-title {
            font-size: 1.2rem;
            font-weight: 500;
            margin-bottom: 1rem;
        }
        .filter-section {
            padding: 1rem;
            border-radius: 10px;
        }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark">
        <div class="container">
            <a class="navbar-brand" href="#">
                <i class="fas fa-chalkboard-teacher me-2"></i>Attendify
            </a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav me-auto">
                    <li class="nav-item">
                        <a class="nav-link" href="lecturer-dashboard.jsp">
                            <i class="fas fa-home me-1"></i>Dashboard
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="manage-classroom-locations.jsp">
                            <i class="fas fa-map-marker-alt me-1"></i>Classroom Locations
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="manage-courses.jsp">
                            <i class="fas fa-book me-1"></i>Manage Courses
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="view-attendance.jsp">
                            <i class="fas fa-clipboard-list me-1"></i>View Attendance
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link active" href="enrolled-students.jsp">
                            <i class="fas fa-users me-1"></i>Enrolled Students
                        </a>
                    </li>
                </ul>
                <ul class="navbar-nav">
                    <li class="nav-item dropdown">
                        <a class="nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-bs-toggle="dropdown">
                            <i class="fas fa-user-circle me-1"></i><%= fullName %>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end">
                            <li><a class="dropdown-item" href="profile.jsp">Profile</a></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item" href="logout.jsp">Logout</a></li>
                        </ul>
                    </li>
                </ul>
            </div>
        </div>
    </nav>

    <div class="container mt-4">
        <div class="row mb-4">
            <div class="col">
                <h2><i class="fas fa-users me-2"></i>Enrolled Students</h2>
                <p class="text-muted">View all students enrolled in your courses and their attendance records</p>
            </div>
        </div>

        <%-- Filters --%>
        <div class="card filter-card mb-4">
            <div class="card-body">
                <h5 class="card-title">Filter by Course</h5>
                <form action="enrolled-students.jsp" method="get" class="row g-3">
                    <div class="col-md-4">
                        <label for="courseSelect" class="form-label">Course</label>
                        <select id="courseSelect" name="courseCode" class="form-select">
                            <option value="">All Courses</option>
                            <%
                                try {
                                    pstmt = connection.prepareStatement(
                                        "SELECT course_code, course_name FROM courses WHERE lecturer_id = ? ORDER BY course_code"
                                    );
                                    pstmt.setString(1, lecturerId);
                                    rs = pstmt.executeQuery();
                                    
                                    while (rs.next()) {
                                        String courseCode = rs.getString("course_code");
                                        String courseName = rs.getString("course_name");
                                        boolean isSelected = courseCode.equals(selectedCourse);
                                        %>
                                        <option value="<%= courseCode %>" <%= isSelected ? "selected" : "" %>><%= courseCode %> - <%= courseName %></option>
                                        <%
                                    }
                                } catch (Exception e) {
                                    out.println("<option value=''>Error loading courses</option>");
                                }
                            %>
                        </select>
                    </div>
                    
                    <div class="col-md-4">
                        <label for="departmentSelect" class="form-label">Department</label>
                        <select id="departmentSelect" name="department" class="form-select">
                            <option value="">All Departments</option>
                            <% 
                                for (String dept : departments) {
                                    boolean isSelected = dept.equals(selectedDepartment);
                            %>
                                <option value="<%= dept %>" <%= isSelected ? "selected" : "" %>><%= dept %></option>
                            <% } %>
                        </select>
                    </div>
                    
                    <div class="col-md-2">
                        <label for="levelSelect" class="form-label">Level</label>
                        <select id="levelSelect" name="level" class="form-select">
                            <option value="">All Levels</option>
                            <% 
                                List<Integer> sortedLevels = new ArrayList<>(levels);
                                Collections.sort(sortedLevels);
                                for (Integer lvl : sortedLevels) {
                                    boolean isSelected = selectedLevel != null && lvl.toString().equals(selectedLevel);
                            %>
                                <option value="<%= lvl %>" <%= isSelected ? "selected" : "" %>><%= lvl %></option>
                            <% } %>
                        </select>
                    </div>
                    
                    <div class="col-md-2 d-flex align-items-end">
                        <button type="submit" class="btn btn-primary w-100">
                            <i class="fas fa-filter me-2"></i>Apply Filters
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <%-- Stats Card --%>
        <div class="row mb-4">
            <div class="col-md-12">
                <div class="card bg-primary text-white">
                    <div class="card-body">
                        <div class="row">
                            <div class="col-md-6">
                                <h5 class="card-title">Total Enrolled Students</h5>
                                <%
                                    int totalEnrolled = 0;
                                    try {
                                        String countQuery = "SELECT COUNT(DISTINCT cs.student_id) AS total FROM course_selections cs " +
                                                           "JOIN courses c ON cs.course_code = c.course_code " +
                                                           "JOIN users u ON cs.student_id = u.user_id " +
                                                           "WHERE c.lecturer_id = ?";
                                        
                                        List<String> params = new ArrayList<>();
                                        params.add(lecturerId);
                                        
                                        if (selectedCourse != null && !selectedCourse.isEmpty()) {
                                            countQuery += " AND cs.course_code = ?";
                                            params.add(selectedCourse);
                                        }
                                        
                                        if (selectedDepartment != null && !selectedDepartment.isEmpty()) {
                                            countQuery += " AND u.department = ?";
                                            params.add(selectedDepartment);
                                        }
                                        
                                        if (selectedLevel != null && !selectedLevel.isEmpty()) {
                                            countQuery += " AND u.level = ?";
                                            params.add(selectedLevel);
                                        }
                                        
                                        pstmt = connection.prepareStatement(countQuery);
                                        for (int i = 0; i < params.size(); i++) {
                                            pstmt.setString(i + 1, params.get(i));
                                        }
                                        
                                        rs = pstmt.executeQuery();
                                        if (rs.next()) {
                                            totalEnrolled = rs.getInt("total");
                                        }
                                    } catch (Exception e) {
                                        // Error handling
                                    }
                                %>
                                <h2 class="display-4"><%= totalEnrolled %></h2>
                                <p class="mb-0">
                                    <% if (selectedCourse != null && !selectedCourse.isEmpty() || 
                                          selectedDepartment != null && !selectedDepartment.isEmpty() || 
                                          selectedLevel != null && !selectedLevel.isEmpty()) { %>
                                        Students matching selected filters
                                    <% } else { %>
                                        Students enrolled across all your courses
                                    <% } %>
                                </p>
                            </div>
                            <div class="col-md-6">
                                <div class="d-flex justify-content-end h-100 align-items-center">
                                    <a href="enrolled-students.jsp" class="btn btn-outline-light">
                                        <i class="fas fa-times me-2"></i>Clear All Filters
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <%-- Students List --%>
        <div class="row">
            <div class="col-12">
                <div class="card">
                    <div class="card-header bg-primary text-white">
                        <h5 class="mb-0">Student Enrollment & Attendance</h5>
                    </div>
                    <div class="card-body">
                        <div class="table-responsive">
                            <table class="table table-hover">
                                <thead>
                                    <tr>
                                        <th>Student ID</th>
                                        <th>Full Name</th>
                                        <th>Course</th>
                                        <th>Department</th>
                                        <th>Level</th>
                                        <th>Total Check-ins</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        try {
                                            String query = 
                                                "SELECT cs.student_id, u.full_name, u.department, u.level, " +
                                                "cs.course_code, c.course_name, " +
                                                "(SELECT COUNT(*) FROM attendance a WHERE a.student_id = cs.student_id AND a.course_code = cs.course_code) as check_in_count " +
                                                "FROM course_selections cs " +
                                                "JOIN users u ON cs.student_id = u.user_id " +
                                                "JOIN courses c ON cs.course_code = c.course_code " +
                                                "WHERE c.lecturer_id = ? ";
                                            
                                            List<String> params = new ArrayList<>();
                                            params.add(lecturerId);
                                            
                                            if (selectedCourse != null && !selectedCourse.isEmpty()) {
                                                query += "AND cs.course_code = ? ";
                                                params.add(selectedCourse);
                                            }
                                            
                                            if (selectedDepartment != null && !selectedDepartment.isEmpty()) {
                                                query += "AND u.department = ? ";
                                                params.add(selectedDepartment);
                                            }
                                            
                                            if (selectedLevel != null && !selectedLevel.isEmpty()) {
                                                query += "AND u.level = ? ";
                                                params.add(selectedLevel);
                                            }
                                            
                                            query += "ORDER BY u.full_name";
                                            
                                            pstmt = connection.prepareStatement(query);
                                            for (int i = 0; i < params.size(); i++) {
                                                pstmt.setString(i + 1, params.get(i));
                                            }
                                            
                                            rs = pstmt.executeQuery();
                                            
                                            boolean hasStudents = false;
                                            
                                            while (rs.next()) {
                                                hasStudents = true;
                                                String studentId = rs.getString("student_id");
                                                String studentName = rs.getString("full_name");
                                                String courseCode = rs.getString("course_code");
                                                String courseName = rs.getString("course_name");
                                                String department = rs.getString("department");
                                                int level = rs.getInt("level");
                                                int checkInCount = rs.getInt("check_in_count");
                                                
                                                // Determine attendance status for badge color
                                                String badgeClass = "bg-secondary";
                                                if (checkInCount > 10) {
                                                    badgeClass = "attendance-high";
                                                } else if (checkInCount > 5) {
                                                    badgeClass = "attendance-medium";
                                                } else if (checkInCount > 0) {
                                                    badgeClass = "attendance-low";
                                                }
                                                %>
                                                <tr class="student-card">
                                                    <td><%= studentId %></td>
                                                    <td><%= studentName %></td>
                                                    <td><%= courseCode %> - <%= courseName %></td>
                                                    <td><%= department %></td>
                                                    <td><%= level %></td>
                                                    <td>
                                                        <span class="badge <%= badgeClass %> attendance-badge">
                                                            <%= checkInCount %> check-ins
                                                        </span>
                                                    </td>
                                                    <td>
                                                        <a href="view-student-attendance.jsp?studentId=<%= studentId %>&courseCode=<%= courseCode %>" 
                                                           class="btn btn-sm btn-outline-primary">
                                                            <i class="fas fa-clipboard-list me-1"></i>View Details
                                                        </a>
                                                    </td>
                                                </tr>
                                                <%
                                            }
                                            
                                            if (!hasStudents) {
                                                %>
                                                <tr>
                                                    <td colspan="7" class="text-center py-4">
                                                        <div class="alert alert-info mb-0">
                                                            <i class="fas fa-info-circle me-2"></i>
                                                            No students found matching the selected filters.
                                                        </div>
                                                    </td>
                                                </tr>
                                                <%
                                            }
                                            
                                        } catch (Exception e) {
                                            %>
                                            <tr>
                                                <td colspan="7" class="text-center py-4">
                                                    <div class="alert alert-danger mb-0">
                                                        <i class="fas fa-exclamation-circle me-2"></i>
                                                        Error retrieving student data: <%= e.getMessage() %>
                                                    </div>
                                                </td>
                                            </tr>
                                            <%
                                        } finally {
                                            try {
                                                if (rs != null) rs.close();
                                                if (pstmt != null) pstmt.close();
                                                if (connection != null) connection.close();
                                            } catch (SQLException e) {
                                                // Ignore
                                            }
                                        }
                                    %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <footer class="bg-light text-center text-muted py-3 mt-5">
        <div class="container">
            <p class="mb-0">&copy; 2025 Attendify - Attendance Management System</p>
        </div>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
