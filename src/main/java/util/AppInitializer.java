package util;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;

@WebListener
public class AppInitializer
        implements ServletContextListener {

    @Override
    public void contextInitialized(
            ServletContextEvent sce
    ) {

        System.out.println(
                "======================================"
        );

        System.out.println(
                "Tution Management System Starting..."
        );

        System.out.println(
                "======================================"
        );

        try {

            DatabaseInitializer.initializeDatabase();

            System.out.println(
                    "Database initialization successful!"
            );

        } catch (Exception e) {

            System.out.println(
                    "Database initialization failed!"
            );

            e.printStackTrace();
        }

        System.out.println(
                "======================================"
        );
    }

    @Override
    public void contextDestroyed(
            ServletContextEvent sce
    ) {

        System.out.println(
                "Tution Management System Stopped."
        );
    }
}