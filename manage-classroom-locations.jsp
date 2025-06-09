<%@ page contentType="text/html;charset=UTF-8" buffer="64kb" %>
<%@ page import="java.sql.*" %>
<%@ include file="WEB-INF/config.jsp" %>
<%
    // Clear any existing content in the buffer
    out.clear();
    // Ensure user is logged in and is a lecturer
    if (session.getAttribute("userId") == null || !"lecturer".equals(session.getAttribute("userType"))) {
        response.sendRedirect("login.jsp?error=Please log in as a lecturer");
        return;
    }

    String lecturerId = (String) session.getAttribute("userId");
    String jdbcURL = "jdbc:sqlite:C:/apache-tomcat-10.1.34/webapps/AttendanceManagementSystem/attendify.db";
    Connection connection = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    String message = "";
    String messageType = "";

    try {
        Class.forName("org.sqlite.JDBC");
        connection = DriverManager.getConnection(jdbcURL);

        // Handle form submission
        if (request.getMethod().equals("POST")) {
            String courseCode = request.getParameter("courseCode");
            double latitude = Double.parseDouble(request.getParameter("latitude"));
            double longitude = Double.parseDouble(request.getParameter("longitude"));
            int radius = Integer.parseInt(request.getParameter("radius"));

            // Verify the lecturer teaches this course
            pstmt = connection.prepareStatement(
                "SELECT 1 FROM courses WHERE course_code = ? AND lecturer_id = ?"
            );
            pstmt.setString(1, courseCode);
            pstmt.setString(2, lecturerId);
            rs = pstmt.executeQuery();

            if (rs.next()) {
                // Update or insert classroom location
                pstmt = connection.prepareStatement(
                    "INSERT OR REPLACE INTO classroom_locations (course_code, latitude, longitude, radius) VALUES (?, ?, ?, ?)"
                );
                pstmt.setString(1, courseCode);
                pstmt.setDouble(2, latitude);
                pstmt.setDouble(3, longitude);
                pstmt.setInt(4, radius);
                pstmt.executeUpdate();

                message = "Classroom location updated successfully!";
                messageType = "success";
            } else {
                message = "You are not authorized to manage this course.";
                messageType = "danger";
            }
        }
    } catch (Exception e) {
        message = "Error: " + e.getMessage();
        messageType = "danger";
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Classroom Locations - Attendify</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyCzZcL8Mli9-IDxcVmlK_vJbXzcXkXzf50&libraries=places"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <style>
        body { background-color: #f0f8ff; }
        .navbar { background-color: #007bff; }
        .card {
            border: none;
            border-radius: 15px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
        }
        #map {
            height: 400px;
            width: 100%;
            margin-bottom: 20px;
            border-radius: 8px;
            position: relative;
        }
        .pac-container {
            z-index: 1051 !important;
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
                        <a class="nav-link" href="lecturer-dashboard.jsp">Dashboard</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link active" href="manage-classroom-locations.jsp">Classroom Locations</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="manage-courses.jsp">Manage Courses</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="view-attendance.jsp">View Attendance</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="enrolled-students.jsp">
                            <i class="fas fa-users me-1"></i>Enrolled Students
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="index.jsp">Logout</a>
                    </li>
                </ul>
            </div>
        </div>
    </nav>

    <div class="container mt-5">
        <div class="row justify-content-center">
            <div class="col-md-8">
                <% if (!message.isEmpty()) { %>
                    <div class="alert alert-<%= messageType %> alert-dismissible fade show" role="alert">
                        <%= message %>
                        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                    </div>
                <% } %>

                <div class="card">
                    <div class="card-body">
                        <h2 class="text-center mb-4">Manage Classroom Locations</h2>
                        
                        <div id="map"></div>

                        <form method="post" id="locationForm" onsubmit="return validateForm()">
                            <div class="mb-3">
                                <label for="courseCode" class="form-label">Select Course</label>
                                <select class="form-select" id="courseCode" name="courseCode" required>
                                    <option value="">Choose a course...</option>
                                    <%
                                        try {
                                            pstmt = connection.prepareStatement(
                                                "SELECT c.course_code, c.course_name, " +
                                                "cl.latitude, cl.longitude, cl.radius " +
                                                "FROM courses c " +
                                                "LEFT JOIN classroom_locations cl ON c.course_code = cl.course_code " +
                                                "WHERE c.lecturer_id = ?"
                                            );
                                            pstmt.setString(1, lecturerId);
                                            rs = pstmt.executeQuery();
                                            
                                            while (rs.next()) {
                                                String code = rs.getString("course_code");
                                                String name = rs.getString("course_name");
                                                Double lat = rs.getObject("latitude") != null ? rs.getDouble("latitude") : null;
                                                Double lng = rs.getObject("longitude") != null ? rs.getDouble("longitude") : null;
                                                Integer rad = rs.getObject("radius") != null ? rs.getInt("radius") : null;
                                                %>
                                                <option value="<%= code %>" 
                                                    data-lat="<%= lat != null ? lat : "" %>"
                                                    data-lng="<%= lng != null ? lng : "" %>"
                                                    data-radius="<%= rad != null ? rad : "" %>">
                                                    <%= code %> - <%= name %>
                                                </option>
                                                <%
                                            }
                                        } catch (Exception e) {
                                            out.println("<option value=''>Error loading courses</option>");
                                        }
                                    %>
                                </select>
                            </div>

                            <div class="mb-3">
                                <div class="input-group">
                                    <input type="text" class="form-control" id="searchLocation" 
                                           placeholder="Search for a location (e.g., TTU Main Campus)">
                                    <button class="btn btn-primary" type="button" id="search-btn">
                                        <i class="fas fa-search"></i> Search
                                    </button>
                                </div>
                            </div>

                            <input type="hidden" id="latitude" name="latitude" required>
                            <input type="hidden" id="longitude" name="longitude" required>

                            <div class="mb-3">
                                <label for="radius" class="form-label">Check-in Radius (meters)</label>
                                <input type="number" class="form-control" id="radius" name="radius" 
                                       min="10" max="200" value="50" required>
                                <div class="form-text">Students must be within this distance from the classroom location to check in.</div>
                            </div>

                            <div class="text-center">
                                <button type="button" class="btn btn-primary me-2" id="current-location-btn">
                                    <i class="fas fa-location-dot me-2"></i>Use Current Location
                                </button>
                                <button type="submit" class="btn btn-success">
                                    <i class="fas fa-save me-2"></i>Save Location
                                </button>
                            </div>
                        </form>
                    </div>
                </div>

                <div class="card mt-4">
                    <div class="card-body">
                        <h3 class="text-center mb-4">Your Classroom Locations</h3>
                        <div class="table-responsive">
                            <table class="table table-hover">
                                <thead>
                                    <tr>
                                        <th>Course</th>
                                        <th>Location</th>
                                        <th>Radius</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        try {
                                            pstmt = connection.prepareStatement(
                                                "SELECT c.course_code, c.course_name, " +
                                                "cl.latitude, cl.longitude, cl.radius " +
                                                "FROM courses c " +
                                                "LEFT JOIN classroom_locations cl ON c.course_code = cl.course_code " +
                                                "WHERE c.lecturer_id = ? AND cl.latitude IS NOT NULL " +
                                                "ORDER BY c.course_code"
                                            );
                                            pstmt.setString(1, lecturerId);
                                            rs = pstmt.executeQuery();
                                            
                                            while (rs.next()) {
                                                String courseCode = rs.getString("course_code").replace("'", "\'");
                                                String courseName = rs.getString("course_name");
                                                double latitude = rs.getDouble("latitude");
                                                double longitude = rs.getDouble("longitude");
                                                int radius = rs.getInt("radius");
                                    %>
                                    <tr>
                                        <td><%= courseCode %> - <%= courseName %></td>
                                        <td><%= String.format("%.6f, %.6f", latitude, longitude) %></td>
                                        <td><%= radius %> meters</td>
                                        <td>
                                            <button type="button" class="btn btn-primary btn-sm edit-location-btn"
                                                    data-course="<%=courseCode%>"
                                                    data-lat="<%=String.format("%.6f", latitude)%>"
                                                    data-lng="<%=String.format("%.6f", longitude)%>"
                                                    data-radius="<%=radius%>">
                                                <i class="fas fa-edit"></i> Edit
                                            </button>
                                        </td>
                                    </tr>
                                    <%
                                            }
                                        } catch (Exception e) {
                                            out.println("<tr><td colspan='3' class='text-center'>Error loading locations</td></tr>");
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

    <script>
        let map;
        let marker;
        let circle;
        let searchBox;
        const defaultLocation = { lat: 6.6745, lng: -1.5716 }; // TTU coordinates

        document.addEventListener('DOMContentLoaded', function() {
            // Initialize Google Map
            initMap();

            // Edit location buttons
            document.querySelectorAll('.edit-location-btn').forEach(button => {
                button.addEventListener('click', function() {
                    const courseCode = this.getAttribute('data-course');
                    const lat = parseFloat(this.getAttribute('data-lat'));
                    const lng = parseFloat(this.getAttribute('data-lng'));
                    const radius = parseInt(this.getAttribute('data-radius'));
                    editLocation(courseCode, lat, lng, radius);
                });
            });

            // Search button
            document.getElementById('search-btn').addEventListener('click', function() {
                document.getElementById('searchLocation').focus();
            });

            // Use current location button
            document.getElementById('current-location-btn').addEventListener('click', getCurrentLocation);

            // Radius input
            document.getElementById('radius').addEventListener('input', updateCircle);
        });

        function initMap() {
            map = new google.maps.Map(document.getElementById('map'), {
                zoom: 15,
                center: defaultLocation,
                mapTypeId: google.maps.MapTypeId.ROADMAP,
                zoomControl: true,
                mapTypeControl: true,
                scaleControl: true,
                streetViewControl: true,
                rotateControl: true,
                fullscreenControl: true
            });

            // Places Autocomplete
            const input = document.getElementById('searchLocation');
            searchBox = new google.maps.places.Autocomplete(input);
            searchBox.bindTo('bounds', map);

            // Marker
            marker = new google.maps.Marker({
                map: map,
                draggable: true,
                animation: google.maps.Animation.DROP
            });

            // Circle
            circle = new google.maps.Circle({
                map: map,
                fillColor: '#007bff',
                fillOpacity: 0.2,
                strokeColor: '#007bff',
                strokeOpacity: 0.8,
                strokeWeight: 2
            });

            marker.addListener('dragend', function() {
                const pos = marker.getPosition();
                updateFormLocation(pos.lat(), pos.lng());
                updateCircle();
            });

            searchBox.addListener('place_changed', function() {
                const place = searchBox.getPlace();
                if (!place.geometry) {
                    alert('No location found for the entered address.');
                    return;
                }
                if (place.geometry.viewport) {
                    map.fitBounds(place.geometry.viewport);
                } else {
                    map.setCenter(place.geometry.location);
                    map.setZoom(17);
                }
                marker.setPosition(place.geometry.location);
                updateFormLocation(place.geometry.location.lat(), place.geometry.location.lng());
                updateCircle();
            });

            // If form already has coordinates, set marker and circle
            const lat = parseFloat(document.getElementById('latitude').value);
            const lng = parseFloat(document.getElementById('longitude').value);
            if (!isNaN(lat) && !isNaN(lng)) {
                const pos = new google.maps.LatLng(lat, lng);
                marker.setPosition(pos);
                map.setCenter(pos);
                updateCircle();
            } else {
                marker.setPosition(defaultLocation);
                map.setCenter(defaultLocation);
                updateCircle();
            }
        }

        function updateFormLocation(lat, lng) {
            document.getElementById('latitude').value = lat;
            document.getElementById('longitude').value = lng;
        }

        function updateCircle() {
            const radius = parseInt(document.getElementById('radius').value) || 50;
            circle.setRadius(radius);
            circle.setCenter(marker.getPosition());
        }

        function editLocation(courseCode, lat, lng, radius) {
            document.getElementById('courseCode').value = courseCode;
            document.getElementById('latitude').value = lat;
            document.getElementById('longitude').value = lng;
            document.getElementById('radius').value = radius;
            const pos = new google.maps.LatLng(parseFloat(lat), parseFloat(lng));
            marker.setPosition(pos);
            map.setCenter(pos);
            updateCircle();
        }

        function getCurrentLocation() {
            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(position => {
                    const lat = position.coords.latitude;
                    const lng = position.coords.longitude;
                    const pos = new google.maps.LatLng(lat, lng);
                    marker.setPosition(pos);
                    map.setCenter(pos);
                    updateFormLocation(lat, lng);
                    updateCircle();
                }, err => {
                    alert('Could not get your location: ' + err.message);
                });
            } else {
                alert('Geolocation is not supported by this browser.');
            }
        }
    </script>
</body>
</html>
<%
    try {
        if (rs != null) rs.close();
        if (pstmt != null) pstmt.close();
        if (connection != null) connection.close();
    } catch(Exception e) {
        out.println("Error closing resources: " + e.getMessage());
    }
%>
