<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%!
    private String escapeHtml(Object value) {
        if (value == null) {
            return "";
        }

        return value.toString()
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }
%>

<%
    String contextPath = request.getContextPath();

    String errorMessage =
            request.getAttribute("errorMessage") != null
                    ? request.getAttribute("errorMessage").toString()
                    : "";

    String email =
            request.getAttribute("email") != null
                    ? request.getAttribute("email").toString()
                    : "";

    boolean registrationSuccess =
            "true".equals(request.getParameter("registered"));

    boolean logoutSuccess =
            "true".equals(request.getParameter("logout"));
%>

<!DOCTYPE html>

<html lang="en">

<head>

    <meta charset="UTF-8">

    <meta name="viewport"
          content="width=device-width, initial-scale=1.0">

    <title>
        Login | Classora | Learn. Connect. Grow.
    </title>

    <meta name="description"
          content="Log in to your Classora account.">


    <!-- Google Fonts -->

    <link rel="preconnect"
          href="https://fonts.googleapis.com">

    <link rel="preconnect"
          href="https://fonts.gstatic.com"
          crossorigin>

    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Inter:wght@400;500;600&display=swap"
          rel="stylesheet">


    <!-- Font Awesome -->

    <link rel="stylesheet"
          href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">


    <!-- Project CSS -->

    <link rel="stylesheet"
          href="<%= contextPath %>/css/style.css">

    <link rel="stylesheet"
          href="<%= contextPath %>/css/login.css">

</head>


<body class="auth-body">


<!-- ========================================
     BACK BUTTON
     ======================================== -->

<a href="<%= contextPath %>/index.jsp"
   class="auth-back">

    <i class="fa-solid fa-arrow-left"></i>

    <span>
        Back to home
    </span>

</a>



