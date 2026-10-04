<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.TimetableSlot" %>
<%@ page import="model.Class" %>
<%@ page import="model.TutorProfile" %>
<%@ page import="java.util.List" %>

<%
    String contextPath = request.getContextPath();

    String errorMessage =
            request.getAttribute("errorMessage") != null
                    ? request.getAttribute("errorMessage").toString()
                    : "";

    List<TimetableSlot> slots =
            (List<TimetableSlot>) request.getAttribute("slots");

    List<Class> classes =
            (List<Class>) request.getAttribute("classes");

    List<TutorProfile> tutors =
            (List<TutorProfile>) request.getAttribute("tutors");

    String selectedClassId = request.getAttribute("selectedClassId") != null ? request.getAttribute("selectedClassId").toString() : "";
    String selectedTutorId = request.getAttribute("selectedTutorId") != null ? request.getAttribute("selectedTutorId").toString() : "";
    String selectedDay = request.getAttribute("selectedDay") != null ? request.getAttribute("selectedDay").toString() : "";
    String selectedStartTime = request.getAttribute("selectedStartTime") != null ? request.getAttribute("selectedStartTime").toString() : "";
    String selectedEndTime = request.getAttribute("selectedEndTime") != null ? request.getAttribute("selectedEndTime").toString() : "";
    String selectedRoom = request.getAttribute("selectedRoom") != null ? request.getAttribute("selectedRoom").toString() : "";
%>

<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">

    <meta name="viewport"
          content="width=device-width, initial-scale=1.0">

    <title>Master Timetable | Classora</title>

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

    <!-- Existing Dashboard Styles -->
    <link rel="stylesheet"
          href="<%= contextPath %>/css/dashboard.css">

    <link rel="stylesheet"
          href="<%= contextPath %>/css/dashboard-admin.css">

    <!-- Timetable Page Styles -->
    <link rel="stylesheet"
          href="<%= contextPath %>/css/manage-timetable.css">
</head>


<body class="timetable-admin-page">

<!-- =====================================================
     HEADER
===================================================== -->

<header class="timetable-topbar">

    <div class="timetable-heading">

        <a href="<%= contextPath %>/dashboard"
           class="timetable-back-btn"
           title="Back to Dashboard">

            <i class="fa-solid fa-arrow-left"></i>

        </a>


        <div>

            <span class="timetable-eyebrow">
                Schedule Management
            </span>

            <h1>
                Master Timetable
            </h1>

            <p>
                Create and manage class schedules across the institute.
            </p>

        </div>

    </div>


    <a href="<%= contextPath %>/dashboard"
       class="timetable-dashboard-btn">

        <i class="fa-solid fa-gauge-high"></i>

        <span>
            Dashboard
        </span>

    </a>

</header>


<!-- =====================================================
     MAIN
===================================================== -->

