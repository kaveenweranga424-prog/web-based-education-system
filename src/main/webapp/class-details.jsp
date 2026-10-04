<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.Class" %>
<%@ page import="model.ClassMaterial" %>
<%@ page import="model.Enrollment" %>
<%@ page import="model.TimetableSlot" %>
<%@ page import="java.util.List" %>
<%!
  private String h(Object value){
    if(value==null)return "";
    return String.valueOf(value).replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
  }
  private String formatTime(String t) {
    if (t == null || t.isBlank()) return "";
    try {
      String[] parts = t.trim().split(":");
      int h = Integer.parseInt(parts[0]);
      int m = parts.length > 1 ? Integer.parseInt(parts[1]) : 0;
      String ampm = h >= 12 ? "PM" : "AM";
      int h12 = h % 12;
      if (h12 == 0) h12 = 12;
      return String.format("%02d:%02d %s", h12, m, ampm);
    } catch (Exception e) {
      return t;
    }
  }
  private String formatDay(String d) {
    if (d == null) return "";
    switch (d.trim().toUpperCase()) {
      case "MON": return "Monday";
      case "TUE": return "Tuesday";
      case "WED": return "Wednesday";
      case "THU": return "Thursday";
      case "FRI": return "Friday";
      case "SAT": return "Saturday";
      case "SUN": return "Sunday";
      default: return d;
    }
  }
  private String getCourseImage(Object imagePathObj, Object subjectObj, String contextPath) {
    if (imagePathObj != null && !String.valueOf(imagePathObj).isBlank()) {
      return contextPath + "/" + String.valueOf(imagePathObj).trim();
    }
    if (subjectObj == null) return contextPath + "/images/courses/default.jpg";
    String s = String.valueOf(subjectObj).toLowerCase().trim();
    if (s.contains("math") || s.contains("ganithaya")) return contextPath + "/images/courses/maths.jpg";
    if (s.contains("sci") || s.contains("vidyawa") || s.contains("physics") || s.contains("chem") || s.contains("bio")) return contextPath + "/images/courses/science.jpg";
    if (s.contains("it") || s.contains("comp") || s.contains("tech") || s.contains("ai") || s.contains("prog") || s.contains("soft")) return contextPath + "/images/courses/it.jpg";
    if (s.contains("eng") || s.contains("lit") || s.contains("lang")) return contextPath + "/images/courses/english.jpg";
    return contextPath + "/images/courses/default.jpg";
  }
  private String getCourseImage(Object subjectObj, String contextPath) {
    return getCourseImage(null, subjectObj, contextPath);
  }
%>
<%
  String contextPath=request.getContextPath();
  Class classItem=(Class)request.getAttribute("classItem");
  List<ClassMaterial> materials=(List<ClassMaterial>)request.getAttribute("materials");
  List<TimetableSlot> timetableSlots=(List<TimetableSlot>)request.getAttribute("timetableSlots");
  Enrollment enrollment=(Enrollment)request.getAttribute("enrollmentRequest");
  Boolean canView=(Boolean)request.getAttribute("canViewMaterials");
  String errorMessage=request.getAttribute("errorMessage")!=null?request.getAttribute("errorMessage").toString():"";
  Object flash=session.getAttribute("flashError");
  if(flash!=null){ errorMessage=String.valueOf(flash); session.removeAttribute("flashError"); }
  String role=String.valueOf(session.getAttribute("userRole"));
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><%=classItem!=null?h(classItem.getSubject()):"Class"%> | Classora</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Plus+Jakarta+Sans:wght@600;700;800&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
  <link rel="stylesheet" href="<%=contextPath%>/css/class-pages.css">
</head>
<body class="class-page-body">
<header class="class-page-header">
  <a class="class-brand" href="<%=contextPath%>/dashboard">
    <span class="class-brand-mark">C</span>
    <span class="class-brand-copy">
      <span class="class-brand-title">Classora</span>
      <span class="class-brand-subtitle">Student Portal</span>
    </span>
  </a>
  <div class="class-header-actions">
    <a class="class-nav-link" href="<%=contextPath%>/classes"><i class="fa-solid fa-arrow-left"></i> Classes</a>
    <a class="class-nav-link" href="<%=contextPath%>/dashboard"><i class="fa-solid fa-gauge"></i> Dashboard</a>
  </div>