<div class="auth-shell">


    <!-- ========================================
         LEFT VISUAL SIDE
         ======================================== -->

    <section class="auth-visual">


        <div class="auth-glow auth-glow--violet"></div>

        <div class="auth-glow auth-glow--blue"></div>

        <div class="auth-glow auth-glow--cyan"></div>

        <div class="auth-grid"></div>


        <div class="auth-visual-content">


            <!-- Logo -->

            <div class="auth-logo">

                <div class="logo-mark">
                    C
                </div>

                <div class="logo-text">

                    <span class="logo-title">
                        Classora
                    </span>

                    <span class="logo-sub">
                        Learn. Connect. Grow.
                    </span>

                </div>

            </div>


            <!-- Heading -->

            <div class="auth-hero">

                <h2 class="auth-visual-heading">

                    Your tuition world,<br>

                    connected in

                    <span class="text-gradient">
                        one place.
                    </span>

                </h2>


                <p class="auth-visual-text">

                    Classes, attendance, payments,
                    examinations and communication —
                    all connected through one secure platform.

                </p>

            </div>


            <!-- Stats -->

            <div class="auth-stat-row">


                <div class="auth-stat">

                    <div class="auth-stat-icon">

                        <i class="fa-solid fa-users"></i>

                    </div>

                    <div>

                        <span class="auth-stat-value">
                            Students
                        </span>

                        <span class="auth-stat-label">
                            Classes & results
                        </span>

                    </div>

                </div>


                <div class="auth-stat">

                    <div class="auth-stat-icon">

                        <i class="fa-solid fa-chalkboard-user"></i>

                    </div>

                    <div>

                        <span class="auth-stat-value">
                            Tutors
                        </span>

                        <span class="auth-stat-label">
                            Attendance & materials
                        </span>

                    </div>

                </div>


                <div class="auth-stat">

                    <div class="auth-stat-icon">

                        <i class="fa-solid fa-user-shield"></i>

                    </div>

                    <div>

                        <span class="auth-stat-value">
                            Admin
                        </span>

                        <span class="auth-stat-label">
                            Secure workspace
                        </span>

                    </div>

                </div>


            </div>


            <!-- Security card -->

            <div class="auth-security-card">

                <div class="auth-security-icon">

                    <i class="fa-solid fa-shield-halved"></i>

                </div>

                <div>

                    <span class="auth-security-title">
                        Secure role-based access
                    </span>

                    <span class="auth-security-text">
                        Your account automatically opens the dashboard
                        assigned to your role.
                    </span>

                </div>

            </div>


        </div>

    </section>



    <!-- ========================================
         RIGHT FORM SIDE
         ======================================== -->

    <section class="auth-form-side">


        <div class="auth-form-wrap">


            <!-- Header -->

            <div class="auth-form-header">

                <span class="auth-eyebrow">
                    CLASSORA ACCOUNT
                </span>

                <h1>
                    Welcome back
                </h1>

                <p>
                    Log in to continue your Classora experience.
                </p>

            </div>



            <!-- ========================================
                 SUCCESS MESSAGES
                 ======================================== -->

            <%
                if (registrationSuccess) {
            %>

            <div class="auth-message auth-message-success">

                <i class="fa-solid fa-circle-check"></i>

                <span>
                    Registration successful. You can now log in.
                </span>

            </div>

            <%
                }
            %>


            <%
                if (logoutSuccess) {
            %>

            <div class="auth-message auth-message-success">

                <i class="fa-solid fa-circle-check"></i>

                <span>
                    You have successfully logged out.
                </span>

            </div>

            <%
                }
            %>



            <!-- ========================================
                 LOGIN ERROR
                 ======================================== -->

            <%
                if (!errorMessage.isEmpty()) {
            %>

            <div class="auth-message auth-message-error">

                <i class="fa-solid fa-circle-exclamation"></i>

                <span>
                    <%= escapeHtml(errorMessage) %>
                </span>

            </div>

            <%
                }
            %>



            <!-- ========================================
                 LOGIN FORM
                 ======================================== -->

            <form id="loginForm"
                  class="auth-form"
                  action="<%= contextPath %>/login"
                  method="post"
                  novalidate>


                <!-- Email -->

                <div class="form-field">

                    <label for="email">
                        Email address
                    </label>


                    <div class="input-wrap">

                        <i class="fa-regular fa-envelope input-icon"></i>

                        <input type="email"
                               id="email"
                               name="email"
                               placeholder="you@example.com"
                               autocomplete="email"
                               maxlength="150"
                               value="<%= escapeHtml(email) %>"
                               required>

                    </div>

                    <span class="field-error"
                          id="emailError">
                    </span>

                </div>



                <!-- Password -->

                <div class="form-field">

                    <label for="password">
                        Password
                    </label>


                    <div class="input-wrap">

                        <i class="fa-solid fa-lock input-icon"></i>

                        <input type="password"
                               id="password"
                               name="password"
                               placeholder="Enter your password"
                               autocomplete="current-password"
                               required>


                        <button type="button"
                                class="toggle-password"
                                id="togglePassword"
                                aria-label="Show password">

                            <i class="fa-regular fa-eye"></i>

                        </button>

                    </div>

                    <span class="field-error"
                          id="passwordError">
                    </span>

                </div>



                <!-- Remember + Forgot -->

                <div class="form-row">

                    <label class="checkbox-wrap">

                        <input type="checkbox"
                               id="remember"
                               name="remember">

                        <span class="checkbox-box"></span>

                        <span>
                            Remember me
                        </span>

                    </label>


                    <a href="#"
                       class="auth-link-muted">

                        Forgot password?

                    </a>

                </div>



                <!-- Submit -->

                <button type="submit"
                        class="btn-primary auth-submit"
                        id="submitBtn">

                    <span class="btn-submit-text">
                        Log in
                    </span>

                    <i class="fa-solid fa-arrow-right"></i>

                </button>


            </form>



            <!-- ========================================
                 REGISTER OPTIONS
                 ======================================== -->

            <div class="register-options">


                <div class="register-divider">

                    <span>
                        New to Classora?
                    </span>

                </div>


                <div class="register-options-grid">


                    <!-- Student -->

                    <a href="<%= contextPath %>/register.jsp"
                       class="register-option">

                        <div class="register-option-icon">

                            <i class="fa-solid fa-user-graduate"></i>

                        </div>


                        <div class="register-option-content">

                            <span class="register-option-title">
                                Student
                            </span>

                            <span class="register-option-text">
                                Create student account
                            </span>

                        </div>


                        <i class="fa-solid fa-arrow-right
                                  register-option-arrow">
                        </i>

                    </a>



                    <!-- Parent -->

                    <a href="<%= contextPath %>/register-parent"
                       class="register-option">

                        <div class="register-option-icon">

                            <i class="fa-solid fa-people-roof"></i>

                        </div>


                        <div class="register-option-content">

                            <span class="register-option-title">
                                Parent
                            </span>

                            <span class="register-option-text">
                                Register with your child
                            </span>

                        </div>


                        <i class="fa-solid fa-arrow-right
                                  register-option-arrow">
                        </i>

                    </a>


                </div>


                <p class="register-note">

                    Tutor and Admin accounts are
                    created by an administrator.

                </p>


            </div>


        </div>

    </section>


</div>



<!-- JavaScript -->

<script src="<%= contextPath %>/js/login.js"></script>


</body>

</html>