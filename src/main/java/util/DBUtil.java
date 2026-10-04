package util;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;

public class DBUtil {

    private static final String DATABASE_NAME =
            getConfig("DB_NAME", "TutionManegment");

    private static final String HOST =
            getConfig("DB_HOST", "127.0.0.1");

    private static final String PORT =
            getConfig("DB_PORT", "1433");

    // Local connection: encrypt=false avoids SSL negotiation latency on every connection
    private static final String SERVER_URL =
            "jdbc:sqlserver://" + HOST + ":" + PORT + ";" +
                    "databaseName=master;" +
                    "encrypt=false;" +
                    "trustServerCertificate=true;";

    private static final String DATABASE_URL =
            "jdbc:sqlserver://" + HOST + ":" + PORT + ";" +
                    "databaseName=" + DATABASE_NAME + ";" +
                    "encrypt=false;" +
                    "trustServerCertificate=true;";

    private static final String USER =
            getConfig("DB_USER", "sa");

    private static final String PASSWORD =
            getConfig("DB_PASSWORD", "123");

    private static final int MAX_POOL_SIZE = 20;
    private static final BlockingQueue<Connection> connectionPool = new ArrayBlockingQueue<>(MAX_POOL_SIZE);

    static {
        try {
            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        } catch (ClassNotFoundException e) {
            throw new RuntimeException("Failed to load SQL Server JDBC driver", e);
        }

        // Add shutdown hook to close all pooled physical connections
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            Connection conn;
            while ((conn = connectionPool.poll()) != null) {
                try {
                    conn.close();
                } catch (SQLException ignored) {
                }
            }
        }));
    }

    private static String getConfig(String key, String defaultValue) {
        String fromSystemProperty = System.getProperty(key);
        if (fromSystemProperty != null && !fromSystemProperty.isBlank()) {
            return fromSystemProperty;
        }

        String fromEnv = System.getenv(key);
        if (fromEnv != null && !fromEnv.isBlank()) {
            return fromEnv;
        }

        return defaultValue;
    }

    public static Connection getServerConnection() throws SQLException {
        try {
            return DriverManager.getConnection(SERVER_URL, USER, PASSWORD);
        } catch (SQLException e) {
            System.err.println(
                    "DBUtil: failed to connect to SQL Server at " + HOST + ":" + PORT +
                            " as user '" + USER + "'. Check that SQL Server is running, " +
                            "TCP/IP is enabled, and the username/password are correct."
            );
            throw e;
        }
    }

    /**
     * Obtains a connection from the pool or creates a new one.
     * Returned connections are proxied so that calling connection.close()
     * recycles the connection back into the pool instead of closing the physical socket.
     */
    public static Connection getConnection() throws SQLException {
        Connection physicalConn = null;

        while (!connectionPool.isEmpty()) {
            Connection candidate = connectionPool.poll();
            if (candidate != null) {
                try {
                    if (!candidate.isClosed() && candidate.isValid(1)) {
                        physicalConn = candidate;
                        break;
                    } else {
                        try { candidate.close(); } catch (SQLException ignored) {}
                    }
                } catch (SQLException e) {
                    try { candidate.close(); } catch (SQLException ignored) {}
                }
            }
        }

        if (physicalConn == null) {
            try {
                physicalConn = DriverManager.getConnection(DATABASE_URL, USER, PASSWORD);
            } catch (SQLException e) {
                System.err.println(
                        "DBUtil: failed to connect to database '" + DATABASE_NAME + "' at " +
                                HOST + ":" + PORT + " as user '" + USER + "'. " + e.getMessage()
                );
                throw e;
            }
        }

        return wrapConnection(physicalConn);
    }

    private static Connection wrapConnection(Connection physicalConn) {
        return (Connection) Proxy.newProxyInstance(
                DBUtil.class.getClassLoader(),
                new Class<?>[]{Connection.class},
                new PooledConnectionHandler(physicalConn)
        );
    }

    private static class PooledConnectionHandler implements InvocationHandler {
        private final Connection physicalConn;
        private boolean closed = false;

        PooledConnectionHandler(Connection physicalConn) {
            this.physicalConn = physicalConn;
        }

        @Override
        public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
            String methodName = method.getName();

            if ("close".equals(methodName)) {
                if (!closed) {
                    closed = true;
                    // Reset auto-commit state before returning to pool
                    try {
                        if (!physicalConn.isClosed()) {
                            if (!physicalConn.getAutoCommit()) {
                                physicalConn.rollback();
                                physicalConn.setAutoCommit(true);
                            }
                            if (!connectionPool.offer(physicalConn)) {
                                physicalConn.close();
                            }
                        }
                    } catch (SQLException e) {
                        try { physicalConn.close(); } catch (SQLException ignored) {}
                    }
                }
                return null;
            }

            if ("isClosed".equals(methodName)) {
                return closed || physicalConn.isClosed();
            }

            if (closed) {
                throw new SQLException("Connection is closed.");
            }

            return method.invoke(physicalConn, args);
        }
    }

    public static String getDatabaseName() {
        return DATABASE_NAME;
    }

    public static void main(String[] args) {
        System.out.println("Testing SQL Server connection...");

        try (Connection conn = getServerConnection()) {
            System.out.println("SQL Server connection successful!");
        } catch (SQLException e) {
            System.out.println("SQL Server connection failed!");
            e.printStackTrace();
        }
    }
}