<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%!
    private String escapeHtml(Object value) {
        if (value == null) return "";
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
    String errorMessage = request.getAttribute("errorMessage") != null
            ? request.getAttribute("errorMessage").toString() : "";
    String firstName = request.getAttribute("firstName") != null
            ? request.getAttribute("firstName").toString() : "";
    String lastName = request.getAttribute("lastName") != null
            ? request.getAttribute("lastName").toString() : "";
    String email = request.getAttribute("email") != null
            ? request.getAttribute("email").toString() : "";
    String phone = request.getAttribute("phone") != null
            ? request.getAttribute("phone").toString() : "";
    String childEmail = request.getAttribute("childEmail") != null
            ? request.getAttribute("childEmail").toString() : "";
    String relationship = request.getAttribute("relationship") != null
            ? request.getAttribute("relationship").toString() : "";
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Parent Registration | Classora</title>
    <meta name="description" content="Create a parent account and connect it to your child's Classora student account.">

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

    <link rel="stylesheet" href="<%= contextPath %>/css/style.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/login.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/register.css">
</head>
<body class="auth-body">

<a href="<%= contextPath %>/index.jsp" class="auth-back">
    <i class="fa-solid fa-arrow-left"></i>
    Back to home
</a>

<div class="auth-shell auth-shell--register">

    <div class="auth-visual">
        <div class="auth-glow auth-glow--violet"></div>
        <div class="auth-glow auth-glow--blue"></div>
        <div class="auth-glow auth-glow--cyan"></div>
        <div class="auth-grid"></div>

        <div class="auth-visual-content">
            <div class="auth-logo">
                <div class="logo-mark">C</div>
                <div class="logo-text">
                    <span class="logo-title">Classora</span>
                    <span class="logo-sub">Learn. Connect. Grow.</span>
                </div>
            </div>

            <h2 class="auth-visual-heading">
                Stay connected to your<br>
                child's <span class="text-gradient">progress.</span>
            </h2>

            <p class="auth-visual-text">
                Create your parent account using the email address of your child's existing student account.
            </p>

            <ul class="auth-feature-list">
                <li>
                    <span class="auth-feature-icon"><i class="fa-regular fa-square-check"></i></span>
                    <div>
                        <span class="auth-feature-title">Attendance</span>
                        <span class="auth-feature-text">Follow your child's attendance records</span>
                    </div>
                </li>
                <li>
                    <span class="auth-feature-icon"><i class="fa-solid fa-wallet"></i></span>
                    <div>
                        <span class="auth-feature-title">Fees & payments</span>
                        <span class="auth-feature-text">Check outstanding fees and payment history</span>
                    </div>
                </li>
                <li>
                    <span class="auth-feature-icon"><i class="fa-solid fa-chart-line"></i></span>
                    <div>
                        <span class="auth-feature-title">Exam results</span>
                        <span class="auth-feature-text">View your child's academic results</span>
                    </div>
                </li>
                <li>
                    <span class="auth-feature-icon"><i class="fa-regular fa-bell"></i></span>
                    <div>
                        <span class="auth-feature-title">Notifications</span>
                        <span class="auth-feature-text">Receive important institute notices</span>
                    </div>
                </li>
            </ul>
        </div>
    </div>

    <div class="auth-form-side">
        <div class="auth-form-wrap auth-form-wrap--wide">

            <div class="auth-form-header">
                <h1>Create your parent account</h1>
                <p>Link your account to your child's existing student account.</p>
            </div>

            <% if (!errorMessage.isEmpty()) { %>
            <div class="auth-error-message">
                <i class="fa-solid fa-circle-exclamation"></i>
                <%= escapeHtml(errorMessage) %>
            </div>
            <% } %>

            <div class="reg-steps" id="regSteps">
                <div class="reg-step is-active" data-step="1">
                    <span class="reg-step-dot">1</span>
                    <span class="reg-step-label">Parent & child</span>
                </div>
                <div class="reg-step-line"></div>
                <div class="reg-step" data-step="2">
                    <span class="reg-step-dot">2</span>
                    <span class="reg-step-label">Account security</span>
                </div>
            </div>

            <form id="parentRegisterForm"
                  class="auth-form"
                  action="<%= contextPath %>/register-parent"
                  method="post"
                  novalidate>

                <div class="reg-panel is-active" data-panel="1">

                    <div class="form-grid-2">
                        <div class="form-field">
                            <label for="firstName">Parent first name</label>
                            <div class="input-wrap">
                                <i class="fa-regular fa-user input-icon"></i>
                                <input type="text" id="firstName" name="firstName"
                                       placeholder="Sunil" maxlength="100"
                                       value="<%= escapeHtml(firstName) %>" required>
                            </div>
                            <span class="field-error" id="firstNameError"></span>
                        </div>

                        <div class="form-field">
                            <label for="lastName">Parent last name</label>
                            <div class="input-wrap">
                                <i class="fa-regular fa-user input-icon"></i>
                                <input type="text" id="lastName" name="lastName"
                                       placeholder="Perera" maxlength="100"
                                       value="<%= escapeHtml(lastName) %>" required>
                            </div>
                            <span class="field-error" id="lastNameError"></span>
                        </div>
                    </div>

                    <div class="form-field">
                        <label for="email">Parent email address</label>
                        <div class="input-wrap">
                            <i class="fa-regular fa-envelope input-icon"></i>
                            <input type="email" id="email" name="email"
                                   placeholder="parent@example.com" maxlength="150"
                                   value="<%= escapeHtml(email) %>" required>
                        </div>
                        <span class="field-error" id="emailError"></span>
                    </div>

                    <div class="form-field">
                        <label for="phone">Parent phone number <span class="field-optional">(optional)</span></label>
                        <div class="input-wrap">
                            <i class="fa-solid fa-phone input-icon"></i>
                            <input type="tel" id="phone" name="phone"
                                   placeholder="07X XXX XXXX" maxlength="20"
                                   value="<%= escapeHtml(phone) %>">
                        </div>
                        <span class="field-error" id="phoneError"></span>
                    </div>

                    <div class="form-field">
                        <label for="childEmail">Child's student email</label>
                        <div class="input-wrap">
                            <i class="fa-solid fa-child-reaching input-icon"></i>
                            <input type="email" id="childEmail" name="childEmail"
                                   placeholder="student@example.com" maxlength="150"
                                   value="<%= escapeHtml(childEmail) %>" required>
                        </div>
                        <span class="field-error" id="childEmailError"></span>
                        <span class="field-hint">The child must already have an ACTIVE STUDENT account.</span>
                    </div>

                    <div class="form-field">
                        <label for="relationship">Relationship to student</label>
                        <div class="select-wrap">
                            <select id="relationship" name="relationship" required>
                                <option value="">Select relationship</option>
                                <option value="MOTHER" <%= "MOTHER".equalsIgnoreCase(relationship) ? "selected" : "" %>>Mother</option>
                                <option value="FATHER" <%= "FATHER".equalsIgnoreCase(relationship) ? "selected" : "" %>>Father</option>
                                <option value="GUARDIAN" <%= "GUARDIAN".equalsIgnoreCase(relationship) ? "selected" : "" %>>Guardian</option>
                            </select>
                            <i class="fa-solid fa-chevron-down select-icon"></i>
                        </div>
                        <span class="field-error" id="relationshipError"></span>
                    </div>

                    <button type="button" class="btn-primary auth-submit reg-next" data-next="2">
                        <span>Continue</span>
                        <i class="fa-solid fa-arrow-right"></i>
                    </button>
                </div>

                <div class="reg-panel" data-panel="2">

                    <div class="form-field">
                        <label for="password">Password</label>
                        <div class="input-wrap">
                            <i class="fa-solid fa-lock input-icon"></i>
                            <input type="password" id="password" name="password"
                                   placeholder="Create a password" minlength="8"
                                   autocomplete="new-password" required>
                            <button type="button" class="toggle-password"
                                    data-toggle-target="password" aria-label="Show password">
                                <i class="fa-regular fa-eye"></i>
                            </button>
                        </div>
                        <div class="pw-strength" id="pwStrength">
                            <span class="pw-strength-bar"></span>
                            <span class="pw-strength-bar"></span>
                            <span class="pw-strength-bar"></span>
                        </div>
                        <span class="field-hint">Use at least 8 characters.</span>
                        <span class="field-error" id="passwordError"></span>
                    </div>

                    <div class="form-field">
                        <label for="confirmPassword">Confirm password</label>
                        <div class="input-wrap">
                            <i class="fa-solid fa-lock input-icon"></i>
                            <input type="password" id="confirmPassword" name="confirmPassword"
                                   placeholder="Re-enter your password" minlength="8"
                                   autocomplete="new-password" required>
                            <button type="button" class="toggle-password"
                                    data-toggle-target="confirmPassword" aria-label="Show password">
                                <i class="fa-regular fa-eye"></i>
                            </button>
                        </div>
                        <span class="field-error" id="confirmPasswordError"></span>
                    </div>

                    <label class="checkbox-wrap reg-terms">
                        <input type="checkbox" id="terms" name="terms" required>
                        <span class="checkbox-box"></span>
                        I confirm that I am the parent/guardian of the student and agree to the
                        <a href="#">Terms of Service</a> and <a href="#">Privacy Policy</a>
                    </label>
                    <span class="field-error" id="termsError"></span>

                    <div class="reg-actions">
                        <button type="button" class="btn-ghost reg-back" data-back="1">
                            <i class="fa-solid fa-arrow-left"></i>
                            Back
                        </button>
                        <button type="submit" class="btn-primary auth-submit" id="submitBtn">
                            <span class="btn-submit-text">Create parent account</span>
                            <i class="fa-solid fa-arrow-right"></i>
                        </button>
                    </div>
                </div>
            </form>

            <p class="auth-switch">
                Already have an account?
                <a href="<%= contextPath %>/login.jsp">Log in</a>
            </p>

            <p class="auth-switch-alt">
                Are you a student?
                <a href="<%= contextPath %>/register.jsp">Create a student account</a>
            </p>
        </div>
    </div>
</div>

<div class="toast" id="toast"></div>
<script src="<%= contextPath %>/js/register-parent.js"></script>
</body>
</html>
