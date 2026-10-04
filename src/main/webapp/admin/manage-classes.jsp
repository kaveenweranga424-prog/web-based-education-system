<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Class" %>
<%@ page import="model.TutorProfile" %>
<%@ page import="java.util.List" %>

<%
    String contextPath = request.getContextPath();

    String errorMessage =
            request.getAttribute("errorMessage") != null
                    ? request.getAttribute("errorMessage").toString()
                    : "";

    List<Class> classes =
            (List<Class>) request.getAttribute("classes");

    List<TutorProfile> tutors =
            (List<TutorProfile>) request.getAttribute("tutors");

    Class editClassItem =
            (Class) request.getAttribute("classItem");
%>

<!DOCTYPE html>
<html lang="en">

<head>

    <meta charset="UTF-8">

    <meta name="viewport"
          content="width=device-width, initial-scale=1.0">

    <title>Manage Classes | Classora</title>


    <!-- Google Fonts -->
    <link rel="preconnect"
          href="https://fonts.googleapis.com">

    <link rel="preconnect"
          href="https://fonts.gstatic.com"
          crossorigin>

    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=Plus+Jakarta+Sans:wght@500;600;700;800&display=swap"
          rel="stylesheet">


    <!-- Font Awesome -->
    <link rel="stylesheet"
          href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">


    <!-- Existing Dashboard CSS -->
    <link rel="stylesheet"
          href="<%= contextPath %>/css/dashboard.css">

    <link rel="stylesheet"
          href="<%= contextPath %>/css/dashboard-admin.css">


    <!-- Manage Classes CSS -->
    <link rel="stylesheet"
          href="<%= contextPath %>/css/manage-classes.css">

</head>


<body class="class-admin-page">


<!-- ===================================================== -->
<!-- TOP HEADER -->
<!-- ===================================================== -->

<header class="class-topbar">

    <div class="class-heading">

        <a href="<%= contextPath %>/dashboard"
           class="back-btn">

            <i class="fa-solid fa-arrow-left"></i>

        </a>


        <div>

            <span class="page-eyebrow">
                Class Management
            </span>

            <h1>
                Manage Classes
            </h1>

            <p>
                Create, edit and manage institute classes.
            </p>

        </div>

    </div>


    <a href="<%= contextPath %>/dashboard"
       class="dashboard-btn">

        <i class="fa-solid fa-gauge-high"></i>

        Dashboard

    </a>

</header>



<!-- ===================================================== -->
<!-- MAIN CONTENT -->
<!-- ===================================================== -->

