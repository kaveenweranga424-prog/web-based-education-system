package filter;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

@WebFilter(urlPatterns = {
        "/dashboard",
        "/dashboard-admin.jsp",
        "/dashboard-tutor.jsp",
        "/dashboard-student.jsp",
        "/dashboard-parent.jsp"
})
public class AuthenticationFilter implements Filter {

    @Override
    public void doFilter(ServletRequest servletRequest,
                         ServletResponse servletResponse,
                         FilterChain chain) throws IOException, ServletException {

        HttpServletRequest request = (HttpServletRequest) servletRequest;
        HttpServletResponse response = (HttpServletResponse) servletResponse;
        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("userId") == null || session.getAttribute("userRole") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String uri = request.getRequestURI();
        if (uri.endsWith("/dashboard")) {
            chain.doFilter(request, response);
            return;
        }

        // Direct JSP requests would bypass DashboardServlet and therefore have no DB data.
        // Always route them through the controller.
        response.sendRedirect(request.getContextPath() + "/dashboard");
    }
}
