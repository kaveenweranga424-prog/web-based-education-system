package service;

import dao.DashboardDAO;

import java.sql.SQLException;
import java.util.Map;

/** Business boundary for role-specific dashboard reads. */
public class DashboardService {
    private final DashboardDAO dashboardDAO;

    public DashboardService() {
        this(new DashboardDAO());
    }

    DashboardService(DashboardDAO dashboardDAO) {
        this.dashboardDAO = dashboardDAO;
    }

    public Map<String, Object> getAdminDashboard() throws SQLException {
        return dashboardDAO.loadAdminDashboard();
    }

    public Map<String, Object> getTutorDashboard(int tutorId) throws SQLException {
        return dashboardDAO.loadTutorDashboard(tutorId);
    }

    public Map<String, Object> getStudentDashboard(int studentId) throws SQLException {
        return dashboardDAO.loadStudentDashboard(studentId);
    }

    public Map<String, Object> getParentDashboard(int parentId, Integer requestedStudentId) throws SQLException {
        return dashboardDAO.loadParentDashboard(parentId, requestedStudentId);
    }

    public Map<String, Object> getStaffDashboard(int staffId) throws SQLException {
        return dashboardDAO.loadStaffDashboard(staffId);
    }
}
