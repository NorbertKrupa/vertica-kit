CREATE OR REPLACE VIEW public.view_vk_config AS
-- This view is part of the Vertica Diagnostic Kit from http://git.io/q9m-fw
-- Version
  (SELECT 'Version' AS Description, 
          VERSION() AS Result) 
UNION ALL
-- License Information
  (SELECT 'License Type', 
          REGEXP_REPLACE(companyname || ' ' || CASE 
                                                 WHEN POSITION('Unlimited' IN size) = 1 THEN 'Unlimited' 
                                                 ELSE TRIM(E' \n' FROM SPLIT_PART(size, 'B', 1)) || 'B' 
                                               END, '[\r\t\f\n]', ' ') 
   FROM   v_internal.vs_licenses)
UNION ALL
-- Database Size
  (SELECT 'Database Size', 
          CAST(ROUND(database_size_bytes / (1024^3), 2) AS VARCHAR(20)) || ' GB' 
   FROM   v_internal.vs_license_audits 
   ORDER  BY audit_start_timestamp DESC 
   LIMIT  1) 
UNION ALL
-- License Utilization
  (SELECT 'License Utilization', 
          CAST(ROUND(a.usage_percent * 100, 2) AS VARCHAR(10)) || '%'
   FROM   v_internal.vs_license_audits a 
          JOIN (SELECT MAX(audit_start_timestamp) AS audit_start_timestamp 
                FROM   v_internal.vs_license_audits) b 
            ON b.audit_start_timestamp = a.audit_start_timestamp) 
UNION ALL
-- Nodes in the Cluster
  (SELECT 'Node Count', CAST(node_count AS VARCHAR(10))
   FROM   v_internal.system)
UNION ALL
-- Down Nodes in the Cluster
  (SELECT 'Down Nodes', CAST(node_down_count AS VARCHAR(10))
   FROM   v_internal.system)
UNION ALL
-- K-Safety Level
  (SELECT 'K-Safety Level', CAST(designed_fault_tolerance AS VARCHAR(5))
   FROM   v_internal.system)
UNION ALL
-- Number of Node Failures Before Automatic Shut Down
  (SELECT 'Node Fault Tolerance', CAST(current_fault_tolerance AS VARCHAR(5))
   FROM   v_internal.system)
UNION ALL
-- Data Collector Status
  (SELECT 'Data Collector Enabled', 
          CASE 
            WHEN MAX(current_value) = 1 THEN 'Yes' 
            ELSE 'No' 
          END 
   FROM   v_internal.vs_configuration_parameters 
   WHERE  parameter_name = 'EnableDataCollector')
UNION ALL
-- Changed Configuration Parameters
  (SELECT 'Changed Parameters', 
          CAST(COUNT(*) AS VARCHAR(10))
   FROM   v_internal.vs_configuration_parameters 
   WHERE  current_value <> default_value);