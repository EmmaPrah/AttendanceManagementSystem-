<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Attendify - Smart Attendance System</title>
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Custom CSS -->
    <link href="css/style.css" rel="stylesheet">
    <!-- Font Awesome -->
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/fullcalendar/5.10.1/main.min.css" rel="stylesheet" />
    <style>
        body {
            background-color: #f0f8ff;
        }
        .feature-card {
            border: 2px solid #007bff;
            border-radius: 10px;
            transition: transform 0.2s;
        }
        .feature-card:hover {
            transform: scale(1.05);
        }
        .btn-custom {
            background-color: #28a745;
            color: white;
        }
        .btn-custom:hover {
            background-color: #218838;
        }
    </style>
</head>
<body class="bg-light">
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
        <div class="container">
            <a class="navbar-brand" href="#">
                <i class="fas fa-microphone-alt me-2"></i>Attendify
            </a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav ms-auto">
                    <li class="nav-item">
                        <a class="nav-link" href="login.jsp">Login</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="register.jsp">Register</a>
            </div>
        </div>
    </nav>

    <section class="hero-section">
        <div class="container text-center">
            <h1 class="display-4 mb-4">Welcome to Attendify</h1>
            <p class="lead mb-5">The next generation attendance management system for modern education</p>
            <div class="d-flex justify-content-center gap-3">
                <a href="register.jsp" class="btn btn-primary btn-lg">Get Started</a>
                <a href="#features" class="btn btn-outline-primary btn-lg">Learn More</a>
            </div>
        </div>
    </section>

    <section id="features" class="container mb-5">
        <h2 class="text-center mb-5">Key Features</h2>
        <div class="row g-4">
            <div class="col-md-4">
                <div class="feature-card card h-100">
                    <div class="card-body text-center p-4">
                        <i class="fas fa-map-marker-alt feature-icon"></i>
                        <h3 class="h4 mb-3">Smart Geolocation</h3>
                        <p class="text-muted">Verify student attendance using precise location tracking within campus boundaries</p>
                        <ul class="list-unstyled text-start">
                            <li><i class="fas fa-check text-success me-2"></i>Accurate location verification</li>
                            <li><i class="fas fa-check text-success me-2"></i>Customizable radius settings</li>
                            <li><i class="fas fa-check text-success me-2"></i>Real-time tracking</li>
                        </ul>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="feature-card card h-100">
                    <div class="card-body text-center p-4">
                        <i class="fas fa-chart-bar feature-icon"></i>
                        <h3 class="h4 mb-3">Advanced Analytics</h3>
                        <p class="text-muted">Comprehensive attendance analytics and reporting system</p>
                        <ul class="list-unstyled text-start">
                            <li><i class="fas fa-check text-success me-2"></i>Detailed attendance reports</li>
                            <li><i class="fas fa-check text-success me-2"></i>Trend analysis</li>
                            <li><i class="fas fa-check text-success me-2"></i>Exportable data</li>
                        </ul>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="feature-card card h-100">
                    <div class="card-body text-center p-4">
                        <i class="fas fa-microphone feature-icon"></i>
                        <h3 class="h4 mb-3">Voice Check-in</h3>
                        <p class="text-muted">Simple and quick attendance marking using voice recognition</p>
                        <ul class="list-unstyled text-start">
                            <li><i class="fas fa-check text-success me-2"></i>Voice-activated check-in</li>
                            <li><i class="fas fa-check text-success me-2"></i>Quick recognition</li>
                            <li><i class="fas fa-check text-success me-2"></i>Hands-free operation</li>
                        </ul>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="feature-card card h-100">
                    <div class="card-body text-center p-4">
                        <i class="fas fa-clock feature-icon"></i>
                        <h3 class="h4 mb-3">Real-time Monitoring</h3>
                        <p class="text-muted">Monitor attendance and class participation in real-time</p>
                        <ul class="list-unstyled text-start">
                            <li><i class="fas fa-check text-success me-2"></i>Live attendance tracking</li>
                            <li><i class="fas fa-check text-success me-2"></i>Instant notifications</li>
                            <li><i class="fas fa-check text-success me-2"></i>Class progress tracking</li>
                        </ul>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="feature-card card h-100">
                    <div class="card-body text-center p-4">
                        <i class="fas fa-calendar-alt feature-icon"></i>
                        <h3 class="h4 mb-3">Smart Scheduling</h3>
                        <p class="text-muted">Intelligent class scheduling and attendance management</p>
                        <ul class="list-unstyled text-start">
                            <li><i class="fas fa-check text-success me-2"></i>Automated timetables</li>
                            <li><i class="fas fa-check text-success me-2"></i>Conflict detection</li>
                            <li><i class="fas fa-check text-success me-2"></i>Calendar integration</li>
                        </ul>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="feature-card card h-100">
                    <div class="card-body text-center p-4">
                        <i class="fas fa-mobile-alt feature-icon"></i>
                        <h3 class="h4 mb-3">Mobile Access</h3>
                        <p class="text-muted">Access attendance system from any device, anywhere</p>
                        <ul class="list-unstyled text-start">
                            <li><i class="fas fa-check text-success me-2"></i>Responsive design</li>
                            <li><i class="fas fa-check text-success me-2"></i>Cross-platform support</li>
                            <li><i class="fas fa-check text-success me-2"></i>Offline capabilities</li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <section class="stats-section">
        <div class="container">
            <div class="row">
                <div class="col-md-4">
                    <div class="stat-card">
                        <div class="stat-number">1000+</div>
                        <div class="stat-label">Active Students</div>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="stat-card">
                        <div class="stat-number">50+</div>
                        <div class="stat-label">Courses</div>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="stat-card">
                        <div class="stat-number">95%</div>
                        <div class="stat-label">Accuracy Rate</div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <footer class="bg-dark text-light py-4 mt-5">
        <div class="container">
            <div class="row">
                <div class="col-md-6 text-center text-md-start">
                    <h5><i class="fas fa-chalkboard-teacher me-2"></i>Attendify</h5>
                    <p class="mb-0">Making attendance management smarter</p>
                </div>
                <div class="col-md-6 text-center text-md-end">
                    <p class="mb-0">&copy; 2025 Attendify. All rights reserved.</p>
                </div>
            </div>
        </div>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>