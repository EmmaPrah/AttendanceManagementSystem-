<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Invalidate the session
    session.invalidate();
    
    // Redirect to login page with a success message
    response.sendRedirect("login.jsp?message=" + java.net.URLEncoder.encode("You have been successfully logged out", "UTF-8"));
%>
