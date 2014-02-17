-- Vertica Diagnostic Information Queries
-- February 2014
--
-- Last Modified: February 16, 2014
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
-- https://my.vertica.com/docs/6.0.x/HTML/index.htm#15460.htm
-- https://my.vertica.com/docs/6.0.x/HTML/index.htm#15563.htm
SELECT DISPLAY_LICENSE();
SELECT GET_COMPLIANCE_STATUS();

-- Is the Data Collector enabled (for monitoring)
-- https://my.vertica.com/docs/6.0.x/HTML/index.htm#16138.htm
SELECT GET_CONFIG_PARAMETER('EnableDataCollector');

-- Profiling configuration (Session, Query, Execution Engine)
-- If any profile configurations are enabled, they may be using memory
-- https://my.vertica.com/docs/6.0.x/HTML/index.htm#10300.htm
-- To disable: https://my.vertica.com/docs/6.0.x/HTML/index.htm#14373.htm
SELECT SHOW_PROFILING_CONFIG();

--*************************************************************************
--  Resource Information
--*************************************************************************

-- Shows disk space utilization by host (see below for alternate methods)
-- http://wp.me/p3Qalh-fs
SELECT host_name, 
       ( disk_space_free_mb / 1024 )  AS disk_space_free_gb, 
       ( disk_space_used_mb / 1024 )  AS disk_space_used_gb, 
       ( disk_space_total_mb / 1024 ) AS disk_space_total_gb 
FROM   v_monitor.host_resources;

-- Shows processor information by host
SELECT host_name, 
       processor_count, 
       processor_core_count, 
       processor_description 
FROM   v_monitor.host_resources;

-- Shows memory information by host
SELECT host_name, 
       total_memory_bytes / ( 1024^3 )           AS total_memory_gb, 
       total_memory_free_bytes / ( 1024^3 )      AS total_memory_free_gb, 
       total_swap_memory_bytes / ( 1024^3 )      AS total_swap_memory_gb, 
       total_swap_memory_free_bytes / ( 1024^3 ) AS total_swap_memory_free_gb 
FROM   v_monitor.host_resources;

-- Shows compressed and raw estimate space utilization by schema
-- http://wp.me/p3Qalh-jA
SELECT ps.anchor_table_schema, 
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
SELECT SUM(CASE 
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

-- Shows projections that haven't been refreshed in the past 3 months 
-- or do not have a corresponding refresh
-- https://my.vertica.com/docs/6.0.x/HTML/index.htm#13905.htm
SELECT p.projection_schema, 
       p.projection_name, 
       DATEDIFF(day, refresh_start, SYSDATE()) AS days_last_refresh 
FROM   v_catalog.projections p 
       LEFT JOIN v_monitor.projection_refreshes pr 
              ON pr.projection_id = p.projection_id 
WHERE  DATEDIFF(month, refresh_start, SYSDATE()) >= 3 
        OR pr.projection_id IS NULL 
ORDER  BY DATEDIFF(day, refresh_start, SYSDATE()) DESC;

-- Shows any load events that had rejected rows
-- See also: https://my.vertica.com/docs/6.1.x/HTML/index.htm#12261.htm
SELECT le.time, 
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
SELECT qr.node_name, 
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