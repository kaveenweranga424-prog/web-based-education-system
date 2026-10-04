<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<% String contextPath = request.getContextPath(); %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Classora brings classes, learning, attendance, payments, results and updates together for students, parents and tutors.">
    <title>Classora | Your Tuition World, Connected</title>

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Plus+Jakarta+Sans:wght@600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/landing.css">
</head>
<body>

<header class="site-header" id="top">
    <nav class="nav-wrap container" id="landingNav">
        <a class="brand" href="#home" aria-label="Classora home">
            <span class="brand-mark"><i class="fa-solid fa-graduation-cap"></i></span>
            <span class="brand-copy">
                <strong>Classora</strong>
                <small>Learn. Connect. Grow.</small>
            </span>
        </a>

        <div class="nav-links" id="landingLinks">
            <a href="#home" class="nav-link active">Home</a>
            <a href="#experience" class="nav-link">Experience</a>
            <a href="#roles" class="nav-link">For You</a>
            <a href="#journey" class="nav-link">How It Works</a>
            <a href="#stories" class="nav-link">Stories</a>
            <div class="mobile-actions">
                <a href="<%= contextPath %>/login.jsp" class="btn btn-soft">Sign in</a>
                <a href="<%= contextPath %>/register.jsp" class="btn btn-primary">Join Classora</a>
            </div>
        </div>

        <div class="nav-actions">
            <a href="<%= contextPath %>/login.jsp" class="btn btn-ghost">Sign in</a>
            <a href="<%= contextPath %>/register.jsp" class="btn btn-primary">Join Classora</a>
        </div>

        <button class="menu-toggle" id="landingMenu" aria-label="Open navigation" aria-expanded="false">
            <span></span><span></span><span></span>
        </button>
    </nav>
</header>

