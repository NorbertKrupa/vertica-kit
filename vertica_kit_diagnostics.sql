-- Vertica Diagnostic Information Queries
-- April 2015
--
-- Last Modified: April 14, 2015
-- http://www.vertica.tips
-- Twitter: verticatips
--
-- Written by Norbert Krupa
--
-- For more scripts and sample code, check out 
--     http://jadito.us/vertica-kit
--     http://vertica.tips
--
-- Vertica Kit is free: you can redistribute it and/or modify it under
-- the terms of the GNU General Public License as published by the Free
-- Software Foundation, either version 3 of the License, or (at your 
-- option) any later version.
--
-- Vertica Kit is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
-- General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with Vertica Kit.  If not, see <http://www.gnu.org/licenses/>.
--
-- Note: These queries should be run from within vsql.

--*************************************************************************
--  Configuration Information
--*************************************************************************

-- Your product version
SELECT version();

-- Your license and compliance status
-- http://j.mp/vertica-view-license-status
-- http://j.mp/vertica-get-compliance-status
SELECT DISPLAY_LICENSE();
SELECT GET_COMPLIANCE_STATUS();

-- Is the Data Collector enabled (for monitoring)
-- http://j.mp/vertica-retaining-monitoring-information
SELECT GET_CONFIG_PARAMETER('EnableDataCollector');

-- Configuration parameters that have been modified
-- http://j.mp/vertica-configuration-parameters
SELECT /*+label(diag_changed_config_param)*/ 
       * 
FROM   v_monitor.configuration_parameters 
WHERE  current_value <> default_value; 

-- Shows change history of configuration parameters
-- http://j.mp/vertica-configuration-changes
SELECT /*+label(diag_config_param_history)*/ 
       * 
FROM   v_monitor.configuration_changes 
ORDER  BY event_timestamp DESC; 

-- Shows current fault tolerance of the system by returning K-safety 
-- level and number of node failures before automatic shut down
-- http://j.mp/vertica-v_monitor-system
SELECT /*+label(diag_fault_tolerance)*/ 
       designed_fault_tolerance, 
       current_fault_tolerance 
FROM   v_monitor.system;

--*************************************************************************
--  Resource Information
--*************************************************************************

-- Shows disk space utilization by host (see below for alternate methods)
-- http://wp.me/p4EqBZ-2O
SELECT /*+label(diag_disk_space_utilization)*/ 
       host_name, 
       ( disk_space_free_mb / 1024 )  AS disk_space_free_gb, 
       ( disk_space_used_mb / 1024 )  AS disk_space_used_gb, 
       ( disk_space_total_mb / 1024 ) AS disk_space_total_gb 
FROM   v_monitor.host_resources;

-- Shows processor information by host
SELECT /*+label(diag_cpu_info)*/ 
       host_name, 
       processor_count, 
       processor_core_count, 
       processor_description 
FROM   v_monitor.host_resources;

-- Shows memory information by host
SELECT /*+label(diag_memory_info)*/ 
       host_name, 
       total_memory_bytes / ( 1024^3 )           AS total_memory_gb, 
       total_memory_free_bytes / ( 1024^3 )      AS total_memory_free_gb, 
       total_swap_memory_bytes / ( 1024^3 )      AS total_swap_memory_gb, 
       total_swap_memory_free_bytes / ( 1024^3 ) AS total_swap_memory_free_gb 
FROM   v_monitor.host_resources;

-- Shows compressed and raw estimate data space utilization by schema
-- http://wp.me/p4EqBZ-33
SELECT /*+label(diag_schema_space_utilization)*/ 
       pj.anchor_table_schema, 
       pj.used_compressed_gb, 
       pj.used_compressed_gb * la.ratio AS raw_estimate_gb 
FROM   (SELECT ps.anchor_table_schema, 
               SUM(used_bytes) / ( 1024^3 ) AS used_compressed_gb 
        FROM   v_catalog.projections p 
               JOIN v_monitor.projection_storage ps 
                 ON ps.projection_id = p.projection_id 
        WHERE  p.is_super_projection = 't' 
        GROUP  BY ps.anchor_table_schema) pj 
       CROSS JOIN (SELECT (SELECT database_size_bytes 
                           FROM   v_catalog.license_audits 
                           ORDER  BY audit_start_timestamp DESC 
                           LIMIT  1) / (SELECT SUM(used_bytes) 
                                        FROM   v_monitor.projection_storage) AS ratio) la 
