-- Vertica Diagnostic Information Queries
-- May 2014
--
-- Last Modified: May 16, 2014
-- http://www.vertica.tips
-- http://www.jadito.us
-- Twitter: justadayito
--
-- Copyright (C) 2014 Norbert Krupa
-- All rights reserved
--
-- For more scripts and sample code, check out 
--     http://jadito.us/vertica-kit
--
-- You may alter this code for your own *non-commercial* purposes. You 
-- may republish altered code as long as you include this copyright and 
-- give due credit.
--
-- Note: These queries were tested with Vertica 6.1.2-0 and for the most 
-- part should be backwards and forwards compatible. These queries should
-- be run from within vsql.
--
-- THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
-- ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
-- TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
-- PARTICULAR PURPOSE. 

--*************************************************************************
--  Configuration Information
--*************************************************************************

-- Your product version
SELECT version();

-- Your license and compliance status
-- https://my.vertica.com/docs/6.1.x/HTML/index.htm#15460.htm
-- https://my.vertica.com/docs/6.1.x/HTML/index.htm#15563.htm
SELECT DISPLAY_LICENSE();
SELECT GET_COMPLIANCE_STATUS();

-- Is the Data Collector enabled (for monitoring)
-- https://my.vertica.com/docs/6.1.x/HTML/index.htm#16138.htm
SELECT GET_CONFIG_PARAMETER('EnableDataCollector');

-- Configuration parameters that have been modified
-- https://my.vertica.com/docs/6.1.x/HTML/index.htm#12772.htm
SELECT /*+label(diag_changed_config_param)*/ 
       * 
FROM   v_monitor.configuration_parameters 
WHERE  current_value <> default_value; 

-- Shows change history of configuration parameters
-- https://my.vertica.com/docs/6.1.x/HTML/index.htm#17542.htm
SELECT /*+label(diag_config_param_history)*/ 
       * 
FROM   v_monitor.configuration_changes 
ORDER  BY event_timestamp DESC; 

-- Shows current fault tolerance of the system by returning K-safety 
-- level and number of node failures before automatic shut down
-- https://my.vertica.com/docs/6.1.x/HTML/index.htm#12275.htm
SELECT /*+label(diag_fault_tolerance)*/ 
       designed_fault_tolerance, 
       current_fault_tolerance 
FROM   v_monitor.system;

--*************************************************************************
--  Resource Information
--*************************************************************************

-- Shows disk space utilization by host (see below for alternate methods)
-- http://wp.me/p3Qalh-fs
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
-- http://wp.me/p3Qalh-jA
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
SELECT /*+label()*/
       node_name, 
       storage_path, 
       disk_space_free_percent 
FROM   v_monitor.disk_storage 
WHERE  disk_space_free_mb / ( disk_space_used_mb + disk_space_free_mb ) <= 0.4 
       AND storage_usage = 'DATA,TEMP';

--*************************************************************************
--  Diagnostic Information
--*************************************************************************

-- Distribution of query request times (see below for identifying slow queries)
-- http://wp.me/p3Qalh-ir
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
FROM   v_internal.query_requests;

-- Shows possible issues with planning of execution of a query; specifically 
-- looking for event types such as GROUP_BY_SPILLED and JOIN_SPILLED
-- https://my.vertica.com/docs/6.1.x/HTML/index.htm#20263.htm
SELECT /*+label(diag_query_events)*/ 
       event_timestamp, 
       session_id, 
       transaction_id, 
       event_description, 
       event_type 
FROM   v_monitor.query_events 
ORDER  BY event_timestamp DESC; 

-- Shows overview of event types
-- https://my.vertica.com/docs/6.1.x/HTML/index.htm#17580.htm
SELECT /*+label(diag_query_event_types)*/
       event_type, 
       COUNT(*) 
FROM   query_events 
GROUP  BY event_type 
ORDER  BY COUNT(*) DESC; 

-- Shows queries that spilled to disk during execution; the query
-- should be optimized for a merge join or group by pipelined
-- https://my.vertica.com/docs/6.1.x/HTML/index.htm#12525.htm
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
-- https://my.vertica.com/docs/6.1.x/HTML/index.htm#12174.htm
-- https://my.vertica.com/docs/6.1.x/HTML/index.htm#10248.htm
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

-- Shows possible data skew in segmented projections; note: Workload
-- Analyzer should be run to obtain the most recent recommendations
-- https://my.vertica.com/docs/6.1.x/HTML/index.htm#17426.htm
SELECT /*+label(diag_workload_resegment)*/
       tuning_description, 
       tuning_cost 
FROM   v_monitor.tuning_recommendations 
WHERE  tuning_description LIKE 're-segment%'
ORDER  BY tuning_description;

