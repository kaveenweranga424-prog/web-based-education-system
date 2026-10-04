<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Class" %>
<%@ page import="model.ClassMaterial" %>
<%@ page import="java.util.List" %>

<%!
    private String esc(Object value) {
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
    Integer classId = (Integer) request.getAttribute("classId");
    Class selectedClass = (Class) request.getAttribute("selectedClass");
    List<Class> assignedClasses = (List<Class>) request.getAttribute("assignedClasses");
    List<ClassMaterial> materials = (List<ClassMaterial>) request.getAttribute("materials");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Materials | Classora</title>

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Plus+Jakarta+Sans:wght@500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/dashboard.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/dashboard-tutor.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/manage-materials.css">
</head>

<body class="materials-admin-page">
<header class="materials-topbar">
    <div class="materials-heading">
        <a href="<%= contextPath %>/dashboard" class="materials-back-btn" title="Back to Dashboard">
            <i class="fa-solid fa-arrow-left"></i>
        </a>
        <div>
            <span class="materials-eyebrow">Tutor · Learning Resources</span>
            <h1>Manage Materials</h1>
            <p>Choose one of your assigned classes, then upload or update its learning materials.</p>
        </div>
    </div>

    <div class="materials-top-actions">
        <% if (selectedClass != null) { %>
        <div class="class-reference">
            <i class="fa-solid fa-book-open"></i>
            <span><%= esc(selectedClass.getSubject()) %> · <%= esc(selectedClass.getBatch()) %></span>
        </div>
        <% } %>
        <a href="<%= contextPath %>/dashboard" class="materials-dashboard-btn">
            <i class="fa-solid fa-gauge-high"></i><span>Dashboard</span>
        </a>
    </div>
</header>

<main class="materials-main">
    <% if (!errorMessage.isEmpty()) { %>
    <div class="materials-alert">
        <div class="materials-alert-icon"><i class="fa-solid fa-circle-exclamation"></i></div>
        <div><strong>Something went wrong</strong><span><%= esc(errorMessage) %></span></div>
    </div>
    <% } %>

    <section class="materials-card material-class-picker-card">
        <div class="materials-card-header">
            <div>
                <span class="materials-section-label">Your Assigned Classes</span>
                <h2>Select a Class</h2>
                <p>Only classes assigned to your tutor account are available here.</p>
            </div>
            <div class="materials-header-icon"><i class="fa-solid fa-chalkboard-user"></i></div>
        </div>

        <% if (assignedClasses != null && !assignedClasses.isEmpty()) { %>
        <form action="<%= contextPath %>/tutor/materials" method="get" class="materials-form class-picker-form">
            <div class="materials-field">
                <label for="classId"><i class="fa-solid fa-book-open"></i> Assigned Class</label>
                <select id="classId" name="classId" required>
                    <option value="">Choose a class</option>
                    <% for (Class c : assignedClasses) { %>
                    <option value="<%= c.getClassId() %>"
                            <%= classId != null && classId == c.getClassId() ? "selected" : "" %>>
                        <%= esc(c.getSubject()) %> — <%= esc(c.getBatch()) %>
                    </option>
                    <% } %>
                </select>
            </div>
            <button type="submit" class="materials-primary-btn">
                <i class="fa-solid fa-folder-open"></i> Open Materials
            </button>
        </form>
        <% } else { %>
        <div class="materials-empty">
            <div class="materials-empty-icon"><i class="fa-solid fa-book-open"></i></div>
            <h3>No classes assigned yet</h3>
            <p>Ask the administrator to assign a class to your tutor account first.</p>
        </div>
        <% } %>
    </section>

    <% if (selectedClass != null && classId != null) { %>
    <section class="materials-card">
        <div class="materials-card-header">
            <div>
                <span class="materials-section-label">New Material</span>
                <h2>Upload Class Material</h2>
                <p>Add notes, documents or other learning resources to <strong><%= esc(selectedClass.getSubject()) %> — <%= esc(selectedClass.getBatch()) %></strong>.</p>
            </div>
            <div class="materials-header-icon"><i class="fa-solid fa-cloud-arrow-up"></i></div>
        </div>

        <form action="<%= contextPath %>/tutor/materials" method="post" enctype="multipart/form-data" class="materials-form">
            <input type="hidden" name="action" value="upload">
            <input type="hidden" name="classId" value="<%= classId %>">

            <div class="materials-form-grid">
                <div class="materials-field">
                    <label for="title"><i class="fa-solid fa-heading"></i> Material Title</label>
                    <input type="text" id="title" name="title" maxlength="200" placeholder="e.g. Chapter 01 - Introduction" required>
                </div>

                <div class="materials-field materials-full-width">
                    <label for="description"><i class="fa-solid fa-align-left"></i> Description <span class="optional-badge">Optional</span></label>
                    <textarea id="description" name="description" maxlength="1000" rows="4" placeholder="Briefly describe this material..."></textarea>
                </div>

                <div class="materials-field materials-full-width">
                    <label for="file"><i class="fa-solid fa-paperclip"></i> Select File</label>
                    <div class="material-file-input">
                        <div class="file-icon"><i class="fa-solid fa-file-arrow-up"></i></div>
                        <div class="file-information">
                            <strong>Choose a file to upload</strong>
                            <span>Maximum upload size: 20 MB.</span>
                        </div>
                        <input type="file" id="file" name="file" required>
                    </div>
                </div>
            </div>

            <div class="materials-form-actions">
                <button type="submit" class="materials-primary-btn">
                    <i class="fa-solid fa-cloud-arrow-up"></i> Upload Material
                </button>
            </div>
        </form>
    </section>

    <section class="materials-card">
        <div class="materials-card-header">
            <div>
                <span class="materials-section-label">Material Library</span>
                <h2>Existing Materials</h2>
                <p>Edit titles/descriptions or delete resources for this class.</p>
            </div>
            <div class="materials-count">
                <i class="fa-solid fa-folder-open"></i>
                <span><%= materials != null ? materials.size() : 0 %> Materials</span>
            </div>
        </div>

        <div class="materials-table-wrapper">
            <table class="materials-table">
                <thead>
                <tr>
                    <th>Material Title</th>
                    <th>Description</th>
                    <th>Uploaded</th>
                    <th class="materials-actions-heading">Actions</th>
                </tr>
                </thead>
                <tbody>
                <% if (materials != null && !materials.isEmpty()) {
                    for (ClassMaterial m : materials) {
                        String editFormId = "edit-material-" + m.getMaterialId();
                %>
                <tr>
                    <td>
                        <input class="material-inline-input" type="text" name="title"
                               value="<%= esc(m.getTitle()) %>" maxlength="200" required form="<%= editFormId %>">
                        <span class="material-type">Class Material</span>
                    </td>
                    <td>
                        <textarea class="material-inline-textarea" name="description" maxlength="1000"
                                  rows="2" form="<%= editFormId %>"><%= esc(m.getDescription()) %></textarea>
                    </td>
                    <td>
                        <div class="uploaded-date">
                            <i class="fa-regular fa-clock"></i><span><%= esc(m.getUploadedAt()) %></span>
                        </div>
                    </td>
                    <td>
                        <div class="material-actions">
                            <form id="<%= editFormId %>" action="<%= contextPath %>/tutor/materials" method="post" enctype="multipart/form-data">
                                <input type="hidden" name="action" value="update">
                                <input type="hidden" name="classId" value="<%= classId %>">
                                <input type="hidden" name="materialId" value="<%= m.getMaterialId() %>">
                                <label style="display:block;font-size:12px;margin:6px 0 4px;">Replace File <span class="optional-badge">Optional</span></label>
                                <input type="file" name="file" style="max-width:180px;font-size:12px;margin-bottom:6px;">
                                <button type="submit" class="material-action-btn material-update-btn" title="Update Material">
                                    <i class="fa-solid fa-floppy-disk"></i>
                                </button>
                            <a href="<%= contextPath %>/materials/download?materialId=<%= m.getMaterialId() %>" class="material-action-btn" title="Download / Preview Material" target="_blank" style="display:inline-flex;align-items:center;justify-content:center;text-decoration:none;background:#f3f4f6;color:#374151;">
                                <i class="fa-solid fa-download"></i>
                            </a>

                            <form action="<%= contextPath %>/tutor/materials" method="post" class="material-delete-form"
                                  onsubmit="return confirm('Are you sure you want to delete this material?');">
                                <input type="hidden" name="action" value="delete">
                                <input type="hidden" name="classId" value="<%= classId %>">
                                <input type="hidden" name="materialId" value="<%= m.getMaterialId() %>">
                                <button type="submit" class="material-action-btn material-delete-btn" title="Delete Material">
                                    <i class="fa-solid fa-trash"></i>
                                </button>
                            </form>
                        </div>
                    </td>
                </tr>
                <%  }
                } else { %>
                <tr>
                    <td colspan="4">
                        <div class="materials-empty">
                            <div class="materials-empty-icon"><i class="fa-solid fa-folder-open"></i></div>
                            <h3>No materials uploaded</h3>
                            <p>Upload the first learning resource for this class using the form above.</p>
                        </div>
                    </td>
                </tr>
                <% } %>
                </tbody>
            </table>
        </div>
    </section>
    <% } %>
</main>
</body>
</html>