ORDER  BY pj.used_compressed_gb DESC; 

-- Shows nodes that have less than the recommended disk space (40%) available for use
-- http://goo.gl/I4kCmk
SELECT /*+label(diag_critical_space_usage)*/
       node_name, 
       storage_path, 
       disk_space_free_percent 
FROM   v_monitor.disk_storage 
WHERE  disk_space_used_mb / ( disk_space_used_mb + disk_space_free_mb ) <= 0.4 
       AND storage_usage = 'DATA,TEMP';

--*************************************************************************
--  Diagnostic Information
--*************************************************************************

-- Distribution of query request times (see below for identifying slow queries)
-- http://wp.me/p4EqBZ-2Q
SELECT /*+label(diag_query_time_distribution)*/ 
       SUM(CASE 
             WHEN request_duration_ms <= 1000 THEN 1 
             ELSE 0 
           END) AS less_than_1, 
       SUM(CASE 
             WHEN request_duration_ms BETWEEN 1001 AND 2000 THEN 1 
             ELSE 0 
           END) AS between_1_and_2, 
       SUM(CASE 
             WHEN request_duration_ms BETWEEN 2001 AND 3000 THEN 1 
             ELSE 0 
           END) AS between_2_and_3, 
       SUM(CASE 
             WHEN request_duration_ms BETWEEN 3001 AND 4000 THEN 1 
             ELSE 0 
           END) AS between_3_and_4, 
       SUM(CASE 
             WHEN request_duration_ms BETWEEN 4001 AND 5000 THEN 1 
             ELSE 0 
           END) AS between_4_and_5, 
       SUM(CASE 
             WHEN request_duration_ms > 5000 THEN 1 
             ELSE 0 
           END) AS greater_than_5 
FROM   v_monitor.query_requests;

-- Shows possible issues with planning of execution of a query; specifically 
-- looking for event types such as GROUP_BY_SPILLED and JOIN_SPILLED
-- http://j.mp/vertica-first-query-performance-steps
SELECT /*+label(diag_query_events)*/ 
       event_timestamp, 
       session_id, 
       transaction_id, 
       event_description, 
       event_type 
FROM   v_monitor.query_events 
ORDER  BY event_timestamp DESC; 

-- Shows overview of event types
-- http://j.mp/vertica-v_monitor-query_events
SELECT /*+label(diag_query_event_types)*/
       event_type, 
       COUNT(*) 
FROM   query_events 
GROUP  BY event_type 
ORDER  BY COUNT(*) DESC; 

-- Shows queries that spilled to disk during execution; the query
-- should be optimized for a merge join or group by pipelined
-- http://j.mp/vertica-optimizing-query-performance
SELECT /*+label(diag_query_event_types)*/
       DISTINCT qr.start_timestamp, 
                qe.event_type, 
                REGEXP_REPLACE(qr.request, '[\r\t\f\n]', ' ') AS request 
FROM   v_monitor.query_events qe 
       JOIN v_monitor.query_requests qr 
         ON qr.transaction_id = qe.transaction_id 
            AND qr.statement_id = qe.statement_id 
WHERE  qe.event_type IN ( 'GROUP_BY_SPILLED', 'JOIN_SPILLED' ) 
       AND qr.request_type = 'QUERY' 
ORDER  BY qr.start_timestamp; 

-- Shows query events in which rows were resegmented during execution
-- http://j.mp/vertica-designing-for-segmentation
-- http://j.mp/vertica-avoiding-segmentation-during-joins
SELECT /*+label(diag_query_events_resegment)*/ 
       DISTINCT qr.start_timestamp, 
                REGEXP_REPLACE(qr.request, '[\r\t\f\n]', ' ') AS request 
FROM   v_monitor.query_events qe 
       JOIN v_monitor.query_requests qr 
         ON qr.transaction_id = qe.transaction_id 
            AND qr.statement_id = qe.statement_id 
WHERE  qe.event_type = 'RESEGMENTED_MANY_ROWS' 
       AND qr.request_type = 'QUERY' 
ORDER  BY qr.start_timestamp;

