<%@ page contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Register - Attendify</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        body {
            background: linear-gradient(135deg, #0072ff, #00c6ff);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .card {
            border: none;
            border-radius: 15px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
            max-width: 500px;
            width: 100%;
            padding: 2rem;
        }
        .form-control, .form-select {
            border-radius: 8px;
            padding: 10px 15px;
            margin-bottom: 15px;
        }
        .btn-primary {
            border-radius: 8px;
            padding: 12px;
            width: 100%;
            font-weight: 600;
            background-color: #0072ff;
            border: none;
        }
        .btn-primary:hover {
            background-color: #005ad6;
        }
        .user-type-toggle {
            display: flex;
            margin-bottom: 20px;
            gap: 10px;
        }
        .user-type-toggle .btn {
            flex: 1;
            padding: 10px;
            border-radius: 8px;
        }
        .user-type-toggle .btn.active {
            background-color: #0072ff;
            color: white;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="card">
            <h2 class="text-center mb-4">Create an Account</h2>
            
            <% if (request.getParameter("error") != null) { %>
                <div class="alert alert-danger alert-dismissible fade show" role="alert">
                    <%= request.getParameter("error") %>
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            <% } %>

            <form action="process-registration.jsp" method="post">
                <div class="user-type-toggle mb-4">
                    <button type="button" class="btn btn-outline-primary active" onclick="toggleUserType('student', this)">Student</button>
                    <button type="button" class="btn btn-outline-primary" onclick="toggleUserType('lecturer', this)">Lecturer</button>
                </div>
                <input type="hidden" name="userType" id="userType" value="student">

                <div class="mb-3">
                    <input type="text" class="form-control" name="fullName" placeholder="Full Name" required>
                </div>

                <div class="mb-3">
                    <input type="email" class="form-control" name="email" placeholder="Email" required>
                </div>

                <div class="mb-3" id="idField">
                    <input type="text" class="form-control" name="userId" placeholder="Student ID" required
                           pattern="[A-Za-z0-9]+" title="ID should only contain letters and numbers">
                </div>

                <div class="mb-3">
                    <input type="password" class="form-control" name="password" placeholder="Password" required>
                </div>

                <button type="submit" class="btn btn-primary">
                    <i class="fas fa-user-plus me-2"></i>Register
                </button>

                <div class="text-center mt-3">
                    Already have an account? <a href="login.jsp">Login here</a>
                </div>
            </form>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function toggleUserType(type, button) {
            // Update hidden input
            document.getElementById('userType').value = type;
            
            // Update buttons
            const buttons = document.querySelectorAll('.user-type-toggle .btn');
            buttons.forEach(btn => btn.classList.remove('active'));
            button.classList.add('active');
            
            // Update ID field placeholder
            const idField = document.getElementById('idField').querySelector('input');
            idField.placeholder = type === 'lecturer' ? 'Lecturer ID' : 'Student ID';
        }
    </script>
</body>
</html>