</header>

<main class="class-page-shell">
  <% if(!errorMessage.isEmpty()){ %>
    <div class="class-notice"><i class="fa-solid fa-circle-exclamation"></i> <%=h(errorMessage)%></div>
  <% } %>

  <a href="<%=contextPath%>/dashboard" style="display:inline-flex;align-items:center;gap:8px;font-size:13.5px;font-weight:600;color:#7c3aed;text-decoration:none;margin-bottom:18px;">
    <i class="fa-solid fa-arrow-left"></i> Back to Dashboard
  </a>

  <% if(classItem!=null){ %>
  <section class="class-detail-card">
    <div style="width:100%;height:clamp(290px, 35vw, 420px);overflow:hidden;border-radius:18px 18px 0 0;position:relative;background:#090d16;">
      <!-- Ambient blurred backdrop to fill entire frame with matching atmospheric colors -->
      <div style="position:absolute;inset:-20px;background-image:url('<%=getCourseImage(classItem.getImagePath(), classItem.getSubject(), contextPath)%>');background-size:cover;background-position:center;filter:blur(28px) brightness(0.5);transform:scale(1.15);"></div>
      <!-- Center contained banner so NO text or graphic is cropped -->
      <img src="<%=getCourseImage(classItem.getImagePath(), classItem.getSubject(), contextPath)%>" style="position:relative;width:100%;height:100%;object-fit:contain;object-position:center;z-index:1;" alt="<%=h(classItem.getSubject())%>">
      <div style="position:absolute;inset:0;background:linear-gradient(to top, rgba(15,23,42,0.85) 0%, rgba(15,23,42,0.15) 35%, transparent 70%);z-index:2;pointer-events:none;"></div>
      <div style="position:absolute;bottom:16px;left:24px;display:flex;align-items:center;gap:10px;z-index:3;flex-wrap:wrap;">
        <span style="background:rgba(124,58,237,0.92);backdrop-filter:blur(6px);color:#fff;padding:5px 14px;border-radius:6px;font-size:12px;font-weight:700;letter-spacing:0.03em;"><%=h(classItem.getBatch())%></span>
        <% if (classItem.isWeekend()) { %>
        <span style="background:rgba(217,119,6,0.92);backdrop-filter:blur(6px);color:#fff;padding:5px 12px;border-radius:6px;font-size:12px;font-weight:700;"><i class="fa-solid fa-mug-hot"></i> Weekend</span>
        <% } else { %>
        <span style="background:rgba(37,99,235,0.92);backdrop-filter:blur(6px);color:#fff;padding:5px 12px;border-radius:6px;font-size:12px;font-weight:700;"><i class="fa-solid fa-calendar-day"></i> Weekday</span>
        <% } %>
        <span style="background:rgba(15,23,42,0.85);backdrop-filter:blur(6px);color:#fff;padding:5px 12px;border-radius:6px;font-size:12px;font-weight:600;"><i class="fa-solid fa-chalkboard-user"></i> <%=classItem.getTutorName()!=null?h(classItem.getTutorName()):"Tutor"%></span>
      </div>
    </div>
    <div class="class-detail-head">
      <div>
        <span class="class-page-kicker"><i class="fa-solid fa-book-open"></i> Class Details</span>
        <h1 class="class-detail-title"><%=h(classItem.getSubject())%> — <%=h(classItem.getBatch())%></h1>
        <div class="class-detail-meta">
          <span><i class="fa-solid fa-chalkboard-user"></i> <%=classItem.getTutorName()!=null?h(classItem.getTutorName()):"Not assigned"%></span>
          <span><i class="fa-solid fa-layer-group"></i> <%=h(classItem.getBatch())%></span>
          <span><i class="fa-solid fa-calendar-days"></i> <%=classItem.getClassTypeDisplay()%> Schedule</span>
        </div>
      </div>
      <div class="class-fee-box">
        <span>Class Fee</span>
        <strong>Rs. <%=h(classItem.getFee())%></strong>
      </div>
    </div>

    <% if("STUDENT".equalsIgnoreCase(role)){ %>
      <% if(enrollment==null){ %>
        <div class="class-enrollment-panel">
          <div class="class-enrollment-copy">
            <strong>Ready to join this class?</strong>
            <p>Pay the class fee via bank transfer or deposit and upload your slip for Admin approval.</p>
          </div>
          <form action="<%=contextPath%>/enroll" method="post">
            <input type="hidden" name="classId" value="<%=classItem.getClassId()%>">
            <button class="class-primary-btn" type="submit"><i class="fa-solid fa-receipt"></i> Pay &amp; Request to Join</button>
          </form>
        </div>
      <% } else {
           String s=enrollment.getStatus();
           String label=s;
           String statusClass="";
           if("PENDING_PAYMENT".equals(s)){ label="Pending Payment"; statusClass="is-waiting"; }
           else if("PAID_PENDING_ADMIN".equals(s) || "PAID_PENDING_STAFF".equals(s) || "STAFF_CONFIRMED".equals(s)){ label="Waiting for Admin Approval"; statusClass="is-waiting"; }
           else if("ACTIVE".equals(s)){ label="Active"; statusClass="is-active"; }
           else if("REJECTED".equals(s)){ label="Rejected"; statusClass="is-rejected"; }
           else if("CANCELLED".equals(s)){ label="Cancelled"; statusClass="is-rejected"; }
      %>
        <div class="class-enrollment-panel">
          <div class="class-enrollment-copy">
            <strong>Enrollment Status</strong>
            <span class="class-status <%=statusClass%>"><i class="fa-solid fa-circle"></i> <%=h(label)%></span>
          </div>
          <% if("PENDING_PAYMENT".equals(s)){ %>
            <a class="class-action-btn" href="<%=contextPath%>/student/payment?enrollmentId=<%=enrollment.getEnrollmentId()%>">
              <i class="fa-solid fa-cloud-arrow-up"></i> Upload Bank Slip
            </a>
          <% } %>
        </div>
      <% } %>
    <% } %>

    <!-- Live Online Class & Schedule Section -->
    <div class="class-live-session" style="background:#ffffff;border:1.5px solid <%=classItem.hasMeetingLink() ? "#bfdbfe" : "#e2e8f0"%>;border-radius:16px;padding:22px 24px;margin-bottom:24px;box-shadow:0 2px 10px rgba(0,0,0,0.04);">
      <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:16px;">
        <div style="display:flex;align-items:flex-start;gap:14px;flex:1;min-width:280px;">
          <div style="width:50px;height:50px;border-radius:14px;background:<%=classItem.hasMeetingLink() ? "#dbeafe" : "#f1f5f9"%>;color:<%=classItem.hasMeetingLink() ? "#2563eb" : "#64748b"%>;display:inline-flex;align-items:center;justify-content:center;font-size:22px;flex-shrink:0;">
            <i class="fa-solid fa-video"></i>
          </div>
          <div style="flex:1;">
            <div style="display:flex;align-items:center;gap:10px;flex-wrap:wrap;margin-bottom:4px;">
              <h2 style="font-size:17.5px;font-weight:800;color:#0f172a;margin:0;">
                Live Online Class
              </h2>
              <% if(classItem.hasMeetingLink()){ %>
                <span style="background:#dcfce7;color:#15803d;font-size:11.5px;font-weight:700;padding:3px 10px;border-radius:12px;display:inline-flex;align-items:center;gap:5px;">
                  <i class="fa-solid fa-circle" style="font-size:7px;"></i> Link Ready
                </span>
              <% } else { %>
                <span style="background:#f1f5f9;color:#64748b;font-size:11.5px;font-weight:600;padding:3px 10px;border-radius:12px;display:inline-flex;align-items:center;gap:5px;">
                  <i class="fa-regular fa-clock" style="font-size:11px;"></i> Link Pending
                </span>
              <% } %>
            </div>

            <p style="font-size:13px;color:#64748b;margin:0 0 10px 0;line-height:1.5;">
              <% if(Boolean.TRUE.equals(canView)){ %>
                <% if(classItem.hasMeetingLink()){ %>
                  Join your tutor's live online lecture session directly using the link below.
                <% } else { %>
                  No live meeting link has been shared yet. Your tutor will share it here before the scheduled class time.
                <% } %>
              <% } else { %>
                Live meeting link is protected and available only to confirmed enrolled students.
              <% } %>
            </p>

            <!-- Class Time & Schedule Badges -->
            <div style="display:flex;align-items:center;gap:10px;flex-wrap:wrap;">
              <% if(timetableSlots != null && !timetableSlots.isEmpty()){ 
                   for(TimetableSlot slot : timetableSlots){ %>
                     <div style="background:#eff6ff;border:1px solid #bfdbfe;color:#1e40af;padding:6px 14px;border-radius:10px;font-size:13px;font-weight:700;display:inline-flex;align-items:center;gap:8px;">
                       <i class="fa-solid fa-calendar-day" style="color:#2563eb;font-size:13px;"></i>
                       <span><%=formatDay(slot.getDayOfWeek())%></span>
                       <span style="color:#93c5fd;">&bull;</span>
                       <i class="fa-regular fa-clock" style="color:#2563eb;font-size:13px;"></i>
                       <span><%=formatTime(slot.getStartTime())%> &ndash; <%=formatTime(slot.getEndTime())%></span>
                     </div>
              <%   }
                 } else { %>
                     <div style="background:#f8fafc;border:1px solid #e2e8f0;color:#334155;padding:6px 14px;border-radius:10px;font-size:13px;font-weight:600;display:inline-flex;align-items:center;gap:8px;">
                       <i class="fa-solid fa-calendar-days" style="color:#64748b;font-size:13px;"></i>
                       <span><%=classItem.getClassTypeDisplay()%> Schedule</span>
                       <span style="color:#cbd5e1;">&bull;</span>
                       <i class="fa-regular fa-clock" style="color:#64748b;font-size:13px;"></i>
                       <span>Timetable to be announced</span>
                     </div>
              <% } %>
            </div>
          </div>
        </div>

        <div style="display:flex;align-items:center;gap:10px;flex-shrink:0;">
          <% if(Boolean.TRUE.equals(canView)){ %>
            <% if(classItem.hasMeetingLink()){ %>
              <a href="<%=h(classItem.getMeetingLink())%>" target="_blank" rel="noopener noreferrer" class="class-primary-btn" style="background:linear-gradient(135deg, #2563eb, #1d4ed8);padding:11px 22px;font-size:14px;font-weight:700;display:inline-flex;align-items:center;gap:8px;text-decoration:none;border-radius:10px;box-shadow:0 4px 14px rgba(37,99,235,0.35);color:#fff;">
                <i class="fa-solid fa-video"></i> Join Live Class Now <i class="fa-solid fa-arrow-up-right-from-square" style="font-size:11px;"></i>
              </a>
            <% } else { %>
              <span style="font-size:13px;color:#64748b;background:#f8fafc;border:1px solid #e2e8f0;padding:9px 16px;border-radius:10px;font-weight:600;display:inline-flex;align-items:center;gap:7px;">
                <i class="fa-regular fa-clock" style="color:#94a3b8;"></i> Awaiting Tutor Link
              </span>
            <% } %>
          <% } else { %>
            <span style="font-size:13px;color:#b45309;background:#fef3c7;border:1px solid #fde68a;padding:8px 16px;border-radius:10px;font-weight:700;display:inline-flex;align-items:center;gap:6px;">
              <i class="fa-solid fa-lock"></i> Enrollment Required
            </span>
          <% } %>
        </div>
      </div>
    </div>

    <div class="class-materials">
      <div class="class-section-head" style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:10px;margin-bottom:18px;">
        <div>
          <h2 style="display:flex;align-items:center;gap:8px;font-size:18px;margin:0 0 4px 0;"><i class="fa-solid fa-folder-open" style="color:#7c3aed;"></i> Class Study Materials &amp; Notes</h2>
          <p style="font-size:13px;color:#6b7280;margin:0;">Download lecture materials, slides, and notes uploaded for this class.</p>
        </div>
        <% if(materials!=null && !materials.isEmpty()){ %>
          <span style="background:#f3e8ff;color:#6b21a8;padding:5px 12px;border-radius:20px;font-size:12px;font-weight:700;"><%=materials.size()%> File<%=materials.size()==1?"":"s"%> Available</span>
        <% } %>
      </div>

      <% if(Boolean.TRUE.equals(canView)){ %>
        <% if(materials!=null && !materials.isEmpty()){ %>
          <div class="class-material-list">
          <% for(ClassMaterial m:materials){ %>
            <div class="class-material-item" style="display: flex; justify-content: space-between; align-items: center; padding: 14px 18px; border: 1px solid #f3f4f6; border-radius: 12px; margin-bottom: 12px; background: #fff;">
              <div style="display: flex; align-items: center; gap: 14px;">
                <span class="class-material-icon" style="width: 42px; height: 42px; border-radius: 10px; background: #f5f3ff; color: #7c3aed; display: inline-flex; align-items: center; justify-content: center; font-size: 18px;"><i class="fa-regular fa-file-lines"></i></span>
                <div>
                  <span class="class-material-title" style="font-size: 14.5px; font-weight: 700; color: #111827; display: block;"><%=h(m.getTitle())%></span>
                  <% if(m.getDescription()!=null && !m.getDescription().isBlank()){ %>
                    <span class="class-material-description" style="font-size: 13px; color: #4b5563; margin-top: 2px; display: block;"><%=h(m.getDescription())%></span>
                  <% } %>
                  <span style="font-size: 11.5px; color: #9ca3af; margin-top: 4px; display: block;">
                    <i class="fa-regular fa-clock"></i> Uploaded: <%=m.getUploadedAt()!=null?h(m.getUploadedAt()):"Recently"%>
                  </span>
                </div>
              </div>
              <a href="<%=contextPath%>/materials/download?materialId=<%=m.getMaterialId()%>" class="class-primary-btn" style="padding: 8px 16px; font-size: 13px; text-decoration: none; white-space: nowrap; display: inline-flex; align-items: center; gap: 6px;">
                <i class="fa-solid fa-download"></i> Download
              </a>
            </div>
          <% } %>
          </div>
        <% } else { %>
          <div class="class-lock-state" style="padding: 32px 20px; text-align: center; color: #6b7280;">
            <i class="fa-regular fa-folder-open" style="font-size: 30px; color: #9ca3af; margin-bottom: 8px; display: block;"></i>
            <strong style="display: block; font-size: 15px; color: #374151; margin-bottom: 4px;">No study materials uploaded yet</strong>
            <span>Your tutor has not uploaded any study materials for this class yet.</span>
          </div>
        <% } %>
      <% } else { %>
        <div class="class-lock-state" style="padding: 32px 20px; text-align: center; color: #6b7280;">
          <i class="fa-solid fa-lock" style="font-size: 30px; color: #d97706; margin-bottom: 8px; display: block;"></i>
          <strong style="display: block; font-size: 15px; color: #374151; margin-bottom: 4px;">Materials Locked</strong>
          <span>Study materials and lecture notes become available after your class enrollment is approved.</span>
        </div>
      <% } %>
    </div>
  </section>
  <% } else { %>
    <section class="class-detail-card">
      <div class="class-empty-state"><i class="fa-solid fa-triangle-exclamation"></i><strong>Class not found</strong><span>The requested class could not be loaded.</span></div>
    </section>
  <% } %>
</main>
</body>
</html>
