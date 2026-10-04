<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%!
    // Simple HTML escaping for values printed inside the page
    private String escapeHtml(Object value) {

        if (value == null) {
            return "";
        }

        String text = value.toString();

        return text
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

    String firstName =
            request.getAttribute("firstName") != null
                    ? request.getAttribute("firstName").toString()
                    : "";

    String lastName =
            request.getAttribute("lastName") != null
                    ? request.getAttribute("lastName").toString()
                    : "";

    String email =
            request.getAttribute("email") != null
                    ? request.getAttribute("email").toString()
                    : "";

    String phone =
            request.getAttribute("phone") != null
                    ? request.getAttribute("phone").toString()
                    : "";
%>

<!DOCTYPE html>
<html lang="en">

<head>

    <meta charset="UTF-8">

    <meta name="viewport"
          content="width=device-width, initial-scale=1.0">

    <title>
        Student Registration | Classora | Learn. Connect. Grow.
    </title>

    <meta name="description"
          content="Create your Classora student account to view classes, attendance, payments and exam results.">


    <!-- Fonts -->

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


    <!-- CSS -->

    <link rel="stylesheet"
          href="<%= contextPath %>/css/style.css">

    <link rel="stylesheet"
          href="<%= contextPath %>/css/login.css">

    <link rel="stylesheet"
          href="<%= contextPath %>/css/register.css">

</head>


<body class="auth-body">


<!-- Back to home -->

<a href="<%= contextPath %>/index.jsp"
   class="auth-back">

    <i class="fa-solid fa-arrow-left"></i>

    Back to home

</a>



<div class="auth-shell auth-shell--register">


    <!-- ================================== -->
    <!-- LEFT SIDE -->
    <!-- ================================== -->

    <div class="auth-visual">


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

            <h2 class="auth-visual-heading">

                Everything about your<br>

                classes,

                <span class="text-gradient">
                    in one place.
                </span>

            </h2>



            <p class="auth-visual-text">

                Check your schedule, attendance and payment status
                without messaging your tutor every time.

            </p>



            <!-- Features -->

            <ul class="auth-feature-list">


                <li>

                    <span class="auth-feature-icon">

                        <i class="fa-regular fa-calendar"></i>

                    </span>

                    <div>

                        <span class="auth-feature-title">
                            Class schedule
                        </span>

                        <span class="auth-feature-text">
                            See every class and timing at a glance
                        </span>

                    </div>

                </li>



                <li>

                    <span class="auth-feature-icon">

                        <i class="fa-regular fa-square-check"></i>

                    </span>

                    <div>

                        <span class="auth-feature-title">
                            Attendance
                        </span>

                        <span class="auth-feature-text">
                            Track your attendance percentage
                        </span>

                    </div>

                </li>



                <li>

                    <span class="auth-feature-icon">

                        <i class="fa-solid fa-wallet"></i>

                    </span>

                    <div>

                        <span class="auth-feature-title">
                            Payment status
                        </span>

                        <span class="auth-feature-text">
                            Know exactly what's paid and what's due
                        </span>

                    </div>

                </li>



                <li>

                    <span class="auth-feature-icon">

                        <i class="fa-regular fa-bell"></i>

                    </span>

                    <div>

                        <span class="auth-feature-title">
                            Notices & Results
                        </span>

                        <span class="auth-feature-text">
                            Get exam results and reminders
                        </span>

                    </div>

                </li>


            </ul>


        </div>


    </div>



    <!-- ================================== -->
    <!-- RIGHT SIDE -->
    <!-- ================================== -->

    <div class="auth-form-side">


        <div class="auth-form-wrap auth-form-wrap--wide">


            <!-- Header -->

            <div class="auth-form-header">

                <h1>
                    Create your Classora account
                </h1>

                <p>
                    Join Classora and keep your classes, progress and updates close.
                </p>

            </div>



            <!-- ================================== -->
            <!-- SERVER ERROR -->
            <!-- ================================== -->

            <%
                if (!errorMessage.isEmpty()) {
            %>

            <div class="auth-error-message">

                <i class="fa-solid fa-circle-exclamation"></i>

                <%= escapeHtml(errorMessage) %>

            </div>

            <%
                }
            %>



            <!-- ================================== -->
            <!-- STEPS -->
            <!-- ================================== -->

            <div class="reg-steps"
                 id="regSteps">


                <div class="reg-step is-active"
                     data-step="1">

                    <span class="reg-step-dot">
                        1
                    </span>

                    <span class="reg-step-label">
                        Your details
                    </span>

                </div>


                <div class="reg-step-line"></div>


                <div class="reg-step"
                     data-step="2">

                    <span class="reg-step-dot">
                        2
                    </span>

                    <span class="reg-step-label">
                        Account security
                    </span>

                </div>


            </div>



            <!-- ================================== -->
            <!-- FORM -->
            <!-- ================================== -->

            <form id="registerForm"
                  class="auth-form"
                  action="<%= contextPath %>/register"
                  method="post"
                  novalidate>


                <!-- Role is forced to STUDENT in RegisterServlet. -->


                <!-- ================================= -->
                <!-- STEP 1 -->
                <!-- ================================= -->

                <div class="reg-panel is-active"
                     data-panel="1">


                    <div class="form-grid-2">


                        <!-- First Name -->

                        <div class="form-field">


                            <label for="firstName">
                                First name
                            </label>


                            <div class="input-wrap">


                                <i class="fa-regular fa-user input-icon"></i>


                                <input type="text"
                                       id="firstName"
                                       name="firstName"
                                       placeholder="Kasun"
                                       autocomplete="given-name"
                                       maxlength="100"
                                       value="<%= escapeHtml(firstName) %>"
                                       required>


                            </div>


                            <span class="field-error"
                                  id="firstNameError">
                            </span>


                        </div>



                        <!-- Last Name -->

                        <div class="form-field">


                            <label for="lastName">
                                Last name
                            </label>


                            <div class="input-wrap">


                                <i class="fa-regular fa-user input-icon"></i>


                                <input type="text"
                                       id="lastName"
                                       name="lastName"
                                       placeholder="Perera"
                                       autocomplete="family-name"
                                       maxlength="100"
                                       value="<%= escapeHtml(lastName) %>"
                                       required>


                            </div>


                            <span class="field-error"
                                  id="lastNameError">
                            </span>


                        </div>


                    </div>



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



                    <!-- Phone -->

                    <div class="form-field">


                        <label for="phone">

                            Phone number

                            <span class="field-optional">
                                (optional)
                            </span>

                        </label>


                        <div class="input-wrap">


                            <i class="fa-solid fa-phone input-icon"></i>


                            <input type="tel"
                                   id="phone"
                                   name="phone"
                                   placeholder="07X XXX XXXX"
                                   autocomplete="tel"
                                   maxlength="20"
                                   value="<%= escapeHtml(phone) %>">


                        </div>


                        <span class="field-error"
                              id="phoneError">
                        </span>


                    </div>


                </div>



                <!-- ================================= -->
                <!-- STEP 2 -->
                <!-- ================================= -->

                <div class="reg-panel is-active"
                     data-panel="2">


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
                                   placeholder="Create a password"
                                   autocomplete="new-password"
                                   minlength="8"
                                   required>


                            <button type="button"
                                    class="toggle-password"
                                    data-toggle-target="password"
                                    aria-label="Show password">


                                <i class="fa-regular fa-eye"></i>


                            </button>


                        </div>



                        <div class="pw-strength"
                             id="pwStrength">

                            <span class="pw-strength-bar"></span>

                            <span class="pw-strength-bar"></span>

                            <span class="pw-strength-bar"></span>

                        </div>



                        <span class="field-hint">

                            Use at least 8 characters.

                        </span>



                        <span class="field-error"
                              id="passwordError">
                        </span>


                    </div>



                    <!-- Confirm Password -->

                    <div class="form-field">


                        <label for="confirmPassword">
                            Confirm password
                        </label>


                        <div class="input-wrap">


                            <i class="fa-solid fa-lock input-icon"></i>


                            <input type="password"
                                   id="confirmPassword"
                                   name="confirmPassword"
                                   placeholder="Re-enter your password"
                                   autocomplete="new-password"
                                   minlength="8"
                                   required>


                            <button type="button"
                                    class="toggle-password"
                                    data-toggle-target="confirmPassword"
                                    aria-label="Show password">


                                <i class="fa-regular fa-eye"></i>


                            </button>


                        </div>


                        <span class="field-error"
                              id="confirmPasswordError">
                        </span>


                    </div>



                    <!-- Terms -->

                    <label class="checkbox-wrap reg-terms">


                        <input type="checkbox"
                               id="terms"
                               name="terms"
                               required>


                        <span class="checkbox-box"></span>


                        I agree to the

                        <a href="#">
                            Terms of Service
                        </a>

                        and

                        <a href="#">
                            Privacy Policy
                        </a>


                    </label>

                    <span class="field-error"
                          id="termsError">
                    </span>



                    <!-- Actions -->

                    <div class="reg-actions">


                        <button type="button"
                                class="btn-ghost reg-back"
                                data-back="1">


                            <i class="fa-solid fa-arrow-left"></i>

                            Back


                        </button>



                        <button type="submit"
                                class="btn-primary auth-submit"
                                id="submitBtn">


                            <span class="btn-submit-text">
                                Create account
                            </span>


                            <i class="fa-solid fa-arrow-right"></i>


                        </button>


                    </div>


                </div>


            </form>



            <!-- Login -->

            <p class="auth-switch">

                Already have an account?

                <a href="<%= contextPath %>/login.jsp">
                    Log in
                </a>

            </p>

            <p class="auth-switch-alt">
                Are you a parent?
                <a href="<%= contextPath %>/register-parent">
                    Create a parent account
                </a>
            </p>


        </div>


    </div>


</div>



<div class="toast"
     id="toast">
</div>



<script src="<%= contextPath %>/js/register.js"></script>


</body>

</html>