<main class="timetable-main">


    <!-- =================================================
         ERROR MESSAGE
    ================================================= -->

    <% if (!errorMessage.isEmpty()) { %>

    <div class="timetable-alert">

        <div class="timetable-alert-icon">

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


    <!-- =================================================
         ADD SLOT CARD
    ================================================= -->

    <section class="timetable-card">


        <div class="timetable-card-header">

            <div>

                <span class="timetable-section-label">
                    New Schedule
                </span>

                <h2>
                    Add Timetable Slot
                </h2>

                <p>
                    Choose a class, tutor, day, time and room for the class.
                </p>

            </div>


            <div class="timetable-header-icon">

                <i class="fa-solid fa-calendar-plus"></i>

            </div>

        </div>


        <form action="<%= contextPath %>/admin/timetable"
              method="post"
              class="timetable-form">

            <input type="hidden"
                   name="action"
                   value="create">


            <div class="timetable-form-grid">


                <!-- Class -->

                <div class="timetable-field">

                    <label for="classId">

                        <i class="fa-solid fa-book-open"></i>

                        Class

                    </label>


                    <div class="timetable-select-wrap">

                        <select id="classId"
                                name="classId"
                                required>

                            <option value="" disabled <%= selectedClassId.isEmpty() ? "selected" : "" %>>
                                Select a class
                            </option>

                            <% if (classes != null) {

                                for (Class c : classes) { %>

                            <option value="<%= c.getClassId() %>"
                                    data-type="<%= c.getClassType() %>"
                                    <%= String.valueOf(c.getClassId()).equals(selectedClassId) ? "selected" : "" %>>

                                [<%= c.getClassTypeDisplay() %>] <%= c.getSubject() %> - <%= c.getBatch() %>

                            </option>

                            <% }

                            } %>

                        </select>

                        <i class="fa-solid fa-chevron-down"></i>

                    </div>

                </div>


                <!-- Tutor -->

                <div class="timetable-field">

                    <label for="tutorId">

                        <i class="fa-solid fa-chalkboard-user"></i>

                        Tutor

                    </label>


                    <div class="timetable-select-wrap">

                        <select id="tutorId"
                                name="tutorId"
                                required>

                            <option value="" disabled <%= selectedTutorId.isEmpty() ? "selected" : "" %>>
                                Select a tutor
                            </option>

                            <% if (tutors != null) {

                                for (TutorProfile t : tutors) { %>

                            <option value="<%= t.getUserId() %>" <%= String.valueOf(t.getUserId()).equals(selectedTutorId) ? "selected" : "" %>>

                                <%= t.getFullName() %>

                            </option>

                            <% }

                            } %>

                        </select>

                        <i class="fa-solid fa-chevron-down"></i>

                    </div>

                </div>


                <!-- Day -->

                <div class="timetable-field">

                    <label for="dayOfWeek">

                        <i class="fa-regular fa-calendar-days"></i>

                        Day of Week

                    </label>


                    <div class="timetable-select-wrap">

                        <select id="dayOfWeek"
                                name="dayOfWeek"
                                required>

                            <option value="" disabled <%= selectedDay.isEmpty() ? "selected" : "" %>>
                                Select a day
                            </option>

                            <option value="MON" data-group="WEEKDAY" <%= "MON".equalsIgnoreCase(selectedDay) ? "selected" : "" %>>Monday</option>
                            <option value="TUE" data-group="WEEKDAY" <%= "TUE".equalsIgnoreCase(selectedDay) ? "selected" : "" %>>Tuesday</option>
                            <option value="WED" data-group="WEEKDAY" <%= "WED".equalsIgnoreCase(selectedDay) ? "selected" : "" %>>Wednesday</option>
                            <option value="THU" data-group="WEEKDAY" <%= "THU".equalsIgnoreCase(selectedDay) ? "selected" : "" %>>Thursday</option>
                            <option value="FRI" data-group="WEEKDAY" <%= "FRI".equalsIgnoreCase(selectedDay) ? "selected" : "" %>>Friday</option>
                            <option value="SAT" data-group="WEEKEND" <%= "SAT".equalsIgnoreCase(selectedDay) ? "selected" : "" %>>Saturday</option>
                            <option value="SUN" data-group="WEEKEND" <%= "SUN".equalsIgnoreCase(selectedDay) ? "selected" : "" %>>Sunday</option>

                        </select>

                        <i class="fa-solid fa-chevron-down"></i>

                    </div>

                </div>


                <!-- Room -->

                <div class="timetable-field">

                    <label for="room">

                        <i class="fa-solid fa-door-open"></i>

                        Room

                        <span class="timetable-optional">
                            Optional
                        </span>

                    </label>

                    <input type="text"
                           id="room"
                           name="room"
                           value="<%= selectedRoom %>"
                           maxlength="50"
                           placeholder="e.g. Hall A">

                </div>


                <!-- Start Time -->

                <div class="timetable-field">

                    <label for="startTime">

                        <i class="fa-regular fa-clock"></i>

                        Start Time

                    </label>

                    <input type="time"
                           id="startTime"
                           name="startTime"
                           value="<%= selectedStartTime %>"
                           required>

                </div>


                <!-- End Time -->

                <div class="timetable-field">

                    <label for="endTime">

                        <i class="fa-solid fa-clock"></i>

                        End Time

                    </label>

                    <input type="time"
                           id="endTime"
                           name="endTime"
                           value="<%= selectedEndTime %>"
                           required>

                </div>

                <!-- Live Validation Hint -->
                <div id="timeValidationHint" style="display:none; grid-column: 1 / -1; font-size: 0.88rem; padding: 10px 14px; border-radius: 8px; line-height: 1.5;"></div>


            </div>


            <div class="timetable-form-actions">

                <a href="<%= contextPath %>/dashboard"
                   class="timetable-secondary-btn">

                    <i class="fa-solid fa-arrow-left"></i>

                    Back to Dashboard

                </a>


                <button type="submit"
                        class="timetable-primary-btn">

                    <i class="fa-solid fa-calendar-plus"></i>

                    Add Slot

                </button>

            </div>

        </form>

    </section>


    <!-- =================================================
         CURRENT TIMETABLE
    ================================================= -->

    <section class="timetable-card">


        <div class="timetable-card-header">

            <div>

                <span class="timetable-section-label">
                    Schedule Directory
                </span>

                <h2>
                    Current Timetable
                </h2>

                <p>
                    View all scheduled classes and cancel slots when necessary.
                </p>

            </div>


            <div class="timetable-count">

                <i class="fa-regular fa-calendar-check"></i>

                <span>

                    <%= slots != null ? slots.size() : 0 %>

                    Slots

                </span>

            </div>

        </div>


        <div class="timetable-table-wrapper">

            <table class="timetable-table">

                <thead>

                <tr>

                    <th>
                        Day
                    </th>

                    <th>
                        Time
                    </th>

                    <th>
                        Subject
                    </th>

                    <th>
                        Batch
                    </th>

                    <th>
                        Tutor
                    </th>

                    <th>
                        Room
                    </th>

                    <th>
                        Tutor Status
                    </th>

                    <th class="timetable-actions-heading">
                        Actions
                    </th>

                </tr>

                </thead>


                <tbody>

                <%
                    if (slots != null && !slots.isEmpty()) {

                        for (TimetableSlot s : slots) {
                %>

                <tr>


                    <!-- Day -->

                    <td>

                        <span class="day-badge day-<%= s.getDayOfWeek().toLowerCase() %>">

                            <i class="fa-regular fa-calendar"></i>

                            <%= s.getDayOfWeek() %>

                        </span>

                    </td>


                    <!-- Time -->

                    <td>

                        <div class="time-cell">

                            <i class="fa-regular fa-clock"></i>

                            <div>

                                <span class="time-main">
                                    <%= s.getStartTime() %>
                                </span>

                                <span class="time-separator">
                                    to
                                </span>

                                <span class="time-main">
                                    <%= s.getEndTime() %>
                                </span>

                            </div>

                        </div>

                    </td>


                    <!-- Subject -->

                    <td>

                        <div class="subject-cell">

                            <div class="subject-icon">

                                <i class="fa-solid fa-book-open"></i>

                            </div>

                            <span>
                                <%= s.getSubject() %>
                            </span>

                        </div>

                    </td>


                    <!-- Batch -->

                    <td>

                        <span class="batch-badge">

                            <%= s.getBatch() %>

                        </span>

                    </td>


                    <!-- Tutor -->

                    <td>

                        <div class="timetable-tutor-cell">

                            <div class="tutor-avatar">

                                <i class="fa-solid fa-user"></i>

                            </div>

                            <span>
                                <%= s.getTutorName() %>
                            </span>

                        </div>

                    </td>


                    <!-- Room -->

                    <td>

                        <%
                            if (s.getRoom() != null
                                    && !s.getRoom().trim().isEmpty()) {
                        %>

                        <span class="room-badge">

                            <i class="fa-solid fa-location-dot"></i>

                            <%= s.getRoom() %>

                        </span>

                        <% } else { %>

                        <span class="no-room">

                            Not assigned

                        </span>

                        <% } %>

                    </td>


                    <!-- Tutor Confirmation Status -->
                    <td>
                        <% if (s.isConfirmed()) { %>
                            <span style="display:inline-flex;align-items:center;gap:5px;background:#dcfce7;color:#15803d;font-size:12px;font-weight:600;padding:4px 8px;border-radius:6px;">
                                <i class="fa-solid fa-circle-check"></i> Confirmed
                            </span>
                        <% } else if (s.isChangeSuggested()) { %>
                            <div style="display:flex;flex-direction:column;gap:6px;">
                                <span style="display:inline-flex;align-items:center;gap:5px;background:#f3e8ff;color:#7e22ce;font-size:12px;font-weight:700;padding:4px 8px;border-radius:6px;width:fit-content;">
                                    <i class="fa-solid fa-arrows-rotate"></i> Time Change Suggested
                                </span>
                                <div style="font-size:11.5px;color:#334155;background:#faf5ff;border:1px solid #e9d5ff;padding:6px 8px;border-radius:6px;line-height:1.4;">
                                    <div><strong>Proposed:</strong> <%= s.getSuggestedDay() %> <%= s.getSuggestedStartTime() %> – <%= s.getSuggestedEndTime() %></div>
                                    <% if (s.getTutorNote() != null && !s.getTutorNote().isBlank()) { %>
                                        <div style="color:#64748b;margin-top:2px;"><em>"<%= s.getTutorNote() %>"</em></div>
                                    <% } %>
                                </div>
                                <form action="<%= contextPath %>/admin/timetable" method="post" style="margin-top:2px;">
                                    <input type="hidden" name="action" value="acceptSuggestion">
                                    <input type="hidden" name="slotId" value="<%= s.getSlotId() %>">
                                    <button type="submit" style="border:none;background:#16a34a;color:#fff;font-size:11px;font-weight:600;padding:5px 9px;border-radius:6px;cursor:pointer;display:inline-flex;align-items:center;gap:4px;">
                                        <i class="fa-solid fa-check"></i> Accept Suggestion
                                    </button>
                                </form>
                            </div>
                        <% } else { %>
                            <span style="display:inline-flex;align-items:center;gap:5px;background:#fef3c7;color:#b45309;font-size:12px;font-weight:600;padding:4px 8px;border-radius:6px;">
                                <i class="fa-regular fa-clock"></i> Pending Tutor
                            </span>
                        <% } %>
                    </td>


                    <!-- Actions -->

                    <td>

                        <div class="timetable-actions">

                            <form action="<%= contextPath %>/admin/timetable"
                                  method="post"
                                  class="timetable-cancel-form"
                                  onsubmit="return confirm('Are you sure you want to cancel this timetable slot?');">

                                <input type="hidden"
                                       name="action"
                                       value="cancel">

                                <input type="hidden"
                                       name="slotId"
                                       value="<%= s.getSlotId() %>">


                                <button type="submit"
                                        class="timetable-action-btn timetable-cancel-btn"
                                        title="Cancel Slot">

                                    <i class="fa-solid fa-xmark"></i>

                                    <span>
                                        Cancel
                                    </span>

                                </button>

                            </form>

                        </div>

                    </td>

                </tr>

                <%
                    }

                } else {
                %>


                <!-- EMPTY STATE -->

                <tr>

                    <td colspan="8">

                        <div class="timetable-empty">

                            <div class="timetable-empty-icon">

                                <i class="fa-regular fa-calendar-xmark"></i>

                            </div>

                            <h3>
                                No timetable slots
                            </h3>

                            <p>
                                Add your first timetable slot using the form above.
                            </p>

                        </div>

                    </td>

                </tr>

                <% } %>

                </tbody>

            </table>

        </div>

    </section>


</main>

<script>
document.addEventListener('DOMContentLoaded', function() {
    const form = document.querySelector('.timetable-form');
    const startInput = document.getElementById('startTime');
    const endInput = document.getElementById('endTime');
    const submitBtn = form ? form.querySelector('button[type="submit"]') : null;
    const hint = document.getElementById('timeValidationHint');

    const classSelect = document.getElementById('classId');
    const daySelect = document.getElementById('dayOfWeek');

    function syncClassDays() {
        if (!classSelect || !daySelect) return;
        const selectedOpt = classSelect.options[classSelect.selectedIndex];
        if (!selectedOpt || !selectedOpt.dataset.type) return;

        const classType = selectedOpt.dataset.type.toUpperCase();
        const isWeekend = classType === 'WEEKEND';

        let currentDayValid = false;

        Array.from(daySelect.options).forEach(opt => {
            if (!opt.value) return;
            const group = opt.dataset.group;
            if (isWeekend) {
                if (group === 'WEEKEND') {
                    opt.disabled = false;
                    opt.style.display = '';
                    if (opt.selected) currentDayValid = true;
                } else {
                    opt.disabled = true;
                    opt.style.display = 'none';
                    if (opt.selected) opt.selected = false;
                }
            } else {
                if (group === 'WEEKDAY') {
                    opt.disabled = false;
                    opt.style.display = '';
                    if (opt.selected) currentDayValid = true;
                } else {
                    opt.disabled = true;
                    opt.style.display = 'none';
                    if (opt.selected) opt.selected = false;
                }
            }
        });

        if (!currentDayValid && !daySelect.value) {
            for (let i = 0; i < daySelect.options.length; i++) {
                if (!daySelect.options[i].disabled && daySelect.options[i].value) {
                    daySelect.options[i].selected = true;
                    break;
                }
            }
        }
    }

    if (classSelect) {
        classSelect.addEventListener('change', syncClassDays);
        syncClassDays();
    }

    function format12h(timeStr) {
        if (!timeStr) return '';
        const parts = timeStr.split(':');
        if (parts.length < 2) return timeStr;
        let h = parseInt(parts[0], 10);
        const m = parts[1];
        const ampm = h >= 12 ? 'PM' : 'AM';
        h = h % 12;
        if (h === 0) h = 12;
        return (h < 10 ? '0' + h : h) + ':' + m + ' ' + ampm;
    }

    function checkTimes() {
        if (!startInput.value || !endInput.value) {
            if (hint) hint.style.display = 'none';
            return true;
        }

        const sParts = startInput.value.split(':').map(Number);
        const eParts = endInput.value.split(':').map(Number);

        if (sParts.length < 2 || eParts.length < 2 || isNaN(sParts[0]) || isNaN(eParts[0])) {
            return true;
        }

        const sMinutes = sParts[0] * 60 + sParts[1];
        const eMinutes = eParts[0] * 60 + eParts[1];

        if (eMinutes <= sMinutes) {
            let msg = 'End time (' + format12h(endInput.value) + ') is earlier than or equal to start time (' + format12h(startInput.value) + ').';
            if (sParts[0] >= 12 && eParts[0] < 12) {
                const suggestedHour = eParts[0] + 12;
                const suggestedTime = (suggestedHour < 10 ? '0' : '') + suggestedHour + ':' + (eParts[1] < 10 ? '0' : '') + eParts[1];
                msg += '<br><strong>Tip:</strong> Did you mean <u>' + format12h(suggestedTime) + '</u>? Click the AM/PM toggle on the End Time input to select PM.';
            }

            if (hint) {
                hint.innerHTML = '<i class="fa-solid fa-triangle-exclamation" style="margin-right:6px;"></i> ' + msg;
                hint.style.display = 'block';
                hint.style.background = '#fff1f2';
                hint.style.color = '#be123c';
                hint.style.border = '1px solid #fecdd3';
            }
            return false;
        } else {
            const diffMin = eMinutes - sMinutes;
            const hours = Math.floor(diffMin / 60);
            const mins = diffMin % 60;
            const durationStr = (hours > 0 ? hours + ' hr ' : '') + (mins > 0 ? mins + ' min' : (hours === 0 ? '0 min' : ''));

            if (hint) {
                hint.innerHTML = '<i class="fa-solid fa-circle-check" style="margin-right:6px;"></i> Duration: <strong>'
                    + durationStr + '</strong> (' + format12h(startInput.value) + ' to ' + format12h(endInput.value) + ')';
                hint.style.display = 'block';
                hint.style.background = '#f0fdf4';
                hint.style.color = '#15803d';
                hint.style.border = '1px solid #bbf7d0';
            }
            return true;
        }
    }

    // Auto-assist: when start time is chosen and end time is empty, preset to start + 2 hours
    startInput.addEventListener('change', function() {
        if (startInput.value && !endInput.value) {
            const parts = startInput.value.split(':').map(Number);
            if (parts.length >= 2 && !isNaN(parts[0])) {
                let endH = (parts[0] + 2) % 24;
                let endM = parts[1];
                endInput.value = (endH < 10 ? '0' : '') + endH + ':' + (endM < 10 ? '0' : '') + endM;
            }
        }
        checkTimes();
    });

    startInput.addEventListener('input', checkTimes);
    endInput.addEventListener('input', checkTimes);
    endInput.addEventListener('change', checkTimes);

    // Run initial check if values were preserved
    if (startInput.value && endInput.value) {
        checkTimes();
    }

    if (form) {
        form.addEventListener('submit', function(e) {
            if (!checkTimes()) {
                e.preventDefault();
                alert('Please ensure the End Time is after the Start Time. Check AM/PM settings.');
                return false;
            }

            if (submitBtn) {
                submitBtn.disabled = true;
                submitBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Adding Slot...';
            }
        });
    }
});
</script>

</body>

</html>
