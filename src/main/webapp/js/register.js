document.addEventListener("DOMContentLoaded", function () {

    // =====================================================
    // ELEMENTS
    // =====================================================

    const form = document.getElementById("registerForm");

    const firstName = document.getElementById("firstName");
    const lastName = document.getElementById("lastName");
    const email = document.getElementById("email");
    const phone = document.getElementById("phone");

    const password = document.getElementById("password");
    const confirmPassword = document.getElementById("confirmPassword");

    const terms = document.getElementById("terms");

    const nextButtons = document.querySelectorAll(".reg-next");
    const backButtons = document.querySelectorAll(".reg-back");

    const panels = document.querySelectorAll(".reg-panel");
    const steps = document.querySelectorAll(".reg-step");

    const togglePasswordButtons =
        document.querySelectorAll(".toggle-password");

    const passwordStrength =
        document.getElementById("pwStrength");


    // =====================================================
    // ERROR FUNCTIONS
    // =====================================================

    function showError(input, message) {

        if (!input) {
            return;
        }

        const errorElement =
            document.getElementById(
                input.id + "Error"
            );

        if (errorElement) {
            errorElement.textContent = message;
        }

        const field =
            input.closest(".form-field");

        if (field) {
            field.classList.add("has-error");
        }
    }


    function clearError(input) {

        if (!input) {
            return;
        }

        const errorElement =
            document.getElementById(
                input.id + "Error"
            );

        if (errorElement) {
            errorElement.textContent = "";
        }

        const field =
            input.closest(".form-field");

        if (field) {
            field.classList.remove("has-error");
        }
    }


    // =====================================================
    // EMAIL VALIDATION
    // =====================================================

    function isValidEmail(emailValue) {

        const emailPattern =
            /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

        return emailPattern.test(
            emailValue
        );
    }


    // =====================================================
    // PHONE VALIDATION
    // =====================================================

    function isValidPhone(phoneValue) {

        /*
         * Phone is optional.
         * If empty, it is valid.
         */

        if (phoneValue.trim() === "") {
            return true;
        }

        /*
         * Sri Lankan mobile format:
         * 07XXXXXXXX
         */

        const cleanedPhone =
            phoneValue.replace(
                /[\s-]/g,
                ""
            );

        const phonePattern =
            /^0[0-9]{9}$/;

        return phonePattern.test(
            cleanedPhone
        );
    }


    // =====================================================
    // STEP 1 VALIDATION
    // =====================================================

    function validateStep1() {

        let valid = true;


        // -------------------------------
        // First Name
        // -------------------------------

        clearError(firstName);

        if (
            !firstName ||
            firstName.value.trim() === ""
        ) {

            showError(
                firstName,
                "First name is required."
            );

            valid = false;
        }


        // -------------------------------
        // Last Name
        // -------------------------------

        clearError(lastName);

        if (
            !lastName ||
            lastName.value.trim() === ""
        ) {

            showError(
                lastName,
                "Last name is required."
            );

            valid = false;
        }


        // -------------------------------
        // Email
        // -------------------------------

        clearError(email);

        if (
            !email ||
            email.value.trim() === ""
        ) {

            showError(
                email,
                "Email address is required."
            );

            valid = false;

        } else if (
            !isValidEmail(
                email.value.trim()
            )
        ) {

            showError(
                email,
                "Please enter a valid email address."
            );

            valid = false;
        }


        // -------------------------------
        // Phone
        // -------------------------------

        clearError(phone);

        if (
            phone &&
            !isValidPhone(phone.value)
        ) {

            showError(
                phone,
                "Please enter a valid phone number."
            );

            valid = false;
        }


        return valid;
    }


    // =====================================================
    // STEP 2 VALIDATION
    // =====================================================

    function validateStep2() {

        let valid = true;


        // -------------------------------
        // Password
        // -------------------------------

        clearError(password);

        if (
            !password ||
            password.value === ""
        ) {

            showError(
                password,
                "Password is required."
            );

            valid = false;

        } else if (
            password.value.length < 8
        ) {

            showError(
                password,
                "Password must contain at least 8 characters."
            );

            valid = false;
        }


        // -------------------------------
        // Confirm Password
        // -------------------------------

        clearError(confirmPassword);

        if (
            !confirmPassword ||
            confirmPassword.value === ""
        ) {

            showError(
                confirmPassword,
                "Please confirm your password."
            );

            valid = false;

        } else if (
            password &&
            confirmPassword.value !==
            password.value
        ) {

            showError(
                confirmPassword,
                "Passwords do not match."
            );

            valid = false;
        }


        // -------------------------------
        // Terms
        // -------------------------------

        const termsError =
            document.getElementById(
                "termsError"
            );

        if (termsError) {
            termsError.textContent = "";
        }


        if (
            !terms ||
            !terms.checked
        ) {

            if (termsError) {

                termsError.textContent =
                    "You must agree to the Terms of Service.";
            }

            valid = false;
        }


        return valid;
    }


    // =====================================================
    // CHANGE STEP
    // =====================================================

    function showStep(stepNumber) {

        panels.forEach(
            function (panel) {

                panel.classList.remove(
                    "is-active"
                );

                if (
                    Number(
                        panel.dataset.panel
                    ) === stepNumber
                ) {

                    panel.classList.add(
                        "is-active"
                    );
                }
            }
        );


        steps.forEach(
            function (step) {

                step.classList.remove(
                    "is-active"
                );

                step.classList.remove(
                    "is-complete"
                );


                const currentStep =
                    Number(
                        step.dataset.step
                    );


                if (
                    currentStep ===
                    stepNumber
                ) {

                    step.classList.add(
                        "is-active"
                    );

                } else if (
                    currentStep <
                    stepNumber
                ) {

                    step.classList.add(
                        "is-complete"
                    );
                }
            }
        );


        /*
         * Scroll the form area to the top.
         */

        const formSide =
            document.querySelector(
                ".auth-form-side"
            );

        if (formSide) {

            formSide.scrollTo({
                top: 0,
                behavior: "smooth"
            });
        }
    }


    // =====================================================
    // NEXT BUTTON
    // =====================================================

    nextButtons.forEach(
        function (button) {

            button.addEventListener(
                "click",
                function () {

                    if (
                        validateStep1()
                    ) {

                        const nextStep =
                            Number(
                                button.dataset.next
                            );

                        showStep(
                            nextStep
                        );
                    }
                }
            );
        }
    );


    // =====================================================
    // BACK BUTTON
    // =====================================================

    backButtons.forEach(
        function (button) {

            button.addEventListener(
                "click",
                function () {

                    const previousStep =
                        Number(
                            button.dataset.back
                        );

                    showStep(
                        previousStep
                    );
                }
            );
        }
    );


    // =====================================================
    // LIVE ERROR CLEARING
    // =====================================================

    if (firstName) {

        firstName.addEventListener(
            "input",
            function () {
                clearError(firstName);
            }
        );
    }


    if (lastName) {

        lastName.addEventListener(
            "input",
            function () {
                clearError(lastName);
            }
        );
    }


    if (email) {

        email.addEventListener(
            "input",
            function () {
                clearError(email);
            }
        );
    }


    if (phone) {

        phone.addEventListener(
            "input",
            function () {
                clearError(phone);
            }
        );
    }


    if (password) {

        password.addEventListener(
            "input",
            function () {

                clearError(password);

                updatePasswordStrength(
                    password.value
                );
            }
        );
    }


    if (confirmPassword) {

        confirmPassword.addEventListener(
            "input",
            function () {
                clearError(
                    confirmPassword
                );
            }
        );
    }


    if (terms) {

        terms.addEventListener(
            "change",
            function () {

                const termsError =
                    document.getElementById(
                        "termsError"
                    );

                if (
                    termsError &&
                    terms.checked
                ) {

                    termsError.textContent =
                        "";
                }
            }
        );
    }


    // =====================================================
    // PASSWORD SHOW / HIDE
    // =====================================================

    togglePasswordButtons.forEach(
        function (button) {

            button.addEventListener(
                "click",
                function () {

                    const targetId =
                        button.getAttribute(
                            "data-toggle-target"
                        );

                    const targetInput =
                        document.getElementById(
                            targetId
                        );

                    if (!targetInput) {
                        return;
                    }


                    const icon =
                        button.querySelector("i");


                    if (
                        targetInput.type ===
                        "password"
                    ) {

                        targetInput.type =
                            "text";

                        if (icon) {

                            icon.classList.remove(
                                "fa-eye"
                            );

                            icon.classList.add(
                                "fa-eye-slash"
                            );
                        }

                        button.setAttribute(
                            "aria-label",
                            "Hide password"
                        );

                    } else {

                        targetInput.type =
                            "password";

                        if (icon) {

                            icon.classList.remove(
                                "fa-eye-slash"
                            );

                            icon.classList.add(
                                "fa-eye"
                            );
                        }

                        button.setAttribute(
                            "aria-label",
                            "Show password"
                        );
                    }
                }
            );
        }
    );


    // =====================================================
    // PASSWORD STRENGTH
    // =====================================================

    function updatePasswordStrength(
        passwordValue
    ) {

        if (!passwordStrength) {
            return;
        }


        const bars =
            passwordStrength.querySelectorAll(
                ".pw-strength-bar"
            );


        let strength = 0;


        if (
            passwordValue.length >= 8
        ) {
            strength++;
        }


        if (
            /[A-Z]/.test(
                passwordValue
            ) &&
            /[a-z]/.test(
                passwordValue
            )
        ) {
            strength++;
        }


        if (
            /\d/.test(
                passwordValue
            ) ||
            /[^A-Za-z0-9]/.test(
                passwordValue
            )
        ) {
            strength++;
        }


        bars.forEach(
            function (bar, index) {

                bar.classList.remove(
                    "is-active"
                );

                if (
                    index < strength
                ) {

                    bar.classList.add(
                        "is-active"
                    );
                }
            }
        );
    }


    // =====================================================
    // FINAL FORM SUBMISSION
    // =====================================================

    if (form) {

        form.addEventListener(
            "submit",
            function (event) {

                /*
                 * Validate both steps again before
                 * sending data to RegisterServlet.
                 */

                const step1Valid =
                    validateStep1();

                const step2Valid =
                    validateStep2();


                if (!step1Valid) {

                    event.preventDefault();

                    showStep(1);

                    return;
                }


                if (!step2Valid) {

                    event.preventDefault();

                    showStep(2);

                    return;
                }


                /*
                 * IMPORTANT:
                 *
                 * Do NOT call preventDefault() here.
                 *
                 * If everything is valid,
                 * the browser will submit normally:
                 *
                 * POST /register
                 *
                 * to RegisterServlet.
                 */


                const submitButton =
                    document.getElementById(
                        "submitBtn"
                    );


                if (submitButton) {

                    submitButton.disabled =
                        true;


                    const buttonText =
                        submitButton.querySelector(
                            ".btn-submit-text"
                        );


                    if (buttonText) {

                        buttonText.textContent =
                            "Creating account...";
                    }
                }
            }
        );
    }

});