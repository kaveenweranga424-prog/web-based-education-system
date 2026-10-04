<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.TutorProfile" %>
<%@ page import="model.User" %>
<%@ page import="java.util.List" %>

<%
    String contextPath = request.getContextPath();

    String errorMessage =
            request.getAttribute("errorMessage") != null
                    ? request.getAttribute("errorMessage").toString()
                    : "";

    String flashSuccess = (String) session.getAttribute("flashSuccess");
    if (flashSuccess != null) {
        session.removeAttribute("flashSuccess");
    }

    List<TutorProfile> tutors =
            (List<TutorProfile>) request.getAttribute("tutors");

    List<User> unassigned =
            (List<User>) request.getAttribute("unassignedTutorUsers");

    TutorProfile editTutor =
            (TutorProfile) request.getAttribute("editTutor");
%>

<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">

    <meta name="viewport"
          content="width=device-width, initial-scale=1.0">

    <title>Manage Tutors | Classora</title>

    <!-- Google Fonts -->
    <link rel="preconnect"
          href="https://fonts.googleapis.com">

    <link rel="preconnect"
          href="https://fonts.gstatic.com"
          crossorigin>

    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Plus+Jakarta+Sans:wght@500;600;700;800&display=swap"
          rel="stylesheet">

    <!-- Font Awesome -->
    <link rel="stylesheet"
          href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

    <!-- Existing dashboard styles -->
    <link rel="stylesheet"
          href="<%= contextPath %>/css/dashboard.css">

    <link rel="stylesheet"
          href="<%= contextPath %>/css/dashboard-admin.css">

    <!-- Tutor page styles -->
    <link rel="stylesheet"
          href="<%= contextPath %>/css/manage-tutors.css">
</head>


<body class="tutor-admin-page">

<!-- =====================================================
     HEADER
===================================================== -->

<header class="tutor-topbar">

    <div class="tutor-heading">

        <a href="<%= contextPath %>/dashboard"
           class="tutor-back-btn"
           title="Back to Dashboard">

            <i class="fa-solid fa-arrow-left"></i>

        </a>


        <div>

            <span class="tutor-eyebrow">
                Tutor Management
            </span>

            <h1>
                Manage Tutors
            </h1>

            <p>
                Create tutor accounts and manage tutor profile information.
            </p>

        </div>

    </div>


    <a href="<%= contextPath %>/dashboard"
       class="tutor-dashboard-btn">

        <i class="fa-solid fa-gauge-high"></i>

        <span>
            Dashboard
        </span>

    </a>

</header>


<!-- =====================================================
     MAIN
===================================================== -->

