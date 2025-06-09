<%@ page import="javax.servlet.http.*" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<%
    // Ensure user is logged in
    if (session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp?error=Please log in to view your profile");
        return;
    }
    String userType = (String) session.getAttribute("userType");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>User Profile - Attendify</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="css/style.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        .profile-container {
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
        .profile-stats {
            background: #f8f9fa;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
        }
        .profile-info-item {
            padding: 15px;
            border-bottom: 1px solid #eee;
            transition: background-color 0.2s;
        }
        .profile-info-item:hover {
            background-color: #f8f9fa;
        }
        .profile-info-item:last-child {
            border-bottom: none;
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
                    <li class="nav-item">
                        <a class="nav-link" href="enrolled-students.jsp">
                            <i class="fas fa-users me-1"></i>Enrolled Students
                        </a>
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
        <div class="profile-container">
            <div class="profile-header text-center">
                <i class="<%= "student".equals(userType) ? "fas fa-user-graduate" : "fas fa-chalkboard-teacher" %> fa-3x mb-3"></i>
                <h2 class="mb-2"><%= session.getAttribute("fullName") %></h2>
                <p class="mb-0"><%= "student".equals(userType) ? "Student" : "Lecturer" %></p>
            </div>

            <div class="profile-stats row text-center mb-4">
                <div class="col">
                    <h4 class="mb-0"><%= session.getAttribute("faculty") %></h4>
                    <small class="text-muted">Faculty</small>
                </div>
                <div class="col">
                    <h4 class="mb-0"><%= session.getAttribute("department") %></h4>
                    <small class="text-muted">Department</small>
                </div>
                <% if ("student".equals(userType)) { %>
                <div class="col">
                    <h4 class="mb-0"><%= session.getAttribute("level") != null ? session.getAttribute("level") : "0" %></h4>
                    <small class="text-muted">Level</small>
                </div>
                <% } %>
            </div>

            <div class="profile-info">
                <div class="profile-info-item">
                    <i class="fas fa-id-card me-2 text-primary"></i>
                    <strong>User ID:</strong> <%= session.getAttribute("userId") %>
                </div>
                <div class="profile-info-item">
                    <i class="fas fa-envelope me-2 text-primary"></i>
                    <strong>Email:</strong> <%= session.getAttribute("userEmail") %>
                </div>
                <div class="profile-info-item">
                    <i class="fas fa-user-tag me-2 text-primary"></i>
                    <strong>Role:</strong> <%= "student".equals(userType) ? "Student" : "Lecturer" %>
                </div>
            </div>

            <div class="text-center mt-4">
                <a href="edit-profile.jsp" class="btn btn-primary">
                    <i class="fas fa-edit me-2"></i>Edit Profile
                </a>
            </div>
        </div>
    </div>

    <footer class="bg-dark text-light py-4 mt-5">
        <div class="container text-center">
            <p>&copy; 2024 Attendify. All rights reserved.</p>
        </div>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script src="js/profile.js"></script>
</body>
</html>