<main>
    <section class="hero" id="home">
        <div class="hero-orb orb-one"></div>
        <div class="hero-orb orb-two"></div>
        <div class="container hero-grid">
            <div class="hero-copy reveal">
                <div class="eyebrow"><span></span> A smarter way to experience tuition</div>
                <h1>
                    Your classes.<br>
                    Your progress.<br>
                    <span class="gradient-text">All beautifully connected.</span>
                </h1>
                <p class="hero-text">
                    Classora keeps students, parents and tutors connected with the moments that matter —
                    class schedules, learning materials, attendance, payments, results and timely updates.
                </p>

                <div class="hero-actions">
                    <a href="<%= contextPath %>/register.jsp" class="btn btn-primary btn-large">
                        Start as a student <i class="fa-solid fa-arrow-right"></i>
                    </a>
                    <a href="<%= contextPath %>/register-parent" class="btn btn-soft btn-large">
                        <i class="fa-solid fa-people-roof"></i> I'm a parent
                    </a>
                </div>

                <div class="hero-trust">
                    <span><i class="fa-solid fa-check"></i> Easy to use</span>
                    <span><i class="fa-solid fa-lock"></i> Secure accounts</span>
                    <span><i class="fa-solid fa-mobile-screen"></i> Works on any screen</span>
                </div>
            </div>

            <div class="hero-stage reveal reveal-right">
                <div class="floating-pill pill-top"><i class="fa-solid fa-bell"></i> New class note uploaded</div>
                <div class="app-window">
                    <div class="app-topbar">
                        <div class="app-brand-mini"><span>C</span><strong>Classora</strong></div>
                        <div class="mini-avatar">KP</div>
                    </div>

                    <div class="welcome-row">
                        <div>
                            <small>GOOD MORNING</small>
                            <h2>Hi Kasun 👋</h2>
                            <p>Ready for a great learning day?</p>
                        </div>
                        <div class="streak"><i class="fa-solid fa-fire"></i><span>12 day<br><strong>streak</strong></span></div>
                    </div>

                    <div class="next-class-card">
                        <div class="next-class-head">
                            <span>UP NEXT</span>
                            <small>Today • 4:30 PM</small>
                        </div>
                        <div class="class-row">
                            <div class="subject-icon"><i class="fa-solid fa-square-root-variable"></i></div>
                            <div class="class-copy"><strong>Mathematics</strong><span>Grade 11 • Mr. Perera</span></div>
                            <button type="button"><i class="fa-solid fa-chevron-right"></i></button>
                        </div>
                    </div>

                    <div class="mini-grid">
                        <article class="mini-card purple-card">
                            <i class="fa-solid fa-calendar-check"></i>
                            <span>Attendance</span>
                            <strong class="counter" data-count="94" data-suffix="%">0%</strong>
                        </article>
                        <article class="mini-card blue-card">
                            <i class="fa-solid fa-chart-line"></i>
                            <span>Latest result</span>
                            <strong class="counter" data-count="87" data-suffix="%">0%</strong>
                        </article>
                        <article class="mini-card cyan-card">
                            <i class="fa-solid fa-wallet"></i>
                            <span>Fee status</span>
                            <strong>Paid</strong>
                        </article>
                    </div>

                    <div class="today-strip">
                        <div><span class="today-dot"></span><strong>2</strong><small>Classes today</small></div>
                        <div><i class="fa-regular fa-file-lines"></i><strong>3</strong><small>New materials</small></div>
                        <div><i class="fa-regular fa-bell"></i><strong>1</strong><small>New notice</small></div>
                    </div>
                </div>

                <div class="floating-card floating-result">
                    <span class="floating-icon"><i class="fa-solid fa-trophy"></i></span>
                    <div><small>Science quiz</small><strong>92% • Excellent!</strong></div>
                </div>
            </div>
        </div>
    </section>

    <section class="social-proof">
        <div class="container proof-row reveal">
            <span>Built around the people who make tuition meaningful</span>
            <div class="proof-chip"><i class="fa-solid fa-user-graduate"></i> Students</div>
            <div class="proof-chip"><i class="fa-solid fa-people-roof"></i> Parents</div>
            <div class="proof-chip"><i class="fa-solid fa-chalkboard-user"></i> Tutors</div>
            <div class="proof-chip"><i class="fa-solid fa-user-tie"></i> Staff</div>
            <div class="proof-chip"><i class="fa-solid fa-shield-halved"></i> Admin</div>
        </div>
    </section>

    <section class="section experience" id="experience">
        <div class="container">
            <div class="section-heading reveal">
                <span class="section-kicker">EVERYDAY EXPERIENCE</span>
                <h2>Less searching. More learning.</h2>
                <p>Classora turns the scattered parts of tuition life into one smooth digital experience.</p>
            </div>

            <div class="experience-grid">
                <article class="experience-card feature-large reveal">
                    <div class="feature-copy">
                        <span class="feature-icon violet"><i class="fa-regular fa-calendar"></i></span>
                        <h3>Know what's happening next</h3>
                        <p>See upcoming classes, times and important reminders without digging through messages.</p>
                    </div>
                    <div class="schedule-preview">
                        <div class="schedule-day active"><span>MON</span><strong>15</strong></div>
                        <div class="schedule-day"><span>TUE</span><strong>16</strong></div>
                        <div class="schedule-day"><span>WED</span><strong>17</strong></div>
                        <div class="schedule-event"><span>4:30 PM</span><div><strong>Mathematics</strong><small>Hall A • Mr. Perera</small></div><i class="fa-solid fa-arrow-right"></i></div>
                        <div class="schedule-event soft"><span>6:00 PM</span><div><strong>Science</strong><small>Lab 02 • Ms. Silva</small></div><i class="fa-solid fa-arrow-right"></i></div>
                    </div>
                </article>

                <article class="experience-card reveal">
                    <span class="feature-icon blue"><i class="fa-solid fa-book-open"></i></span>
                    <h3>Materials when you need them</h3>
                    <p>Open class notes, tutorials and resources from the same place you check your schedule.</p>
                    <div class="file-stack">
                        <div><i class="fa-regular fa-file-pdf"></i><span><strong>Functions - Week 04</strong><small>PDF • 2.4 MB</small></span><i class="fa-solid fa-download"></i></div>
                        <div><i class="fa-regular fa-file-lines"></i><span><strong>Revision worksheet</strong><small>Updated today</small></span><i class="fa-solid fa-download"></i></div>
                    </div>
                </article>

                <article class="experience-card reveal">
                    <span class="feature-icon cyan"><i class="fa-solid fa-chart-simple"></i></span>
                    <h3>See progress clearly</h3>
                    <p>Attendance and results become easy to understand at a glance.</p>
                    <div class="progress-ring-wrap">
                        <div class="progress-ring"><span>94%</span><small>attendance</small></div>
                        <div class="progress-list"><span><i></i> Present <strong>47</strong></span><span><i></i> Absent <strong>3</strong></span><span><i></i> Late <strong>1</strong></span></div>
                    </div>
                </article>

                <article class="experience-card feature-wide reveal">
                    <div>
                        <span class="feature-icon coral"><i class="fa-regular fa-bell"></i></span>
                        <h3>Important updates don't get lost</h3>
                        <p>Class changes, fee reminders, new materials and results arrive as clear updates instead of scattered chats.</p>
                    </div>
                    <div class="notification-stack">
                        <div class="notification-item"><span class="notif-icon purple"><i class="fa-solid fa-clock"></i></span><div><strong>Class time updated</strong><small>Physics • Tomorrow at 5:00 PM</small></div><span class="new-dot"></span></div>
                        <div class="notification-item"><span class="notif-icon cyan"><i class="fa-solid fa-file-circle-check"></i></span><div><strong>New results published</strong><small>Mathematics monthly test</small></div></div>
                        <div class="notification-item"><span class="notif-icon green"><i class="fa-solid fa-circle-check"></i></span><div><strong>Payment recorded</strong><small>September class fee</small></div></div>
                    </div>
                </article>
            </div>
        </div>
    </section>

    <section class="section role-section" id="roles">
        <div class="container role-layout">
            <div class="role-copy reveal">
                <span class="section-kicker">MADE FOR EVERY ROLE</span>
                <h2>One platform, a different experience for everyone.</h2>
                <p>Select a role to see how Classora adapts to what that person actually needs.</p>

                <div class="role-tabs" role="tablist">
                    <button class="role-tab active" data-role="student"><i class="fa-solid fa-user-graduate"></i> Student</button>
                    <button class="role-tab" data-role="parent"><i class="fa-solid fa-people-roof"></i> Parent</button>
                    <button class="role-tab" data-role="tutor"><i class="fa-solid fa-chalkboard-user"></i> Tutor</button>
                </div>
            </div>

            <div class="role-card reveal reveal-right" id="roleCard">
                <div class="role-card-top">
                    <span class="role-icon"><i class="fa-solid fa-user-graduate"></i></span>
                    <div><small>STUDENT EXPERIENCE</small><h3>Stay on top of every class.</h3></div>
                </div>
                <p id="roleDescription">See schedules, materials, attendance, fees and results in one simple personal space.</p>
                <div class="role-points" id="rolePoints">
                    <span><i class="fa-solid fa-check"></i> Upcoming classes at a glance</span>
                    <span><i class="fa-solid fa-check"></i> Materials and exam results in one place</span>
                    <span><i class="fa-solid fa-check"></i> Personal attendance and payment status</span>
                </div>
                <div class="role-visual">
                    <div class="role-screen-line"><span>Next class</span><strong>Mathematics • 4:30 PM</strong></div>
                    <div class="role-screen-line"><span>Attendance</span><strong>94%</strong></div>
                    <div class="role-screen-line"><span>Latest result</span><strong>87%</strong></div>
                </div>
            </div>
        </div>
    </section>

    <section class="section journey" id="journey">
        <div class="container">
            <div class="section-heading reveal">
                <span class="section-kicker">SIMPLE FROM DAY ONE</span>
                <h2>Start in minutes, stay connected every day.</h2>
                <p>No complicated setup for students and parents — just the right information at the right time.</p>
            </div>

            <div class="journey-grid">
                <article class="journey-step reveal"><span>01</span><div class="journey-icon"><i class="fa-solid fa-user-plus"></i></div><h3>Create your account</h3><p>Students can register directly. Parents can connect to an existing student account.</p></article>
                <article class="journey-step reveal"><span>02</span><div class="journey-icon"><i class="fa-solid fa-link"></i></div><h3>Get connected</h3><p>Your classes and account role determine the information you see after login.</p></article>
                <article class="journey-step reveal"><span>03</span><div class="journey-icon"><i class="fa-solid fa-sparkles"></i></div><h3>Enjoy the experience</h3><p>Follow classes, progress, updates and payments from one calm, organized space.</p></article>
            </div>
        </div>
    </section>

    <section class="section stories" id="stories">
        <div class="container stories-grid">
            <div class="story-copy reveal">
                <span class="section-kicker">REAL MOMENTS</span>
                <h2>Designed to make tuition life feel easier.</h2>
                <p>From checking a class time to seeing a result, every interaction is designed to be clear and quick.</p>
                <div class="story-controls"><button id="storyPrev" aria-label="Previous story"><i class="fa-solid fa-arrow-left"></i></button><button id="storyNext" aria-label="Next story"><i class="fa-solid fa-arrow-right"></i></button></div>
            </div>

            <div class="story-slider reveal reveal-right" id="storySlider">
                <article class="story-card active">
                    <div class="quote-mark">“</div>
                    <p>I don't need to scroll through old messages to find my class time anymore. Everything I need is right there.</p>
                    <div class="story-person"><span class="person-avatar">KS</span><div><strong>Kasun S.</strong><small>Student</small></div></div>
                </article>
                <article class="story-card">
                    <div class="quote-mark">“</div>
                    <p>Being able to see attendance and fee information from my own account gives me much more confidence.</p>
                    <div class="story-person"><span class="person-avatar">MP</span><div><strong>Malini P.</strong><small>Parent</small></div></div>
                </article>
                <article class="story-card">
                    <div class="quote-mark">“</div>
                    <p>Students get the materials and updates they need without me repeating the same information again and again.</p>
                    <div class="story-person"><span class="person-avatar">RP</span><div><strong>Ravindu P.</strong><small>Tutor</small></div></div>
                </article>
            </div>
        </div>
    </section>

    <section class="section faq-section">
        <div class="container faq-layout">
            <div class="faq-copy reveal">
                <span class="section-kicker">QUICK ANSWERS</span>
                <h2>Questions before you join?</h2>
                <p>Here are a few things new users usually want to know.</p>
            </div>

            <div class="faq-list reveal reveal-right">
                <article class="faq-item open">
                    <button class="faq-question"><span>Do all users use the same login page?</span><i class="fa-solid fa-plus"></i></button>
                    <div class="faq-answer"><p>Yes. Classora securely reads the role linked to your account and opens the correct dashboard automatically.</p></div>
                </article>
                <article class="faq-item">
                    <button class="faq-question"><span>Can a parent connect with a child?</span><i class="fa-solid fa-plus"></i></button>
                    <div class="faq-answer"><p>Yes. Parent registration can connect to an existing student account so relevant student information can be viewed securely.</p></div>
                </article>
                <article class="faq-item">
                    <button class="faq-question"><span>Can tutors register publicly?</span><i class="fa-solid fa-plus"></i></button>
                    <div class="faq-answer"><p>No. Tutor and admin accounts are created through authorized administration for better role security.</p></div>
                </article>
            </div>
        </div>
    </section>

    <section class="cta-section">
        <div class="container cta-box reveal">
            <div class="cta-glow"></div>
            <div>
                <span class="section-kicker light">READY WHEN YOU ARE</span>
                <h2>Make your next class feel more connected.</h2>
                <p>Join Classora and keep your tuition experience simple, organized and easy to follow.</p>
            </div>
            <div class="cta-actions">
                <a href="<%= contextPath %>/register.jsp" class="btn btn-white">Create student account <i class="fa-solid fa-arrow-right"></i></a>
                <a href="<%= contextPath %>/login.jsp" class="btn btn-outline-light">Sign in</a>
            </div>
        </div>
    </section>
</main>

<footer class="footer">
    <div class="container footer-grid">
        <div>
            <a class="brand footer-brand" href="#top"><span class="brand-mark"><i class="fa-solid fa-graduation-cap"></i></span><span class="brand-copy"><strong>Classora</strong><small>Learn. Connect. Grow.</small></span></a>
            <p>A connected digital space for modern tuition classes.</p>
        </div>
        <div class="footer-links"><a href="#experience">Experience</a><a href="#roles">For You</a><a href="#journey">How It Works</a><a href="<%= contextPath %>/login.jsp">Sign in</a></div>
    </div>
    <div class="container footer-bottom"><span>© 2026 Classora.</span><span>Learn. Connect. Grow.</span></div>
</footer>

<script src="<%= contextPath %>/js/landing.js"></script>
</body>
</html>