-- Shows projections that haven't been refreshed in the past 3 months 
-- or do not have a corresponding refresh
-- https://my.vertica.com/docs/6.1.x/HTML/index.htm#13905.htm
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
-- https://my.vertica.com/docs/6.1.x/HTML/index.htm#15576.htm
SELECT /*+label(diag_stale_projection_columns)*/ 
       projection_id, 
       projection_name, 
       projection_column_name, 
       statistics_type, 
       DATEDIFF(day, statistics_updated_timestamp, SYSDATE()) AS days_last_refresh 
FROM   v_catalog.projection_columns 
WHERE  DATEDIFF(month, statistics_updated_timestamp, SYSDATE()) >= 1
ORDER  BY days_last_refresh DESC;

-- Shows projections which do not have full statistics; with tuning command;
-- only looking for statistics_type of NONE or ROWCOUNT. NONE means no statistics;
-- ROWCOUNT means created automatically from existing catalog metadata
-- https://my.vertica.com/docs/6.1.x/HTML/index.htm#15574.htm
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

-- Shows any load events that had rejected rows
-- See also: https://my.vertica.com/docs/6.1.x/HTML/index.htm#12261.htm
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
-- http://wp.me/p3Qalh-iV
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

-- Shows the last run and interval for each service on each ndoe
-- https://my.vertica.com/docs/6.1.x/HTML/index.htm#17588.htm
SELECT /*+label(diag_system_services)*/
       * 
FROM   v_monitor.system_services 
ORDER  BY node_name, 
          last_run_start;

-- Shows Workload Analyzer tuning rules
-- http://www.vertica.com/2014/05/06/inside-the-secret-world-of-the-workload-analyzer/
SELECT /*+label(diag_wla_tuning_params)*/
       * 
FROM   v_internal.vs_tuning_rule_parameters;

-- Shows tables without primary keys
-- http://vertica.tips/2014/03/29/hash-join-operator/
SELECT /*+label(diag_tables_without_pk)*/
       DISTINCT t.table_schema, 
                t.table_name 
FROM   v_catalog.tables t 
       LEFT JOIN v_catalog.constraint_columns cc 
              ON cc.table_id = t.table_id 
WHERE  cc.constraint_type <> 'p' 
ORDER  BY t.table_schema, 
          t.table_name; 

-- Shows percentage of database that has been deleted
-- https://my.vertica.com/docs/6.1.x/HTML/index.htm#12704_1.htm
SELECT /*+label(diag_database_deleted_data)*/ 
      (SELECT SUM(used_bytes) 
        FROM   v_monitor.delete_vectors) / (SELECT SUM(ros_used_bytes) 
                                            FROM   v_monitor.projection_storage) * 100 AS percent;

-- Shows denied resource requests (useful for identifying resource space and pool issues)
-- https://my.vertica.com/docs/6.1.x/HTML/index.htm#15239_1.htm
SELECT /*+label(diag_denied_resource_req)*/ 
       reason, 
       COUNT(*) 
FROM   v_monitor.resource_rejection_details 
GROUP  BY reason;

-- Shows projection last used timestamp to identify unused projections
-- https://my.vertica.com/docs/6.1.x/HTML/index.htm#17579.htm
SELECT /*+label(diag_unused_projectiosn)*/ 
       projection_name, 
       MIN(query_start_timestamp) AS last_used_timestamp 
FROM   v_monitor.projection_usage 
GROUP  BY projection_name, 
          query_start_timestamp 
ORDER  BY query_start_timestamp 
LIMIT  30;

--*************************************************************************
--  Query Profiling Information
--*************************************************************************

-- Examining actual time spent in query
-- https://my.vertica.com/docs/6.1.x/HTML/index.htm#10300.htm
-- Profiling configuration: if any configs are enabled, and you're not 
-- performing profiling, it may be using memory
-- To disable: https://my.vertica.com/docs/6.1.x/HTML/index.htm#14373.htm
SELECT SHOW_PROFILING_CONFIG();

-- Clear previous profiling data
-- https://my.vertica.com/docs/6.1.x/HTML/index.htm#10305.htm
SELECT CLEAR_PROFILING('query');

-- Session and global profiling should be enabled as they will be capped by data
-- collector policies; execution engine profiling should be used sparsely and briefly
-- https://my.vertica.com/docs/6.1.x/HTML/index.htm#13914.htm
SELECT SET_CONFIG_PARAMETER('GlobalQueryProfiling', 1);
SELECT SET_CONFIG_PARAMETER('GlobalSessionProfiling', 1);

-- Examine query_profiles; shows 50 longest running queries
-- https://my.vertica.com/docs/6.1.x/HTML/index.htm#10304.htm
SELECT /*+label(diag_long_running_queries)*/ 
       LEFT(REGEXP_REPLACE(query, '[\r\t\f\n]', ' '), 100) AS query, 
       COUNT(*)                                            AS instances, 
       AVG(query_duration_us)                              AS avg_query_duration_us 
FROM   v_monitor.query_profiles 
GROUP  BY query 
ORDER  BY avg_query_duration_us DESC 
LIMIT 50;