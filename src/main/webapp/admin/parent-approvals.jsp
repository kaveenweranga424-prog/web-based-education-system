<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%!
    private String h(Object val) {
        if (val == null) return "";
        return String.valueOf(val).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
    String contextPath = request.getContextPath();
    List<Map<String, Object>> pendingLinks = (List<Map<String, Object>>) request.getAttribute("pendingLinks");
    String errorMessage = request.getAttribute("errorMessage") != null ? String.valueOf(request.getAttribute("errorMessage")) : "";
    boolean updatedSuccess = "true".equals(request.getParameter("updated"));
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Parent Approvals | Classora Admin</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@500;600;700;800&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/dashboard.css">
    <link rel="stylesheet" href="<%= contextPath %>/css/class-pages.css">
    <style>
        .approval-shell { max-width: 1100px; margin: 32px auto; padding: 0 20px; }
        .approval-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 24px; flex-wrap: wrap; gap: 16px; }
        .approval-card { background: #fff; border: 1px solid #e8e8e8; border-radius: 16px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,.04); }
        .table-wrap { overflow-x: auto; }
        .data-table { width: 100%; border-collapse: collapse; text-align: left; font-size: 13.5px; }
        .data-table th { background: #f9fafb; padding: 14px 16px; border-bottom: 1px solid #e5e7eb; color: #4b5563; font-weight: 600; }
        .data-table td { padding: 14px 16px; border-bottom: 1px solid #f3f4f6; vertical-align: middle; }
        .btn-action-sm { display: inline-flex; align-items: center; gap: 6px; padding: 7px 14px; border-radius: 8px; font-size: 12.5px; font-weight: 600; border: none; cursor: pointer; transition: all .2s; }
        .btn-approve { background: #16a34a; color: #fff; }
        .btn-approve:hover { background: #15803d; }
        .btn-reject { background: #ef4444; color: #fff; }
        .btn-reject:hover { background: #dc2626; }
        .alert-box { padding: 14px 18px; border-radius: 12px; margin-bottom: 20px; font-size: 14px; display: flex; align-items: center; gap: 10px; }
        .alert-success { background: #dcfce7; color: #166534; border: 1px solid #bbf7d0; }
        .alert-error { background: #fee2e2; color: #991b1b; border: 1px solid #fecaca; }
        .empty-state { padding: 48px 24px; text-align: center; color: #737373; }
        .empty-state i { font-size: 40px; color: #d4d4d4; margin-bottom: 12px; }
    </style>
</head>
<body class="dash-body">

<header class="class-page-header">
    <a class="class-brand" href="<%= contextPath %>/dashboard">
        <span class="class-brand-mark">C</span>
        <span class="class-brand-copy">
            <span class="class-brand-title">Classora</span>
            <span class="class-brand-subtitle">Administrator Portal</span>
        </span>
    </a>
    <div class="class-header-actions">
        <a class="class-nav-link" href="<%= contextPath %>/dashboard"><i class="fa-solid fa-arrow-left"></i> Dashboard</a>
    </div>
</header>

<main class="approval-shell">
    <div class="approval-header">
        <div>
            <h1 style="font-family:'Plus Jakarta Sans',sans-serif;font-size:24px;font-weight:700;">Parent Account Approvals</h1>
            <p style="font-size:14px;color:#737373;margin-top:4px;">Verify and approve parent requests linking to registered students.</p>
        </div>
        <div>
            <a href="<%= contextPath %>/dashboard" class="btn-solid sm" style="text-decoration:none;"><i class="fa-solid fa-gauge"></i> Admin Dashboard</a>
        </div>
    </div>

    <% if (updatedSuccess) { %>
        <div class="alert-box alert-success">
            <i class="fa-solid fa-circle-check"></i>
            <span>Parent request has been processed and notification sent.</span>
        </div>
    <% } %>

    <% if (!errorMessage.isEmpty()) { %>
        <div class="alert-box alert-error">
            <i class="fa-solid fa-circle-exclamation"></i>
            <span><%= h(errorMessage) %></span>
        </div>
    <% } %>

    <div class="approval-card">
        <% if (pendingLinks == null || pendingLinks.isEmpty()) { %>
            <div class="empty-state">
                <i class="fa-regular fa-circle-check"></i>
                <h3 style="font-size:16px;color:#171717;margin-bottom:6px;">No Pending Parent Requests</h3>
                <p style="font-size:13.5px;">All parent registration requests have been reviewed and approved.</p>
            </div>
        <% } else { %>
            <div class="table-wrap">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Parent Details</th>
                            <th>Target Student</th>
                            <th>Relationship</th>
                            <th>Requested On</th>
                            <th style="text-align:right;">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                    <% for (Map<String, Object> r : pendingLinks) { %>
                        <tr>
                            <td>
                                <strong style="color:#171717;"><%= h(r.get("parentName")) %></strong><br>
                                <span style="font-size:12px;color:#737373;"><i class="fa-regular fa-envelope"></i> <%= h(r.get("parentEmail")) %></span>
                                <% if (r.get("parentPhone") != null) { %>
                                    <br><span style="font-size:12px;color:#737373;"><i class="fa-solid fa-phone"></i> <%= h(r.get("parentPhone")) %></span>
                                <% } %>
                            </td>
                            <td>
                                <strong style="color:#171717;"><%= h(r.get("studentName")) %></strong><br>
                                <span style="font-size:12px;color:#737373;"><i class="fa-regular fa-envelope"></i> <%= h(r.get("studentEmail")) %></span>
                            </td>
                            <td>
                                <span class="badge badge-neutral"><%= h(r.get("relationship")) %></span>
                            </td>
                            <td style="font-size:12px;color:#737373;">
                                <%= r.get("createdAt") != null ? r.get("createdAt").toString().substring(0, 16) : "" %>
                            </td>
                            <td style="text-align:right;white-space:nowrap;">
                                <form action="<%= contextPath %>/admin/parent-approvals" method="post" style="display:inline;">
                                    <input type="hidden" name="parentStudentId" value="<%= r.get("parentStudentId") %>">
                                    <input type="hidden" name="action" value="approve">
                                    <button type="submit" class="btn-action-sm btn-approve" title="Approve Link">
                                        <i class="fa-solid fa-check"></i> Approve
                                    </button>
                                </form>
                                <form action="<%= contextPath %>/admin/parent-approvals" method="post" style="display:inline;" onsubmit="return confirm('Decline this parent linking request?');">
                                    <input type="hidden" name="parentStudentId" value="<%= r.get("parentStudentId") %>">
                                    <input type="hidden" name="action" value="reject">
                                    <button type="submit" class="btn-action-sm btn-reject" title="Reject Link">
                                        <i class="fa-solid fa-xmark"></i> Reject
                                    </button>
                                </form>
                            </td>
                        </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
        <% } %>
    </div>
</main>

</body>
</html>
