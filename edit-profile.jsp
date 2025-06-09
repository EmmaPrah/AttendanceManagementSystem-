<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%
    // Ensure user is logged in
    if (session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp?error=Please log in to edit your profile");
        return;
    }
    String userType = (String) session.getAttribute("userType");
    String userId = (String) session.getAttribute("userId");
    
    // Get user details from database
    String jdbcURL = "jdbc:sqlite:C:/apache-tomcat-10.1.34/webapps/AttendanceManagementSystem/attendify.db";
    Connection connection = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    String fullName = "";
    String email = "";
    String faculty = "";
    String department = "";
    int level = 0;
    
    try {
        Class.forName("org.sqlite.JDBC");
        connection = DriverManager.getConnection(jdbcURL);
        pstmt = connection.prepareStatement("SELECT * FROM users WHERE user_id = ?");
        pstmt.setString(1, userId);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            fullName = rs.getString("full_name");
            email = rs.getString("email");
            faculty = rs.getString("faculty");
            department = rs.getString("department");
            level = rs.getInt("level");
        }
    } catch (Exception e) {
        e.printStackTrace();
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
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Edit Profile - Attendify</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        .edit-profile-container {
            background: white;
            border-radius: 15px;
            padding: 30px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .profile-header {
            background: linear-gradient(45deg, #0072ff, #00c6ff);
            color: white;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 30px;
        }
        .form-group {
            margin-bottom: 20px;
        }
        .form-control {
            border-radius: 8px;
            padding: 12px;
            border: 1px solid #dee2e6;
        }
        .form-control:focus {
            border-color: #0072ff;
            box-shadow: 0 0 0 0.2rem rgba(0, 114, 255, 0.25);
        }
        .btn-save {
            background: linear-gradient(45deg, #0072ff, #00c6ff);
            border: none;
            padding: 12px 30px;
            font-weight: 500;
        }
        .btn-save:hover {
            background: linear-gradient(45deg, #005acc, #00b3ff);
        }
    </style>
</head>
<body class="bg-light">
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
        <div class="container">
            <a class="navbar-brand" href="<%= "student".equals(userType) ? "student-dashboard.jsp" : "lecturer-dashboard.jsp" %>">
                <i class="<%= "student".equals(userType) ? "fas fa-user-graduate" : "fas fa-chalkboard-teacher" %> me-2"></i>Attendify
            </a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav me-auto">
                    <li class="nav-item">
                        <a class="nav-link" href="<%= "student".equals(userType) ? "student-dashboard.jsp" : "lecturer-dashboard.jsp" %>">Dashboard</a>
                    </li>
                    <% if ("student".equals(userType)) { %>
                    <li class="nav-item">
                        <a class="nav-link" href="view-attendance-record.jsp">My Attendance</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="student-check-in.jsp">Check In</a>
                    </li>
                    <% } else { %>
                    <li class="nav-item">
                        <a class="nav-link" href="view-attendance.jsp">View Attendance</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="manage-courses.jsp">Manage Courses</a>
                    </li>
                    <% } %>
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
        <div class="edit-profile-container">
            <div class="profile-header text-center">
                <i class="fas fa-user-edit fa-3x mb-3"></i>
                <h2 class="mb-0">Edit Profile</h2>
            </div>

            <% 
            String error = request.getParameter("error");
            if (error != null && !error.isEmpty()) {
            %>
            <div class="alert alert-danger alert-dismissible fade show" role="alert">
                <i class="fas fa-exclamation-circle me-2"></i><%= error %>
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
            <%
            }
            String success = request.getParameter("success");
            if (success != null && !success.isEmpty()) {
            %>
            <div class="alert alert-success alert-dismissible fade show" role="alert">
                <i class="fas fa-check-circle me-2"></i><%= success %>
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
            <%
            }
            %>

            <form action="update-profile.jsp" method="POST" class="mt-4">
                <div class="form-group">
                    <label for="fullName" class="form-label">
                        <i class="fas fa-user me-2 text-primary"></i>Full Name
                    </label>
                    <input type="text" class="form-control" id="fullName" name="fullName" value="<%= fullName %>" required>
                </div>

                <div class="form-group">
                    <label for="email" class="form-label">
                        <i class="fas fa-envelope me-2 text-primary"></i>Email
                    </label>
                    <input type="email" class="form-control" id="email" name="email" value="<%= email %>" required>
                </div>

                <div class="form-group">
                    <label for="faculty" class="form-label">
                        <i class="fas fa-university me-2 text-primary"></i>Faculty
                    </label>
                    <input type="text" class="form-control" id="faculty" name="faculty" value="<%= faculty %>" required>
                </div>

                <div class="form-group">
                    <label for="department" class="form-label">
                        <i class="fas fa-building me-2 text-primary"></i>Department
                    </label>
                    <input type="text" class="form-control" id="department" name="department" value="<%= department %>" required>
                </div>

                <% if ("student".equals(userType)) { %>
                <div class="form-group">
                    <label for="level" class="form-label">
                        <i class="fas fa-sort-numeric-down me-2 text-primary"></i>Level
                    </label>
                    <select class="form-control" id="level" name="level" required>
                        <option value="100" <%= level == 100 ? "selected" : "" %>>100</option>
                        <option value="200" <%= level == 200 ? "selected" : "" %>>200</option>
                        <option value="300" <%= level == 300 ? "selected" : "" %>>300</option>
                        <option value="400" <%= level == 400 ? "selected" : "" %>>400</option>
                        <option value="500" <%= level == 500 ? "selected" : "" %>>500</option>
                    </select>
                </div>
                <% } %>

                <div class="form-group">
                    <label for="currentPassword" class="form-label">
                        <i class="fas fa-lock me-2 text-primary"></i>Current Password
                    </label>
                    <input type="password" class="form-control" id="currentPassword" name="currentPassword" required>
                    <small class="text-muted">Enter your current password to save changes</small>
                </div>

                <div class="form-group">
                    <label for="newPassword" class="form-label">
                        <i class="fas fa-key me-2 text-primary"></i>New Password
                    </label>
                    <input type="password" class="form-control" id="newPassword" name="newPassword">
                    <small class="text-muted">Leave blank if you don't want to change your password</small>
                </div>

                <div class="text-center mt-4">
                    <a href="profile.jsp" class="btn btn-light me-2">
                        <i class="fas fa-times me-2"></i>Cancel
                    </a>
                    <button type="submit" class="btn btn-primary btn-save">
                        <i class="fas fa-save me-2"></i>Save Changes
                    </button>
                </div>
            </form>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
