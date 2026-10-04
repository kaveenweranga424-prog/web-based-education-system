document.addEventListener("DOMContentLoaded", function () {
    const form = document.getElementById("parentRegisterForm");
    const firstName = document.getElementById("firstName");
    const lastName = document.getElementById("lastName");
    const email = document.getElementById("email");
    const phone = document.getElementById("phone");
    const childEmail = document.getElementById("childEmail");
    const relationship = document.getElementById("relationship");
    const password = document.getElementById("password");
    const confirmPassword = document.getElementById("confirmPassword");
    const terms = document.getElementById("terms");
    const panels = document.querySelectorAll(".reg-panel");
    const steps = document.querySelectorAll(".reg-step");
    const nextButtons = document.querySelectorAll(".reg-next");
    const backButtons = document.querySelectorAll(".reg-back");
    const togglePasswordButtons = document.querySelectorAll(".toggle-password");
    const strengthBox = document.getElementById("pwStrength");

    function showError(input, message) {
        if (!input) return;
        const error = document.getElementById(input.id + "Error");
        if (error) error.textContent = message;
        const field = input.closest(".form-field");
        if (field) field.classList.add("has-error");
    }

    function clearError(input) {
        if (!input) return;
        const error = document.getElementById(input.id + "Error");
        if (error) error.textContent = "";
        const field = input.closest(".form-field");
        if (field) field.classList.remove("has-error");
    }

    function validEmail(value) {
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
    }

    function validPhone(value) {
        if (value.trim() === "") return true;
        return /^0[0-9]{9}$/.test(value.replace(/[\s-]/g, ""));
    }

    function validateStep1() {
        let valid = true;

        [firstName, lastName, email, phone, childEmail, relationship].forEach(clearError);

        if (!firstName.value.trim()) {
            showError(firstName, "Parent first name is required.");
            valid = false;
        }

        if (!lastName.value.trim()) {
            showError(lastName, "Parent last name is required.");
            valid = false;
        }

        if (!email.value.trim()) {
            showError(email, "Parent email is required.");
            valid = false;
        } else if (!validEmail(email.value.trim())) {
            showError(email, "Enter a valid parent email address.");
            valid = false;
        }

        if (!validPhone(phone.value)) {
            showError(phone, "Enter a valid phone number.");
            valid = false;
        }

        if (!childEmail.value.trim()) {
            showError(childEmail, "Child's student email is required.");
            valid = false;
        } else if (!validEmail(childEmail.value.trim())) {
            showError(childEmail, "Enter a valid child email address.");
            valid = false;
        } else if (email.value.trim().toLowerCase() === childEmail.value.trim().toLowerCase()) {
            showError(childEmail, "Parent and child emails cannot be the same.");
            valid = false;
        }

        if (!relationship.value) {
            showError(relationship, "Select your relationship to the student.");
            valid = false;
        }

        return valid;
    }

    function validateStep2() {
        let valid = true;
        clearError(password);
        clearError(confirmPassword);

        if (!password.value) {
            showError(password, "Password is required.");
            valid = false;
        } else if (password.value.length < 8) {
            showError(password, "Password must contain at least 8 characters.");
            valid = false;
        }

        if (!confirmPassword.value) {
            showError(confirmPassword, "Please confirm your password.");
            valid = false;
        } else if (password.value !== confirmPassword.value) {
            showError(confirmPassword, "Passwords do not match.");
            valid = false;
        }

        const termsError = document.getElementById("termsError");
        if (termsError) termsError.textContent = "";
        if (!terms.checked) {
            if (termsError) termsError.textContent = "Please confirm the parent/guardian declaration.";
            valid = false;
        }

        return valid;
    }

    function showStep(stepNumber) {
        panels.forEach(function (panel) {
            panel.classList.toggle("is-active", Number(panel.dataset.panel) === stepNumber);
        });

        steps.forEach(function (step) {
            const number = Number(step.dataset.step);
            step.classList.remove("is-active", "is-done");
            if (number === stepNumber) step.classList.add("is-active");
            if (number < stepNumber) step.classList.add("is-done");
        });
    }

    nextButtons.forEach(function (button) {
        button.addEventListener("click", function () {
            if (validateStep1()) showStep(Number(button.dataset.next));
        });
    });

    backButtons.forEach(function (button) {
        button.addEventListener("click", function () {
            showStep(Number(button.dataset.back));
        });
    });

    [firstName, lastName, email, phone, childEmail].forEach(function (input) {
        if (input) input.addEventListener("input", function () { clearError(input); });
    });

    if (relationship) relationship.addEventListener("change", function () { clearError(relationship); });
    if (confirmPassword) confirmPassword.addEventListener("input", function () { clearError(confirmPassword); });
    if (terms) terms.addEventListener("change", function () {
        if (terms.checked) {
            const termsError = document.getElementById("termsError");
            if (termsError) termsError.textContent = "";
        }
    });

    if (password) {
        password.addEventListener("input", function () {
            clearError(password);
            if (!strengthBox) return;

            let strength = 0;
            if (password.value.length >= 8) strength++;
            if (/[A-Z]/.test(password.value) && /[a-z]/.test(password.value)) strength++;
            if (/\d/.test(password.value) || /[^A-Za-z0-9]/.test(password.value)) strength++;

            strengthBox.classList.remove("weak", "medium", "strong");
            if (password.value.length > 0) {
                strengthBox.classList.add(strength <= 1 ? "weak" : strength === 2 ? "medium" : "strong");
            }
        });
    }

    togglePasswordButtons.forEach(function (button) {
        button.addEventListener("click", function () {
            const target = document.getElementById(button.dataset.toggleTarget);
            if (!target) return;
            const showing = target.type === "text";
            target.type = showing ? "password" : "text";
            const icon = button.querySelector("i");
            if (icon) {
                icon.classList.toggle("fa-eye", showing);
                icon.classList.toggle("fa-eye-slash", !showing);
            }
        });
    });

    if (form) {
        form.addEventListener("submit", function (event) {
            const step1 = validateStep1();
            const step2 = validateStep2();

            if (!step1) {
                event.preventDefault();
                showStep(1);
                return;
            }

            if (!step2) {
                event.preventDefault();
                showStep(2);
                return;
            }

            const submit = document.getElementById("submitBtn");
            if (submit) {
                submit.disabled = true;
                const text = submit.querySelector(".btn-submit-text");
                if (text) text.textContent = "Creating account...";
            }
        });
    }
});