-- Shows any load events that had rejected rows
-- See also: http://j.mp/vertica-v_monitor-load_streams
SELECT /*+label(diag_rejected_load_rows)*/
       le.time, 
       le.node_name, 
       le.event_description, 
       le.event_type, 
       le.rows_accepted, 
       le.rows_rejected, 
       le.session_id, 
       le.user_name, 
       ss.client_hostname, 
       ss.session_type, 
       ss.is_internal 
FROM   v_internal.dc_load_events le 
       LEFT JOIN v_internal.dc_session_starts ss 
              ON ss.session_id = le.session_id 
WHERE  le.rows_rejected <> 0 
ORDER  BY le.time DESC;

-- Shows any query requests with errors (truncated request text)
-- http://wp.me/p4EqBZ-2U
SELECT /*+label(diag_query_errors)*/
       qr.node_name, 
       qr.user_name, 
       qr.session_id, 
       qr.start_timestamp, 
       qr.request_type, 
       LEFT(REGEXP_REPLACE(qr.request, '[\r\t\f\n]', ' '), 100) AS request, 
       qr.request_duration_ms, 
       qr.error_count, 
       em.error_level, 
       em.error_code, 
       em.message 
FROM   v_monitor.query_requests qr 
       JOIN v_monitor.error_messages em 
         ON em.node_name = qr.node_name 
            AND em.session_id = qr.session_id 
            AND em.request_id = qr.request_id 
            AND em.transaction_id = qr.transaction_id 
ORDER  BY qr.start_timestamp DESC;

-- Shows the last run and interval for each service on each node
-- http://j.mp/vertica-v_monitor-system_services
SELECT /*+label(diag_system_services)*/
       * 
FROM   v_monitor.system_services 
ORDER  BY node_name, 
          last_run_start;

-- Shows Workload Analyzer tuning rules
-- http://j.mp/vertica-secret-world-workload-analyzer
SELECT /*+label(diag_wla_tuning_params)*/
       * 
FROM   v_internal.vs_tuning_rule_parameters;

-- Shows tables without primary keys
-- http://wp.me/p4EqBZ-1d
SELECT /*+label(diag_tables_without_pk)*/ 
       DISTINCT t.table_schema, 
                t.table_name 
FROM   v_catalog.tables t 
       LEFT JOIN (SELECT table_id, 
                         MAX(CASE 
                               WHEN constraint_type = 'p' THEN 1 
                               ELSE 0 
                             END) AS has_pk 
                  FROM   v_catalog.constraint_columns 
                  GROUP  BY table_id) cc 
              ON cc.table_id = t.table_id 
WHERE  cc.has_pk = 0 
       AND t.is_system_table = 'f' 
ORDER  BY t.table_schema, 
          t.table_name; 

-- Shows percentage of database that has been deleted
-- http://j.mp/vertica-delete-update-query-considerations
SELECT /*+label(diag_database_deleted_data)*/ 
      (SELECT SUM(used_bytes) 
       FROM   v_monitor.delete_vectors) / (SELECT SUM(ros_used_bytes) 
                                           FROM   v_monitor.projection_storage) * 100 AS percent;

-- Shows denied resource requests (useful for identifying resource space and pool issues)
-- http://j.mp/vertica-clear-resource-rejections
SELECT /*+label(diag_denied_resource_req)*/ 
       reason, 
       COUNT(*) 
FROM   v_monitor.resource_rejection_details 
GROUP  BY reason;

-- Shows mergeout activity, durations, and volumes processed
-- http://j.mp/vertica-v_monitor-tuple_mover_operations
SELECT /*+label(diag_mergeout_activity)*/ 
       DATEDIFF(mi, ms.operation_start_timestamp, CASE WHEN me.operation_status = 'Running' THEN clock_timestamp() ELSE me.operation_start_timestamp END) AS min_to_complete,
       CAST(CASE WHEN DATEDIFF(ss, ms.operation_start_timestamp, CASE WHEN me.operation_status = 'Running' THEN NULL::TIMESTAMP ELSE me.operation_start_timestamp END ) > 0 THEN CAST(ms.total_ros_used_bytes / ( 1024.0^2 ) AS DECIMAL(14,2))/DATEDIFF(ss,ms.operation_start_timestamp,CASE WHEN me.operation_status = 'Running' THEN clock_timestamp() ELSE me.operation_start_timestamp END ) ELSE 0 END AS DECIMAL(14,2)) AS mb_sec,
       me.operation_status AS mergeout_status,
       ms.operation_start_timestamp AS mergeout_start,
       me.operation_start_timestamp AS mergeout_end,
       ms.node_name,
       ms.table_name,
       ms.projection_name,
       ms.total_ros_used_bytes AS ros_bytes,
       CAST(ms.total_ros_used_bytes / ( 1024.0^2 ) AS DECIMAL(14,2)) AS ros_mb,
       CAST(ms.total_ros_used_bytes / ( 1024.0^3 ) AS DECIMAL(14,2)) AS ros_gb,
       ms.earliest_container_start_epoch AS start_epoch,
       ms.latest_container_end_epoch AS end_epoch,
       ms.ros_count
