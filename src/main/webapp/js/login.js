document.addEventListener("DOMContentLoaded", function () {
    const form = document.getElementById("loginForm");
    const emailInput = document.getElementById("email");
    const passwordInput = document.getElementById("password");
    const emailError = document.getElementById("emailError");
    const passwordError = document.getElementById("passwordError");
    const togglePassword = document.getElementById("togglePassword");
    const submitBtn = document.getElementById("submitBtn");

    function isValidEmail(email) {
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
    }

    function showError(input, errorElement, message) {
        if (!input || !errorElement) return;
        input.classList.add("input-invalid");
        errorElement.textContent = message;
        errorElement.classList.add("visible");
    }

    function clearError(input, errorElement) {
        if (!input || !errorElement) return;
        input.classList.remove("input-invalid");
        errorElement.textContent = "";
        errorElement.classList.remove("visible");
    }

    if (togglePassword && passwordInput) {
        togglePassword.addEventListener("click", function () {
            const hidden = passwordInput.type === "password";
            passwordInput.type = hidden ? "text" : "password";
            togglePassword.innerHTML = hidden
                ? '<i class="fa-regular fa-eye-slash"></i>'
                : '<i class="fa-regular fa-eye"></i>';
            togglePassword.setAttribute("aria-label", hidden ? "Hide password" : "Show password");
        });
    }

    if (emailInput) {
        emailInput.addEventListener("input", function () {
            if (emailInput.value.trim() === "" || isValidEmail(emailInput.value.trim())) {
                clearError(emailInput, emailError);
            }
        });
    }

    if (passwordInput) {
        passwordInput.addEventListener("input", function () {
            if (passwordInput.value.length > 0) {
                clearError(passwordInput, passwordError);
            }
        });
    }

    if (form) {
        form.addEventListener("submit", function (event) {
            let valid = true;
            const email = emailInput ? emailInput.value.trim() : "";
            const password = passwordInput ? passwordInput.value : "";

            if (email === "") {
                showError(emailInput, emailError, "Enter your email address.");
                valid = false;
            } else if (!isValidEmail(email)) {
                showError(emailInput, emailError, "Enter a valid email address.");
                valid = false;
            } else {
                clearError(emailInput, emailError);
            }

            if (password === "") {
                showError(passwordInput, passwordError, "Enter your password.");
                valid = false;
            } else {
                clearError(passwordInput, passwordError);
            }

            if (!valid) {
                event.preventDefault();
                return;
            }

            // Valid form: allow the normal POST to LoginServlet.
            if (submitBtn) {
                submitBtn.disabled = true;
                const text = submitBtn.querySelector(".btn-submit-text");
                if (text) text.textContent = "Logging in...";
            }
        });
    }
});