<main class="class-main">


    <!-- ================================================= -->
    <!-- ERROR MESSAGE -->
    <!-- ================================================= -->

    <% if (!errorMessage.isEmpty()) { %>

    <div class="class-alert">

        <div class="class-alert-icon">

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



    <!-- ================================================= -->
    <!-- CLASS FORM -->
    <!-- ================================================= -->

    <section class="class-card">


        <div class="class-card-header">

            <div>

                <span class="section-label">
                    <%= editClassItem != null ? "Update class" : "New class" %>
                </span>

                <h2>

                    <%= editClassItem != null
                            ? "Edit Class"
                            : "Create New Class" %>

                </h2>

                <p>

                    <%= editClassItem != null
                            ? "Update the details of this class."
                            : "Enter the information below to create a new class." %>

                </p>

            </div>


            <div class="header-icon">

                <i class="fa-solid fa-book-open"></i>

            </div>

        </div>



        <form action="<%= contextPath %>/admin/classes"
              method="post"
              enctype="multipart/form-data"
              class="class-form">


            <!-- Action -->

            <input type="hidden"
                   name="action"
                   value="<%= editClassItem != null ? "update" : "create" %>">


            <% if (editClassItem != null) { %>

            <input type="hidden"
                   name="classId"
                   value="<%= editClassItem.getClassId() %>">

            <% } %>



            <div class="class-form-grid">


                <!-- Subject -->

                <div class="class-field">

                    <label for="subject">

                        <i class="fa-solid fa-book"></i>

                        Subject

                    </label>


                    <input type="text"
                           id="subject"
                           name="subject"
                           maxlength="100"
                           placeholder="e.g. Mathematics"
                           value="<%= editClassItem != null
                                   ? editClassItem.getSubject()
                                   : "" %>"
                           required>

                </div>



                <!-- Batch / Grade -->

                <div class="class-field">

                    <label for="batch">

                        <i class="fa-solid fa-graduation-cap"></i>

                        Grade / Batch

                    </label>


                    <input type="text"
                           id="batch"
                           name="batch"
                           list="gradeList"
                           maxlength="50"
                           placeholder="e.g. Grade 10"
                           value="<%= editClassItem != null
                                   ? editClassItem.getBatch()
                                   : "" %>"
                           required
                           autocomplete="off">

                    <datalist id="gradeList">
                        <option value="Grade 6">
                        <option value="Grade 7">
                        <option value="Grade 8">
                        <option value="Grade 9">
                        <option value="Grade 10">
                        <option value="Grade 11">
                        <option value="Grade 12">
                        <option value="Grade 13">
                        <option value="2026 A/L">
                        <option value="2027 A/L">
                    </datalist>

                </div>



                <!-- Schedule Type (Weekday / Weekend) -->

                <div class="class-field">

                    <label>

                        <i class="fa-solid fa-calendar-days"></i>

                        Schedule Type

                    </label>

                    <%
                        String curClassType = editClassItem != null ? editClassItem.getClassType() : "WEEKDAY";
                    %>

                    <div class="schedule-type-selector">

                        <label class="schedule-option <%= "WEEKDAY".equalsIgnoreCase(curClassType) ? "active" : "" %>" id="optWeekday">

                            <input type="radio" name="classType" value="WEEKDAY" <%= "WEEKDAY".equalsIgnoreCase(curClassType) ? "checked" : "" %>>

                            <span class="schedule-icon">
                                <i class="fa-solid fa-calendar-day"></i>
                            </span>

                            <div class="schedule-info">
                                <strong>Weekday Batch</strong>
                                <small>Monday – Friday</small>
                            </div>

                        </label>


                        <label class="schedule-option <%= "WEEKEND".equalsIgnoreCase(curClassType) ? "active" : "" %>" id="optWeekend">

                            <input type="radio" name="classType" value="WEEKEND" <%= "WEEKEND".equalsIgnoreCase(curClassType) ? "checked" : "" %>>

                            <span class="schedule-icon weekend">
                                <i class="fa-solid fa-mug-hot"></i>
                            </span>

                            <div class="schedule-info">
                                <strong>Weekend Batch</strong>
                                <small>Saturday – Sunday</small>
                            </div>

                        </label>

                    </div>

                </div>





                <!-- Tutor -->

                <div class="class-field">

                    <label for="tutorId">

                        <i class="fa-solid fa-chalkboard-user"></i>

                        Assign Tutor

                        <span class="optional">
                            Optional
                        </span>

                    </label>

                    <select id="tutorId"
                            name="tutorId"
                            style="width: 100%; height: 46px; padding: 10px 14px; border: 1.5px solid #e5e7eb; border-radius: 10px; font-size: 14px; font-family: inherit; background-color: #fff; color: #111827;">
                        <option value="">-- No Tutor Assigned --</option>
                        <% if (tutors != null) {
                            for (TutorProfile t : tutors) {
                                boolean isSelected = editClassItem != null
                                        && editClassItem.getTutorId() != null
                                        && editClassItem.getTutorId() == t.getUserId();
                        %>
                        <option value="<%= t.getUserId() %>" <%= isSelected ? "selected" : "" %>>
                            <%= t.getFullName() %> (<%= t.getSpecialization() != null && !t.getSpecialization().isBlank() ? t.getSpecialization() : t.getEmail() %>)
                        </option>
                        <% } } %>
                    </select>

                </div>



                <!-- Fee -->

                <div class="class-field">

                    <label for="fee">

                        <i class="fa-solid fa-money-bill-wave"></i>

                        Class Fee

                    </label>


                    <div class="money-input">

                        <span>
                            Rs.
                        </span>

                        <input type="number"
                               id="fee"
                               name="fee"
                               min="0"
                               step="0.01"
                               placeholder="5000.00"
                               value="<%= editClassItem != null
                                       ? editClassItem.getFee()
                                       : "" %>"
                               required>

                    </div>

                </div>



                <!-- Status -->

                <% if (editClassItem != null) { %>

                <div class="class-field full-width">

                    <label for="status">

                        <i class="fa-solid fa-circle-check"></i>

                        Status

                    </label>


                    <div class="select-wrapper">

                        <select id="status"
                                name="status">

                            <option value="ACTIVE"
                                    <%= "ACTIVE".equals(editClassItem.getStatus())
                                            ? "selected"
                                            : "" %>>

                                Active

                            </option>


                            <option value="INACTIVE"
                                    <%= "INACTIVE".equals(editClassItem.getStatus())
                                            ? "selected"
                                            : "" %>>

                                Inactive

                            </option>

                        </select>


                        <i class="fa-solid fa-chevron-down"></i>

                    </div>

                </div>

                <% } %>
                <!-- Class Banner Image -->
                <div class="class-field full-width">
                    <label for="classImage">
                        <i class="fa-solid fa-image"></i>
                        Class Banner Image
                        <span class="optional">Optional</span>
                    </label>
                    <div style="display: flex; gap: 16px; align-items: center; flex-wrap: wrap; margin-top: 4px;">
                        <% if (editClassItem != null && editClassItem.getImagePath() != null && !editClassItem.getImagePath().isBlank()) { %>
                            <div style="position: relative; width: 120px; height: 68px; border-radius: 8px; overflow: hidden; border: 1.5px solid #e2e8f0; box-shadow: 0 2px 6px rgba(0,0,0,0.06); flex-shrink: 0;">
                                <img src="<%= contextPath %>/<%= editClassItem.getImagePath() %>" alt="Current Banner" style="width: 100%; height: 100%; object-fit: cover;">
                            </div>
                        <% } %>
                        <div style="flex: 1; min-width: 240px;">
                            <input type="file"
                                   id="classImage"
                                   name="classImage"
                                   accept="image/png, image/jpeg, image/webp"
                                   style="width: 100%; padding: 10px 14px; border: 1.5px dashed #cbd5e1; border-radius: 10px; font-size: 13px; font-family: inherit; background-color: #f8fafc; cursor: pointer;">
                            <span style="display: block; margin-top: 6px; font-size: 12px; color: #64748b;">
                                <i class="fa-solid fa-circle-info"></i> Upload a custom 16:9 banner image (PNG, JPG, WebP - max 10MB). If not provided, a default subject-themed banner is used.
                            </span>
                        </div>
                    </div>
                </div>

            </div>



            <!-- Form Actions -->

            <div class="class-form-actions">


                <% if (editClassItem != null) { %>

                <a href="<%= contextPath %>/admin/classes"
                   class="btn-class-secondary">

                    <i class="fa-solid fa-xmark"></i>

                    Cancel

                </a>

                <% } %>


                <button type="submit"
                        class="btn-class-primary">

                    <i class="fa-solid
                        <%= editClassItem != null
                                ? "fa-floppy-disk"
                                : "fa-plus" %>">
                    </i>


                    <%= editClassItem != null
                            ? "Save Changes"
                            : "Create Class" %>

                </button>


            </div>


        </form>

    </section>



    <!-- ================================================= -->
    <!-- CLASSES TABLE -->
    <!-- ================================================= -->

    <section class="class-card class-list-card">


        <div class="class-card-header">

            <div>

                <span class="section-label">
                    Class Directory
                </span>

                <h2>
                    All Classes
                </h2>

                <p>
                    View and manage all institute classes.
                </p>

            </div>


            <div class="class-count">

                <i class="fa-solid fa-layer-group"></i>

                <span>

                    <%= classes != null
                            ? classes.size()
                            : 0 %>

                    Classes

                </span>

            </div>

        </div>



        <!-- Table -->

        <div class="class-table-wrapper">


            <table class="class-table">


                <thead>

                <tr>

                    <th>ID</th>

                    <th>Banner</th>

                    <th>Subject</th>

                    <th>Batch</th>

                    <th>Schedule</th>

                    <th>Tutor</th>

                    <th>Fee</th>

                    <th>Status</th>

                    <th class="actions-heading">
                        Actions
                    </th>

                </tr>

                </thead>



                <tbody>


                <% if (classes != null && !classes.isEmpty()) {

                    for (Class c : classes) {

                %>


                <tr>


                    <!-- ID -->

                    <td>

                        <span class="class-id">

                            #<%= c.getClassId() %>

                        </span>

                    </td>



                    <!-- Banner -->

                    <td>
                        <%
                            String bImg = c.getImagePath();
                            if (bImg == null || bImg.isBlank()) {
                                String sLow = c.getSubject() != null ? c.getSubject().toLowerCase() : "";
                                if (sLow.contains("math")) bImg = "images/courses/maths.jpg";
                                else if (sLow.contains("sci")) bImg = "images/courses/science.jpg";
                                else if (sLow.contains("it") || sLow.contains("ict") || sLow.contains("tech")) bImg = "images/courses/it.jpg";
                                else if (sLow.contains("eng")) bImg = "images/courses/english.jpg";
                                else bImg = "images/courses/default.jpg";
                            }
                        %>
                        <div style="width: 58px; height: 36px; border-radius: 6px; overflow: hidden; border: 1px solid #e2e8f0; box-shadow: 0 1px 3px rgba(0,0,0,0.05);">
                            <img src="<%= contextPath %>/<%= bImg %>" alt="<%= c.getSubject() %>" style="width: 100%; height: 100%; object-fit: cover;">
                        </div>
                    </td>



                    <!-- Subject -->

                    <td>

                        <div class="subject-cell">

                            <div class="subject-icon">

                                <i class="fa-solid fa-book-open"></i>

                            </div>


                            <span>

                                <%= c.getSubject() %>

                            </span>

                        </div>

                    </td>



                    <!-- Batch -->

                    <td>

                        <span class="batch-badge">

                            <%= c.getBatch() %>

                        </span>

                    </td>



                    <!-- Schedule -->

                    <td>

                        <% if (c.isWeekend()) { %>

                        <span class="badge-schedule badge-weekend">

                            <i class="fa-solid fa-mug-hot"></i> Weekend

                        </span>

                        <% } else { %>

                        <span class="badge-schedule badge-weekday">

                            <i class="fa-solid fa-calendar-day"></i> Weekday

                        </span>

                        <% } %>

                    </td>



                    <!-- Tutor -->

                    <td>

                        <div class="tutor-cell">

                            <div class="mini-avatar">

                                <i class="fa-solid fa-user"></i>

                            </div>


                            <span>

                                <%= c.getTutorName() != null
                                        ? c.getTutorName()
                                        : "Not assigned" %>

                            </span>

                        </div>

                    </td>



                    <!-- Fee -->

                    <td>

                        <span class="class-fee">

                            Rs.
                            <%= c.getFee() %>

                        </span>

                    </td>



                    <!-- Status -->

                    <td>


                        <% if ("ACTIVE".equals(c.getStatus())) { %>

                        <span class="class-status status-active">

                            <span class="status-dot"></span>

                            Active

                        </span>


                        <% } else { %>


                        <span class="class-status status-inactive">

                            <span class="status-dot"></span>

                            Inactive

                        </span>


                        <% } %>


                    </td>



                    <!-- Actions -->

                    <td>


                        <div class="class-actions">


                            <!-- Edit -->

                            <a href="<%= contextPath %>/admin/classes?action=edit&id=<%= c.getClassId() %>"
                               class="class-action-btn edit"
                               title="Edit Class">

                                <i class="fa-solid fa-pen"></i>

                            </a>





                            <!-- Delete -->

                            <form action="<%= contextPath %>/admin/classes"
                                  method="post"
                                  class="inline-form"
                                  onsubmit="return confirm('Are you sure you want to permanently delete this class? This action cannot be undone.');">


                                <input type="hidden"
                                       name="action"
                                       value="delete">


                                <input type="hidden"
                                       name="classId"
                                       value="<%= c.getClassId() %>">


                                <button type="submit"
                                        class="class-action-btn"
                                        style="background: #fef2f2; color: #dc2626; border: 1px solid #fecaca; border-radius: 8px; width: 34px; height: 34px; display: inline-flex; align-items: center; justify-content: center; cursor: pointer; transition: all 0.2s;"
                                        onmouseover="this.style.background='#fee2e2'; this.style.color='#b91c1c';"
                                        onmouseout="this.style.background='#fef2f2'; this.style.color='#dc2626';"
                                        title="Permanently Delete Class">

                                    <i class="fa-solid fa-trash"></i>

                                </button>


                            </form>


                        </div>


                    </td>


                </tr>


                <%

                    }

                } else {

                %>


                <!-- Empty State -->

                <tr>

                    <td colspan="9">


                        <div class="class-empty">


                            <div class="empty-icon">

                                <i class="fa-solid fa-book-open"></i>

                            </div>


                            <h3>
                                No classes yet
                            </h3>


                            <p>
                                Create your first class using the form above.
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
    const radioWeekday = document.querySelector('input[name="classType"][value="WEEKDAY"]');
    const radioWeekend = document.querySelector('input[name="classType"][value="WEEKEND"]');
    const optWeekday = document.getElementById('optWeekday');
    const optWeekend = document.getElementById('optWeekend');

    function updateSelection() {
        const isWeekend = radioWeekend && radioWeekend.checked;
        if (optWeekday) optWeekday.classList.toggle('active', !isWeekend);
        if (optWeekend) optWeekend.classList.toggle('active', isWeekend);
    }

    if (optWeekday) {
        optWeekday.addEventListener('click', function() {
            if (radioWeekday) {
                radioWeekday.checked = true;
                updateSelection();
            }
        });
    }

    if (optWeekend) {
        optWeekend.addEventListener('click', function() {
            if (radioWeekend) {
                radioWeekend.checked = true;
                updateSelection();
            }
        });
    }

    updateSelection();
});
</script>

</body>

</html>