CREATE OR REPLACE VIEW public.view_vk_diagnostic AS
-- This view is part of the Vertica Diagnostic Kit from http://git.io/q9m-fw
-- Queries returned < 1 sec
  (SELECT 'Queries returned < 1 sec' AS Description, 
          COUNT(*) AS Value 
   FROM   v_internal.dc_requests_issued ri 
          LEFT JOIN v_internal.dc_requests_completed rc USING (node_name, session_id, request_id) 
   WHERE  DATEDIFF('millisecond', ri.time, rc.time) <= 1000)
UNION ALL
-- Queries returned between 1 and 2 sec
  (SELECT 'Queries returned between 1 and 2 sec', 
          COUNT(*) 
   FROM   v_internal.dc_requests_issued ri 
          LEFT JOIN v_internal.dc_requests_completed rc USING (node_name, session_id, request_id) 
   WHERE  DATEDIFF('millisecond', ri.time, rc.time) BETWEEN 1001 AND 2000)
UNION ALL
-- Queries returned between 2 and 3 sec
  (SELECT 'Queries returned between 2 and 3 sec', 
          COUNT(*) 
   FROM   v_internal.dc_requests_issued ri 
          LEFT JOIN v_internal.dc_requests_completed rc USING (node_name, session_id, request_id) 
   WHERE  DATEDIFF('millisecond', ri.time, rc.time) BETWEEN 2001 AND 3000)
UNION ALL
-- Queries returned between 3 and 4 sec
  (SELECT 'Queries returned between 3 and 4 sec', 
          COUNT(*) 
   FROM   v_internal.dc_requests_issued ri 
          LEFT JOIN v_internal.dc_requests_completed rc USING (node_name, session_id, request_id) 
   WHERE  DATEDIFF('millisecond', ri.time, rc.time) BETWEEN 3001 AND 4000)
UNION ALL
-- Queries returned between 4 and 5 sec
  (SELECT 'Queries returned between 4 and 5 sec', 
          COUNT(*) 
   FROM   v_internal.dc_requests_issued ri 
          LEFT JOIN v_internal.dc_requests_completed rc USING (node_name, session_id, request_id) 
   WHERE  DATEDIFF('millisecond', ri.time, rc.time) BETWEEN 4001 AND 5000)
UNION ALL
-- Queries returned > 5 sec
  (SELECT 'Queries returned > 5 sec', 
          COUNT(*) 
   FROM   v_internal.dc_requests_issued ri 
          LEFT JOIN v_internal.dc_requests_completed rc USING (node_name, session_id, request_id) 
   WHERE  DATEDIFF('millisecond', ri.time, rc.time) > 5000)
UNION ALL
-- Query Events
  (SELECT 'Query Event: ' || INITCAP( CAST( REPLACE( event_type, '_', ' ' ) AS VARCHAR(100) ) ), 
          COUNT(*) 
   FROM   v_monitor.query_events 
   GROUP  BY event_type 
   ORDER  BY COUNT(*) DESC)
UNION ALL
-- Rejected Load Events
  (SELECT 'Rejected Load Events',
          COUNT(*) 
   FROM   v_internal.dc_load_events
   WHERE  rows_rejected <> 0)
UNION ALL
-- Tables Without Primary Keys
  (SELECT 'Tables Without Primary Keys',
          COUNT(DISTINCT t.table_name) 
          FROM   v_catalog.tables t 
          LEFT JOIN v_catalog.constraint_columns cc 
                 ON cc.table_id = t.table_id 
   WHERE  cc.constraint_type <> 'p' 
          AND t.is_system_table = 'f')
UNION ALL
-- Percent of Database Deleted
  (SELECT 'Percent of Database Deleted', 
         CAST( ROUND( (SELECT SUM(used_bytes) 
                       FROM   v_monitor.delete_vectors) / (SELECT SUM(ros_used_bytes) 
                                                           FROM   v_monitor.projection_storage) * 100) AS INT ) )
UNION ALL
-- Resource Rejections
  (SELECT 'Resource Rejection: ' || reason, 
          COUNT(*) 
   FROM   v_monitor.resource_rejection_details 
   GROUP  BY reason)
UNION ALL
-- Projections Without Refresh In Last 3 Months
  (SELECT 'Projections Without Refresh In Last 3 Months', 
          COUNT(*)
   FROM   v_catalog.projections p 
          LEFT JOIN v_monitor.projection_refreshes pr 
                 ON pr.projection_id = p.projection_id 
   WHERE  DATEDIFF(month, pr.refresh_start, SYSDATE()) >= 3 
           OR pr.projection_id IS NULL) 
UNION ALL
-- Projection Columns Without Refresh In Last 1 Month
  (SELECT 'Projection Columns Without Refresh In Last 1 Month', 
          COUNT(*) 
   FROM   v_catalog.projection_columns 
   WHERE  DATEDIFF(month, statistics_updated_timestamp, SYSDATE()) >= 1) 
UNION ALL
-- Projection Columns Without Full Statistics
  (SELECT 'Projection Columns Without Full Statistics', 
          COUNT(*)
   FROM   v_catalog.projections p 
          JOIN v_catalog.projection_columns pc 
            ON pc.projection_id = p.projection_id 
   WHERE  p.has_statistics = 'f' 
          AND pc.statistics_type IN ( 'NONE', 'ROWCOUNT' ));