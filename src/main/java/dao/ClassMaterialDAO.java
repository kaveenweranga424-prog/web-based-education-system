package dao;

import model.ClassMaterial;
import util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ClassMaterialDAO {
    public int addMaterial(ClassMaterial material)throws SQLException{
        String sql="INSERT INTO dbo.class_materials(class_id,title,description,file_path) VALUES(?,?,?,?)";
        try(Connection c=DBUtil.getConnection(); PreparedStatement s=c.prepareStatement(sql,Statement.RETURN_GENERATED_KEYS)){
            s.setInt(1,material.getClassId());s.setString(2,material.getTitle());s.setString(3,material.getDescription());s.setString(4,material.getFilePath());
            if(s.executeUpdate()>0){try(ResultSet k=s.getGeneratedKeys()){if(k.next())return k.getInt(1);}}
        }return -1;
    }
    public boolean updateMaterial(ClassMaterial m)throws SQLException{
        String sql="UPDATE dbo.class_materials SET title=?,description=?,file_path=? WHERE material_id=? AND class_id=?";
        try(Connection c=DBUtil.getConnection(); PreparedStatement s=c.prepareStatement(sql)){
            s.setString(1,m.getTitle());s.setString(2,m.getDescription());s.setString(3,m.getFilePath());s.setInt(4,m.getMaterialId());s.setInt(5,m.getClassId());
            return s.executeUpdate()>0;
        }
    }
    public boolean deleteMaterial(int id)throws SQLException{
        try(Connection c=DBUtil.getConnection();PreparedStatement s=c.prepareStatement("DELETE FROM dbo.class_materials WHERE material_id=?")){
            s.setInt(1,id);return s.executeUpdate()>0;
        }
    }
    public ClassMaterial findById(int id)throws SQLException{
        try(Connection c=DBUtil.getConnection();PreparedStatement s=c.prepareStatement("SELECT * FROM dbo.class_materials WHERE material_id=?")){
            s.setInt(1,id);try(ResultSet r=s.executeQuery()){return r.next()?map(r):null;}
        }
    }
    public List<ClassMaterial> findByClass(int classId)throws SQLException{
        List<ClassMaterial> out=new ArrayList<>();
        try(Connection c=DBUtil.getConnection();PreparedStatement s=c.prepareStatement("SELECT * FROM dbo.class_materials WHERE class_id=? ORDER BY uploaded_at DESC")){
            s.setInt(1,classId);try(ResultSet r=s.executeQuery()){while(r.next())out.add(map(r));}
        }return out;
    }
    private ClassMaterial map(ResultSet r)throws SQLException{
        ClassMaterial m=new ClassMaterial();m.setMaterialId(r.getInt("material_id"));m.setClassId(r.getInt("class_id"));
        m.setTitle(r.getString("title"));m.setDescription(r.getString("description"));m.setFilePath(r.getString("file_path"));m.setUploadedAt(r.getTimestamp("uploaded_at"));return m;
    }
}
