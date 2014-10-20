CREATE OR REPLACE VIEW public.view_vk_resource AS
-- This view is part of the Vertica Diagnostic Kit from http://git.io/q9m-fw
-- Disk Space Utilization
  (SELECT 'Disk Space Utilization' AS Resource, 
          host_name AS Node, 
          CAST( ROUND( disk_space_used_mb / 1024, 2 ) AS FLOAT(3) ) AS 'Used (GB)', 
          CAST( ROUND( disk_space_free_mb / 1024, 2 ) AS FLOAT(3) ) AS 'Free (GB)', 
          CAST( ROUND( disk_space_total_mb / 1024, 2 ) AS FLOAT(3) ) AS 'Total (GB)' 
   FROM   v_monitor.host_resources 
   ORDER  BY host_name) 
UNION ALL
-- Memory Information
  (SELECT 'Memory Information', 
          host_name, 
          CAST( ROUND( ( total_memory_bytes - total_memory_free_bytes ) / ( 1024^3 ), 2 ) AS FLOAT(3) ), 
          CAST( ROUND( total_memory_free_bytes / ( 1024^3 ), 2 ) AS FLOAT(3) ), 
          CAST( ROUND( total_memory_bytes / ( 1024^3 ), 2 ) AS FLOAT(3) ) 
   FROM   v_monitor.host_resources
   ORDER  BY host_name)
UNION ALL
-- Nodes Exceeding Used Space Limit
  (SELECT 'Critical Space Usage', 
          node_name, 
          CAST( ROUND( disk_space_free_mb / 1024, 2 ) AS FLOAT(3) ), 
          CAST( ROUND( disk_space_used_mb / 1024, 2 ) AS FLOAT(3) ), 
          CAST( ROUND( ( disk_space_free_mb + disk_space_used_mb ) / 1024, 2 ) AS FLOAT(3) ) 
   FROM   v_monitor.disk_storage 
   WHERE  disk_space_free_mb / ( disk_space_used_mb + disk_space_free_mb ) <= 0.4 
          AND storage_usage = 'DATA,TEMP');
