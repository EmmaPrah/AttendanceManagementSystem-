<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.io.File" %>
<!DOCTYPE html>
<html>
<head>
    <title>Database Setup - Attendify</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="container mt-4">
    <div class="card">
        <div class="card-body">
            <h2 class="card-title mb-4">Setting up Database...</h2>
            <%
                // Database connection details
                String dbPath = "C:/apache-tomcat-10.1.34/webapps/AttendanceManagementSystem/attendify.db";
                String jdbcURL = "jdbc:sqlite:" + dbPath;
                Connection connection = null;
                Statement statement = null;
                ResultSet tables = null;
                DatabaseMetaData metaData = null;

                try {
                    // Ensure the database directory exists
                    File dbFile = new File(dbPath);
                    if (!dbFile.getParentFile().exists()) {
                        dbFile.getParentFile().mkdirs();
                    }

                    // Load the JDBC driver
                    Class.forName("org.sqlite.JDBC");
                    
                    // Create connection with WAL mode enabled
                    connection = DriverManager.getConnection(jdbcURL + "?journal_mode=WAL&busy_timeout=5000");
                    
                    // Set busy timeout
                    statement = connection.createStatement();
                    statement.execute("PRAGMA busy_timeout=5000");

                    // Enable foreign key support
                    statement.execute("PRAGMA foreign_keys = ON");

                    // Check if tables exist
                    metaData = connection.getMetaData();

                    // Create users table if it doesn't exist
                    tables = metaData.getTables(null, null, "users", null);
                    if (!tables.next()) {
                        statement.executeUpdate(
                            "CREATE TABLE users (" +
                            "user_id TEXT PRIMARY KEY, " +
                            "full_name TEXT NOT NULL, " +
                            "email TEXT UNIQUE NOT NULL, " +
                            "password TEXT NOT NULL, " +
                            "user_type TEXT NOT NULL CHECK (user_type IN ('student', 'lecturer')), " +
                            "faculty TEXT, " +
                            "department TEXT, " +
                            "level INTEGER CHECK (level IN (100, 200, 300, 400))" +
                            ")"
                        );

                        // Insert test data
                        statement.executeUpdate(
                            "INSERT INTO users (user_id, full_name, email, password, user_type, faculty, department) " +
                            "VALUES ('L001', 'Dr. John Smith', 'john.smith@example.com', 'password123', 'lecturer', 'Engineering', 'Computer Science')"
                        );

                        statement.executeUpdate(
                            "INSERT INTO users (user_id, full_name, email, password, user_type, faculty, department, level) " +
                            "VALUES ('S001', 'Jane Doe', 'jane.doe@example.com', 'password123', 'student', 'Engineering', 'Computer Science', 300)"
                        );
                    }

                    // Create courses table if it doesn't exist
                    tables = metaData.getTables(null, null, "courses", null);
                    if (!tables.next()) {
                        statement.executeUpdate(
                            "CREATE TABLE courses (" +
                            "course_code TEXT PRIMARY KEY, " +
                            "course_name TEXT NOT NULL, " +
                            "department TEXT NOT NULL, " +
                            "lecturer_id TEXT NOT NULL, " +
                            "level INTEGER NOT NULL CHECK (level IN (100, 200, 300, 400)), " +
                            "semester INTEGER NOT NULL CHECK (semester IN (1, 2)), " +
                            "FOREIGN KEY (lecturer_id) REFERENCES users(user_id)" +
                            ")"
                        );

                        // Insert test course
                        statement.executeUpdate(
                            "INSERT INTO courses (course_code, course_name, department, lecturer_id, level, semester) " +
                            "VALUES ('CS301', 'Database Systems', 'Computer Science', 'L001', 300, 1)"
                        );
                    }

                    // Create course_selections table if it doesn't exist
                    tables = metaData.getTables(null, null, "course_selections", null);
                    if (!tables.next()) {
                        statement.executeUpdate(
                            "CREATE TABLE course_selections (" +
                            "student_id TEXT, " +
                            "course_code TEXT, " +
                            "PRIMARY KEY (student_id, course_code), " +
                            "FOREIGN KEY (student_id) REFERENCES users(user_id), " +
                            "FOREIGN KEY (course_code) REFERENCES courses(course_code)" +
                            ")"
                        );

                        // Insert test course selection
                        statement.executeUpdate(
                            "INSERT INTO course_selections (student_id, course_code) " +
                            "VALUES ('S001', 'CS301')"
                        );
                    }

                    // Create classroom_locations table if it doesn't exist
                    tables = metaData.getTables(null, null, "classroom_locations", null);
                    if (!tables.next()) {
                        statement.executeUpdate(
                            "CREATE TABLE classroom_locations (" +
                            "course_code TEXT PRIMARY KEY, " +
                            "latitude REAL NOT NULL, " +
                            "longitude REAL NOT NULL, " +
                            "radius INTEGER NOT NULL, " +
                            "FOREIGN KEY (course_code) REFERENCES courses(course_code)" +
                            ")"
                        );
                    
                        // Insert test classroom location
                        statement.executeUpdate(
                            "INSERT INTO classroom_locations (course_code, latitude, longitude, radius) " +
                            "VALUES ('CS301', 4.8978, -1.7551, 50)"
                        );
                    }

                    // Create voice_prints table if it doesn't exist
                    tables = metaData.getTables(null, null, "voice_prints", null);
                    if (!tables.next()) {
                        statement.executeUpdate(
                            "CREATE TABLE voice_prints (" +
                            "student_id TEXT NOT NULL, " +
                            "voice_data BLOB NOT NULL, " +
                            "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                            "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                            "FOREIGN KEY (student_id) REFERENCES users(user_id)" +
                            ")"
                        );
                    }

                    // Create attendance table if it doesn't exist
                    tables = metaData.getTables(null, null, "attendance", null);
                    if (!tables.next()) {
                        statement.executeUpdate(
                            "CREATE TABLE attendance (" +
                            "student_id TEXT, " +
                            "course_code TEXT, " +
                            "check_in_date DATE NOT NULL, " +
                            "check_in_time TIME NOT NULL, " +
                            "latitude REAL NOT NULL, " +
                            "longitude REAL NOT NULL, " +
                            "voice_verified BOOLEAN DEFAULT 0, " +
                            "PRIMARY KEY (student_id, course_code, check_in_date), " +
                            "FOREIGN KEY (student_id) REFERENCES users(user_id), " +
                            "FOREIGN KEY (course_code) REFERENCES courses(course_code)" +
                            ")"
                        );
                    }

                    // Create archived attendance table if it doesn't exist
                    tables = metaData.getTables(null, null, "archived_attendance", null);
                    if (!tables.next()) {
                        statement.executeUpdate(
                            "CREATE TABLE archived_attendance (" +
                            "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                            "student_id TEXT NOT NULL, " +
                            "course_code TEXT NOT NULL, " +
                            "check_in_date DATE NOT NULL, " +
                            "check_in_time TIME NOT NULL, " +
                            "latitude REAL NOT NULL, " +
                            "longitude REAL NOT NULL, " +
                            "voice_verified BOOLEAN DEFAULT 0, " +
                            "archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                            "week_number INTEGER NOT NULL, " +
                            "year INTEGER NOT NULL, " +
                            "FOREIGN KEY (student_id) REFERENCES users(user_id), " +
                            "FOREIGN KEY (course_code) REFERENCES courses(course_code)" +
                            ")"
                        );
                    }

                    out.println("<div class='alert alert-success'>Database setup completed successfully!</div>");
                } catch(Exception e) {
                    e.printStackTrace(); // Log the full stack trace
                    out.println("<div class='alert alert-danger'>");
                    out.println("Error!<br>");
                    out.println("Failed to set up database: " + e.getMessage());
                    out.println("<br>Please ensure you have proper permissions and try again.");
                    out.println("</div>");
                } finally {
                    try {
                        if(statement != null) statement.close();
                        if(connection != null) connection.close();
                    } catch(SQLException e) {
                        e.printStackTrace();
                    }
                }
            %>
            <div class="mt-3">
                <a href="setupDatabase.jsp" class="btn btn-primary me-2">Try Again</a>
                <a href="login.jsp" class="btn btn-secondary">Go to Login</a>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
