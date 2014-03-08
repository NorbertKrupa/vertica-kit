-- Vertica Diagnostic Information Queries
-- March 2014
--
-- Last Modified: March 8, 2014
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
       ps.anchor_table_schema, 
       ps.used_compressed_gb, 
       ps.used_compressed_gb * la.ratio AS raw_estimate_gb 
FROM   (SELECT anchor_table_schema, 
               SUM(used_bytes) / ( 1024^3 ) AS used_compressed_gb 
        FROM   v_monitor.projection_storage 
        GROUP  BY anchor_table_schema 
        ORDER  BY SUM(used_bytes) DESC) ps 
CROSS JOIN (SELECT (SELECT database_size_bytes 
                   FROM   v_catalog.license_audits 
                   ORDER  BY audit_start_timestamp DESC 
                   LIMIT  1) / (SELECT SUM(used_bytes) 
                                FROM   v_monitor.projection_storage) AS ratio) la
ORDER  BY ps.used_compressed_gb DESC;

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

-- Enable query profiling and allow to run for sufficient period of time; 
-- disable when not in use
-- https://my.vertica.com/docs/6.1.x/HTML/index.htm#13914.htm
SELECT SET_CONFIG_PARAMETER('GlobalQueryProfiling', 1);

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