FROM  (SELECT * 
       FROM   v_monitor.tuple_mover_operations 
       WHERE  operation_name = 'Mergeout' 
              AND operation_status = 'Start' ) AS ms
       LEFT JOIN (SELECT * 
                  FROM   v_monitor.tuple_mover_operations 
                  WHERE  operation_name = 'Mergeout' 
                         AND operation_status IN ( 'Complete', 'Running' ) ) AS me
               ON ms.earliest_container_start_epoch = me.earliest_container_start_epoch
                  AND ms.latest_container_end_epoch = me.latest_container_end_epoch
                  AND ms.ros_count = me.ros_count
                  AND ms.total_ros_used_bytes = me.total_ros_used_bytes
                  AND ms.session_id = me.session_id
                  AND ms.node_name = me.node_name
                  AND ms.table_name = me.table_name
                  AND ms.table_schema = me.table_schema
                  AND ms.projection_name = me.projection_name
WHERE   ms.operation_start_timestamp BETWEEN clock_timestamp() - INTERVAL '1 DAY' AND clock_timestamp()
        -- AND ms.table_schema = 'foo'
        -- AND ms.table_name = 'bar' 
ORDER   BY ms.projection_name, 
           me.operation_status DESC;

-- Sessions that have not been closed and have had no activity for at least 
-- 15 min. Use discretion to determine the session is no longer active (a 
-- transaction which has been ended is typically committed)
-- http://j.mp/vertica_managing_sessions
SELECT /*+label(diag_open_sessions)*/ 
       s.time AS session_start,
       ts.time AS transaction_start,
       s.user_name,
       s.client_hostname,
       ts.node_name, 
       ts.session_id, 
       ts.transaction_id, 
       E'SELECT /*+label(close_session)*/ CLOSE_SESSION(\'' || s.session_id 
         || E'\');' AS close_command
       --, LEFT(REGEXP_REPLACE(TRIM(BOTH E'\'' FROM SUBSTRING(ts.description FROM 21)), '[\r\t\f\n]', ' '), 100) AS last_statement
FROM   v_internal.dc_transaction_starts ts 
       JOIN (SELECT time, 
                    user_name, 
                    client_hostname, 
                    session_id, 
                    node_name 
             FROM   v_internal.dc_session_starts 
             WHERE  NOT is_internal) s 
           USING (node_name, session_id) 
       LEFT JOIN v_internal.dc_transaction_ends te 
           USING (node_name, session_id, transaction_id)
WHERE  te.time IS NULL
AND    ts.time < SYSDATE() - INTERVAL '15 minutes';

-- Shows cluster request distribution to identify potential load balancing issues
-- http://j.mp/vertica-request-distribution
SELECT /*+label(diag_request_distriution)*/ 
       a.requests, 
       ROUND((a.requests / b.total_requests) * 100, 2.0) AS percent
FROM   (SELECT node_name, 
               COUNT(*) AS requests 
        FROM   v_monitor.query_requests 
        GROUP  BY node_name) a 
       CROSS JOIN (SELECT COUNT(*) AS total_requests 
                   FROM   v_monitor.query_requests) b 
ORDER  BY percent DESC;

--*************************************************************************
--  Projection Specific
--*************************************************************************

-- Shows projections that haven't been refreshed in the past 3 months 
-- or do not have a corresponding refresh
-- http://j.mp/vertica-refresh
SELECT /*+label(diag_stale_projections)*/ 
       p.projection_schema, 
       p.projection_name, 
       DATEDIFF(day, pr.refresh_start, SYSDATE()) AS days_last_refresh 
