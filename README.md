# Vertica Kit
It's my goal to create a kit that contains essential queries and resources for administering HP's Vertica. You can check out what I've done so far on [my blog](http://www.jadito.us).

## Vertica Diagnostic Queries
The goal of these queries is to provide as much information as possible covering monitoring, diagnostics and performance tuning. This idea is heavily inspired by [Glenn Barry's](http://www.sqlskills.com/blogs/glenn/category/dmv-queries/) SQL Server diagnostic queries and [Ola Hallengren's](http://ola.hallengren.com/) SQL Server maintenance solution.

The July 2014 release has the following changes:
* Fixes calculation on nodes with less than recommended disk space
* Adds 3 diagnostic views
 * Configuration Information View
  * License Information
  * Database Size
  * License Utilization
  * Nodes in the Cluster
  * Down Nodes in the Cluster
  * K-Safety Level
  * Number of Node Failures Before Automatic Shut Down
  * Data Collector Status
  * Changed Configuration Parameters
 * Diagnostic Information View
  * Queries returned < 1 sec
  * Queries returned between 1 and 2 sec
  * Queries returned between 2 and 3 sec
  * Queries returned between 3 and 4 sec
  * Queries returned between 4 and 5 sec
  * Queries returned > 5 sec
  * Query Events
  * Rejected Load Events
  * Tables Without Primary Keys
  * Percent of Database Deleted
  * Resource Rejections
  * Projections Without Refresh In Last 3 Months
  * Projection Columns Without Refresh In Last 1 Month
  * Projection Columns Without Full Statistics
 * Resource Information View
  * Disk Space Utilization
  * Memory Information
  * Nodes Exceeding Used Space Limit

The core diagnostic query list contains 33 queries over 5 sections and covers the following:

* Configuration Information (6)
 * Product Version
 * License and Compliance Status
 * Data Collector Status
 * Changed Configuration Parameters
 * Configuration Change History
 * Fault Tolerance
* Resource Information (5)
 * Disk Space Utilization by Host
 * Processor Information by Host
 * Memory Information by Host
 * Compressed and Raw Estimate Data Space Usage by Schema
 * Disk Space Warning
* Diagnostic Information (13)
 * Distribution of Query Request Times
 * Proactively Examining Query Events
 * Overview of Query Event Types
 * Spill to Disk Events
 * Resegmented Query Events
 * Load Events with Rejected Rows
 * Query Requests with Errors
 * Service Intervals and Last Run
 * Workload Analyzer Tuning Rules
 * Possible Missing Primary Keys
 * Deleted Database Date
 * Denied Resource Requests
 * Mergeout Activity
* Projection Specific (5)
 * Outdated Column Statistics
 * Columns Requiring Statistics Updates
 * Data Skew in Segmented Projections
 * Outdated and Un-refreshed Projections
 * Unused Projections
* Query Profiling Information (4)
 * Profiling Configuration
 * Clearing Profile Data
 * Query, Session and EE Profiling
 * Examining Query Profiles

## Other Resources
Doug Harmon has his own [Vertica SQL Toolbelt](https://github.com/DougHarmon/v-sql-tb) that contains shell scripts and other helpful diagnostic queries.

The unofficial [Vertica forums](http://www.vertica-forums.com) have some great people helping out the Vertica community.

[vertica.tips](http://www.vertica.tips) is a blog with authors from the community sharing expert knowledge.