<main class="tutor-main">


    <!-- =================================================
         ERROR MESSAGE
    ================================================= -->

    <% if (!errorMessage.isEmpty()) { %>

    <div class="tutor-alert">

        <div class="tutor-alert-icon">

            <i class="fa-solid fa-circle-exclamation"></i>

        </div>


        <div>

            <strong>
                Something went wrong
            </strong>

            <span>
                <%= errorMessage %>
            </span>

        </div>

    </div>

    <% } %>
    <% if (flashSuccess != null && !flashSuccess.isEmpty()) { %>
    <div class="tutor-alert" style="background:#ecfdf5;border:1px solid #a7f3d0;color:#065f46;padding:14px 18px;border-radius:12px;margin-bottom:24px;display:flex;align-items:center;gap:12px;">
        <i class="fa-solid fa-circle-check" style="font-size:20px;color:#10b981;flex-shrink:0;"></i>
        <div>
            <strong style="display:block;margin-bottom:2px;">Success</strong>
            <span style="font-size:13.5px;"><%= flashSuccess %></span>
        </div>
    </div>
    <% } %>


    <!-- =================================================
         CREATE TUTOR
    ================================================= -->

    <section class="tutor-card">

        <div class="tutor-card-header">

            <div>

                <span class="tutor-section-label">
                    <%= editTutor != null ? "Update Tutor" : "New Tutor" %>
                </span>

                <h2>
                    <%= editTutor != null ? "Edit Tutor Account" : "Create New Tutor Account" %>
                </h2>

                <p>
                    <%= editTutor != null ? "Update tutor profile and personal details." : "Create the login account and tutor profile in one place." %>
                </p>

            </div>


            <div class="tutor-header-icon">

                <i class="fa-solid <%= editTutor != null ? "fa-user-pen" : "fa-user-plus" %>"></i>

            </div>

        </div>


        <form action="<%= contextPath %>/admin/tutors"
              method="post"
              class="tutor-form">

            <input type="hidden"
                   name="action"
                   value="<%= editTutor != null ? "update" : "create" %>">

            <% if (editTutor != null) { %>
            <input type="hidden"
                   name="userId"
                   value="<%= editTutor.getUserId() %>">
            <% } %>


            <div class="tutor-form-grid">


                <!-- First Name -->

                <div class="tutor-field">

                    <label for="firstName">

                        <i class="fa-regular fa-user"></i>

                        First Name

                    </label>

                    <input type="text"
                           id="firstName"
                           name="firstName"
                           maxlength="100"
                           value="<%= editTutor != null && editTutor.getFirstName() != null ? editTutor.getFirstName() : "" %>"
                           placeholder="e.g. Kasun"
                           autocomplete="given-name"
                           required>

                </div>


                <!-- Last Name -->

                <div class="tutor-field">

                    <label for="lastName">

                        <i class="fa-regular fa-user"></i>

                        Last Name

                    </label>

                    <input type="text"
                           id="lastName"
                           name="lastName"
                           maxlength="100"
                           value="<%= editTutor != null && editTutor.getLastName() != null ? editTutor.getLastName() : "" %>"
                           placeholder="e.g. Perera"
                           autocomplete="family-name"
                           required>

                </div>


                <!-- Email -->

                <div class="tutor-field">

                    <label for="email">

                        <i class="fa-regular fa-envelope"></i>

                        Email Address

                    </label>

                    <input type="email"
                           id="email"
                           name="email"
                           maxlength="150"
                           value="<%= editTutor != null && editTutor.getEmail() != null ? editTutor.getEmail() : "" %>"
                           placeholder="tutor@example.com"
                           autocomplete="email"
                           required>

                </div>


                <!-- Phone -->

                <div class="tutor-field">

                    <label for="phone">

                        <i class="fa-solid fa-phone"></i>

                        Phone Number

                        <span class="tutor-optional">
                            Optional
                        </span>

                    </label>

                    <input type="tel"
                           id="phone"
                           name="phone"
                           maxlength="20"
                           value="<%= editTutor != null && editTutor.getPhone() != null ? editTutor.getPhone() : "" %>"
                           placeholder="07X XXX XXXX"
                           autocomplete="tel">

                </div>


                <!-- Temporary Password (only when creating) -->

                <% if (editTutor == null) { %>
                <div class="tutor-field">

                    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px;">
                        <label for="temporaryPassword" style="margin-bottom:0;">
                            <i class="fa-solid fa-lock"></i>
                            Temporary Password
                        </label>
                        <button type="button" onclick="generateTempPassword()" style="border:none;background:#eff6ff;color:#2563eb;font-size:12px;font-weight:600;padding:4px 8px;border-radius:6px;cursor:pointer;display:inline-flex;align-items:center;gap:4px;">
                            <i class="fa-solid fa-wand-magic-sparkles"></i> Auto Generate
                        </button>
                    </div>

                    <div style="position:relative;">
                        <input type="password"
                               id="temporaryPassword"
                               name="temporaryPassword"
                               minlength="8"
                               placeholder="Minimum 8 characters"
                               autocomplete="new-password"
                               style="padding-right:40px;"
                               required>
                        <button type="button" onclick="toggleTempPasswordVisibility()" style="position:absolute;right:10px;top:50%;transform:translateY(-50%);background:none;border:none;color:#64748b;cursor:pointer;padding:4px;">
                            <i class="fa-solid fa-eye" id="togglePassIcon"></i>
                        </button>
                    </div>

                    <% boolean isEmailActive = util.EmailService.isConfigured(); %>
                    <% if (isEmailActive) { %>
                        <span class="tutor-field-help" style="color:#047857;background:#ecfdf5;border:1px solid #a7f3d0;padding:6px 10px;border-radius:6px;margin-top:6px;display:inline-flex;align-items:center;gap:6px;font-size:12px;">
                            <i class="fa-solid fa-circle-check"></i>
                            Live SMTP Active: A welcome email with login details and this temporary password will be sent to the tutor's email address upon creation.
                        </span>
                    <% } else { %>
                        <span class="tutor-field-help" style="color:#92400e;background:#fef3c7;border:1px solid #fde68a;padding:8px 12px;border-radius:6px;margin-top:6px;display:inline-flex;align-items:flex-start;gap:8px;font-size:12px;line-height:1.4;">
                            <i class="fa-solid fa-triangle-exclamation" style="font-size:14px;margin-top:2px;flex-shrink:0;"></i>
                            <span>
                                <strong>Live Email Not Configured:</strong> SMTP credentials in <code>email.properties</code> are currently blank. When you create the tutor, credentials will be printed to the server console log for local testing. To send real emails to inboxes, add your Gmail username &amp; App Password in <code>email.properties</code>.
                            </span>
                        </span>
                    <% } %>

                </div>
                <% } %>


                <!-- Specialization -->

                <div class="tutor-field">

                    <label for="specialization">

                        <i class="fa-solid fa-graduation-cap"></i>

                        Specialization

                        <span class="tutor-optional">
                            Optional
                        </span>

                    </label>

                    <input type="text"
                           id="specialization"
                           name="specialization"
                           maxlength="150"
                           value="<%= editTutor != null && editTutor.getSpecialization() != null ? editTutor.getSpecialization() : "" %>"
                           placeholder="e.g. Mathematics">

                </div>


                <!-- Bio -->

                <div class="tutor-field tutor-full-width">

                    <label for="bio">

                        <i class="fa-solid fa-align-left"></i>

                        Bio

                        <span class="tutor-optional">
                            Optional
                        </span>

                    </label>

                    <textarea id="bio"
                              name="bio"
                              maxlength="1000"
                              rows="4"
                              placeholder="Add a short description about the tutor..."><%= editTutor != null && editTutor.getBio() != null ? editTutor.getBio() : "" %></textarea>

                    <span class="tutor-field-help">
                        Maximum 1000 characters.
                    </span>

                </div>


            </div>


            <div class="tutor-form-actions">

                <% if (editTutor != null) { %>
                <a href="<%= contextPath %>/admin/tutors"
                   class="tutor-secondary-btn">

                    <i class="fa-solid fa-xmark"></i>

                    Cancel Edit

                </a>
                <% } else { %>
                <a href="<%= contextPath %>/dashboard"
                   class="tutor-secondary-btn">

                    <i class="fa-solid fa-arrow-left"></i>

                    Back to Dashboard

                </a>
                <% } %>


                <button type="submit"
                        class="tutor-primary-btn">

                    <i class="fa-solid <%= editTutor != null ? "fa-floppy-disk" : "fa-user-plus" %>"></i>

                    <%= editTutor != null ? "Update Tutor" : "Create Tutor" %>

                </button>

            </div>

        </form>

    </section>


    <!-- =================================================
         UNASSIGNED TUTOR USERS
    ================================================= -->

    <% if (unassigned != null && !unassigned.isEmpty()) { %>

    <section class="tutor-card tutor-warning-card">

        <div class="tutor-card-header">

            <div>

                <span class="tutor-section-label warning-label">
                    Attention Required
                </span>

                <h2>
                    Tutor Accounts Missing a Profile
                </h2>

                <p>
                    These tutor user accounts exist but do not currently have a tutor profile.
                </p>

            </div>


            <div class="tutor-header-icon tutor-warning-icon">

                <i class="fa-solid fa-triangle-exclamation"></i>

            </div>

        </div>


        <div class="unassigned-list">

            <% for (User u : unassigned) { %>

            <div class="unassigned-item">

                <div class="unassigned-user-icon">

                    <i class="fa-solid fa-user"></i>

                </div>


                <div class="unassigned-user-info">

                    <strong>
                        <%= u.getFullName() %>
                    </strong>

                    <span>
                        <i class="fa-regular fa-envelope"></i>
                        <%= u.getEmail() %>
                    </span>

                </div>


                <span class="unassigned-user-id">

                    User #<%= u.getUserId() %>

                </span>

                <form action="<%= contextPath %>/admin/tutors" method="post" style="display:inline;margin-left:12px;"
                      onsubmit="return confirm('Are you sure you want to permanently delete user <%= u.getFullName() %>?');">
                    <input type="hidden" name="action" value="delete">
                    <input type="hidden" name="userId" value="<%= u.getUserId() %>">
                    <button type="submit" style="background:#fef2f2;color:#b91c1c;border:1px solid #fca5a5;padding:5px 10px;border-radius:6px;font-size:12px;font-weight:600;cursor:pointer;display:inline-flex;align-items:center;gap:4px;" title="Delete User">
                        <i class="fa-solid fa-trash-can"></i> Delete
                    </button>
                </form>

            </div>

            <% } %>

        </div>

    </section>

    <% } %>


    <!-- =================================================
         ALL TUTORS
    ================================================= -->

    <section class="tutor-card">

        <div class="tutor-card-header">

            <div>

                <span class="tutor-section-label">
                    Tutor Directory
                </span>

                <h2>
                    All Tutors
                </h2>

                <p>
                    View tutor accounts and academic profile information.
                </p>

            </div>


            <div class="tutor-count">

                <i class="fa-solid fa-chalkboard-user"></i>

                <span>

                    <%= tutors != null ? tutors.size() : 0 %>

                    Tutors

                </span>

            </div>

        </div>


        <div class="tutor-table-wrapper">

            <table class="tutor-table">

                <thead>

                <tr>

                    <th>
                        User ID
                    </th>

                    <th>
                        Tutor
                    </th>

                    <th>
                        Email
                    </th>

                    <th>
                        Specialization
                    </th>

                    <th>
                        Bio
                    </th>

                    <th>
                        Status
                    </th>

                    <th style="text-align:right;">
                        Actions
                    </th>

                </tr>

                </thead>


                <tbody>

                <%
                    if (tutors != null && !tutors.isEmpty()) {

                        for (TutorProfile t : tutors) {
                %>

                <tr>

                    <!-- User ID -->

                    <td>

                        <span class="tutor-id">

                            #<%= t.getUserId() %>

                        </span>

                    </td>


                    <!-- Name -->

                    <td>

                        <div class="tutor-name-cell">

                            <div class="tutor-avatar">

                                <i class="fa-solid fa-user"></i>

                            </div>


                            <div>

                                <span class="tutor-name">

                                    <%= t.getFullName() %>

                                </span>

                                <span class="tutor-role">

                                    Tutor

                                </span>

                            </div>

                        </div>

                    </td>


                    <!-- Email -->

                    <td>

                        <div class="tutor-email">

                            <i class="fa-regular fa-envelope"></i>

                            <span>
                                <%= t.getEmail() %>
                            </span>

                        </div>

                    </td>


                    <!-- Specialization -->

                    <td>

                        <%
                            if (t.getSpecialization() != null
                                    && !t.getSpecialization().trim().isEmpty()) {
                        %>

                        <span class="specialization-badge">

                            <i class="fa-solid fa-graduation-cap"></i>

                            <%= t.getSpecialization() %>

                        </span>

                        <% } else { %>

                        <span class="specialization-missing">

                            <i class="fa-solid fa-circle-exclamation"></i>

                            Not set

                        </span>

                        <% } %>

                    </td>


                    <!-- Bio -->

                    <td>

                        <%
                            if (t.getBio() != null
                                    && !t.getBio().trim().isEmpty()) {
                        %>

                        <span class="tutor-bio">

                            <%= t.getBio() %>

                        </span>

                        <% } else { %>

                        <span class="tutor-no-bio">

                            No bio added

                        </span>

                        <% } %>

                    </td>

                    <!-- Status -->
                    <td>
                        <% boolean isActive = "ACTIVE".equalsIgnoreCase(t.getStatus()); %>
                        <span style="display:inline-block;padding:3px 10px;border-radius:9999px;font-size:11.5px;font-weight:700;letter-spacing:0.5px;text-transform:uppercase;<%= isActive ? "background:#dcfce7;color:#15803d;" : "background:#fee2e2;color:#b91c1c;" %>">
                            <%= t.getStatus() != null ? t.getStatus() : "ACTIVE" %>
                        </span>
                    </td>

                    <!-- Actions -->
                    <td style="text-align:right;">

                        <a href="<%= contextPath %>/admin/tutors?action=edit&id=<%= t.getUserId() %>"
                           style="background:#eff6ff;color:#2563eb;border:1px solid #bfdbfe;padding:5px 10px;border-radius:6px;font-size:12px;font-weight:600;display:inline-flex;align-items:center;gap:4px;text-decoration:none;"
                           title="Edit Tutor">
                            <i class="fa-solid fa-pen"></i> Edit
                        </a>

                        <form action="<%= contextPath %>/admin/tutors" method="post" style="display:inline;"
                              onsubmit="return confirm('Are you sure you want to permanently delete tutor <%= t.getFullName() %>? Any assigned classes will become unassigned.');">
                            <input type="hidden" name="action" value="delete">
                            <input type="hidden" name="userId" value="<%= t.getUserId() %>">
                            <button type="submit" style="background:#fef2f2;color:#b91c1c;border:1px solid #fca5a5;padding:5px 10px;border-radius:6px;font-size:12px;font-weight:600;cursor:pointer;display:inline-flex;align-items:center;gap:4px;margin-left:6px;" title="Delete Tutor">
                                <i class="fa-solid fa-trash-can"></i> Delete
                            </button>
                        </form>
                    </td>

                </tr>

                <%
                    }

                } else {
                %>

                <!-- Empty State -->

                <tr>

                    <td colspan="7">

                        <div class="tutor-empty">

                            <div class="tutor-empty-icon">

                                <i class="fa-solid fa-chalkboard-user"></i>

                            </div>

                            <h3>
                                No tutors found
                            </h3>

                            <p>
                                Create your first tutor account using the form above.
                            </p>

                        </div>

                    </td>

                </tr>

                <% } %>

                </tbody>

            </table>

        </div>

    </section>


<script>
function generateTempPassword() {
    var chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!@#$%";
    var pass = "";
    for (var i = 0; i < 10; i++) {
        pass += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    var input = document.getElementById("temporaryPassword");
    if (input) {
        input.value = pass;
        input.type = "text";
        var icon = document.getElementById("togglePassIcon");
        if (icon) {
            icon.classList.remove("fa-eye");
            icon.classList.add("fa-eye-slash");
        }
    }
}
function toggleTempPasswordVisibility() {
    var input = document.getElementById("temporaryPassword");
    var icon = document.getElementById("togglePassIcon");
    if (!input) return;
    if (input.type === "password") {
        input.type = "text";
        if (icon) {
            icon.classList.remove("fa-eye");
            icon.classList.add("fa-eye-slash");
        }
    } else {
        input.type = "password";
        if (icon) {
            icon.classList.remove("fa-eye-slash");
            icon.classList.add("fa-eye");
        }
    }
}
</script>
</body>

</html>