FROM   v_catalog.projections p 
       LEFT JOIN v_monitor.projection_refreshes pr 
              ON pr.projection_id = p.projection_id 
WHERE  DATEDIFF(month, pr.refresh_start, SYSDATE()) >= 3 
        OR pr.projection_id IS NULL 
ORDER  BY days_last_refresh DESC;

-- Shows projection columns that haven't been refreshed in the past month
-- http://j.mp/vertica-last-statistics-update
SELECT /*+label(diag_stale_projection_columns)*/ 
       projection_id, 
       projection_name, 
       projection_column_name, 
       statistics_type, 
       DATEDIFF(day, statistics_updated_timestamp, SYSDATE()) AS days_last_refresh 
FROM   v_catalog.projection_columns 
WHERE  DATEDIFF(month, statistics_updated_timestamp, SYSDATE()) >= 1
ORDER  BY days_last_refresh DESC;

-- Shows possible data skew in segmented projections; note: Workload
-- Analyzer should be run to obtain the most recent recommendations
-- http://j.mp/vertica-wla-triggering-conditions
SELECT /*+label(diag_workload_resegment)*/
       tuning_description, 
       tuning_cost 
FROM   v_monitor.tuning_recommendations 
WHERE  tuning_description LIKE 're-segment%'
ORDER  BY tuning_description;

-- Shows projections which do not have full statistics; with tuning command;
-- only looking for statistics_type of NONE or ROWCOUNT. NONE means no statistics;
-- ROWCOUNT means created automatically from existing catalog metadata
-- http://j.mp/vertica-reacting-to-stale-statistics
SELECT /*+label(diag_unrefreshed_columns)*/ 
       pc.projection_name, 
       pc.table_name, 
       pc.table_column_name, 
       pc.statistics_type, 
       E'SELECT /*+label(update_statistics)*/ ANALYZE_STATISTICS(\'' 
         || pc.table_name || '.' || pc.table_column_name || E'\');' AS tuning_command
FROM   v_catalog.projections p 
       JOIN v_catalog.projection_columns pc 
         ON pc.projection_id = p.projection_id 
WHERE  p.has_statistics = 'f' 
       AND pc.statistics_type IN ( 'NONE', 'ROWCOUNT' );

-- Shows projection last used timestamp to identify unused projections
-- http://j.mp/vertica-unused_projections
SELECT /*+label(diag_unused_projections)*/
       projection_basename, 
       MAX(time) AS last_used 
FROM   v_internal.dc_projections_used 
WHERE  table_oid IN (SELECT table_id 
                     FROM   v_catalog.tables 
                     WHERE  NOT is_system_table) 
GROUP  BY projection_basename 
ORDER  BY last_used ASC 
LIMIT  50;

--*************************************************************************
--  Query Profiling Information
--*************************************************************************

-- Examining actual time spent in query
-- http://j.mp/vertica-profiling-database-performance
-- Profiling configuration: if any configs are enabled, and you're not 
-- performing profiling, it may be using memory
-- To disable: http://j.mp/vertica-disable-profiling
SELECT SHOW_PROFILING_CONFIG();

-- Clear previous profiling data
-- http://j.mp/vertica-functions-clear-profiling
SELECT CLEAR_PROFILING('query');

-- Session and global profiling should be enabled as they will be capped by data
-- collector policies; execution engine profiling should be used sparsely and briefly
-- http://j.mp/vertica-profiling-parameters
SELECT SET_CONFIG_PARAMETER('GlobalQueryProfiling', 1);
SELECT SET_CONFIG_PARAMETER('GlobalSessionProfiling', 1);

-- Examine query_profiles; shows 50 longest running queries
-- http://j.mp/vertica-view-profiling-data
SELECT /*+label(diag_long_running_queries)*/ 
       LEFT(REGEXP_REPLACE(query, '[\r\t\f\n]', ' '), 100) AS query, 
       COUNT(*)                                            AS instances, 
       AVG(query_duration_us)                              AS avg_query_duration_us 
FROM   v_monitor.query_profiles 
GROUP  BY query 
ORDER  BY avg_query_duration_us DESC 
LIMIT  50;
