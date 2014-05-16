# Vertica Kit
It's my goal to create a kit that contains essential queries and resources for administering HP's Vertica. You can check out what I've done so far on [my blog](http://www.jadito.us).

## Vertica Diagnostic Queries
The goal of these queries is to provide as much information as possible covering monitoring, diagnostics and performance tuning. This idea is heavily inspired by [Glenn Barry's](http://www.sqlskills.com/blogs/glenn/category/dmv-queries/) SQL Server diagnostic queries and [Ola Hallengren's](http://ola.hallengren.com/) SQL Server maintenance solution.

The May 2014 release has the following changes:
* Fixed schema for query_requests for query time distribution
* Adds 6 queries
 * Nodes with less than recommended disk space available (40%)
 * Workload analyzer tuning rules
 * Tables without primary keys (help with optimizing joins)
 * Percentage of database that has been deleted
 * Denied resource requests (identify resource space and pool issues)
 * Projection last used timestamp (identify unused projections)

It contains 32 queries over 4 sections and covers the following:

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
* Diagnostic Information (17)
 * Distribution of Query Request Times
 * Proactively Examining Query Events
 * Overview of Query Event Types
 * Spill to Disk Events
 * Resegmented Query Events
 * Data Skew in Segmented Projections
 * Outdated and Un-refreshed Projections
 * Outdated Column Statistics
 * Columns Requiring Statistics Updates
 * Load Events with Rejected Rows
 * Query Requests with Errors
 * Service Intervals and Last Run
 * Workload Analyzer Tuning Rules
 * Possible Missing Primary Keys
 * Deleted Database Date
 * Denied Resource Requests
 * Unused Projections
* Query Profiling Information (4)
 * Profiling Configuration
 * Clearing Profile Data
 * Query, Session and EE Profiling
 * Examining Query Profiles

## Other Resources
Doug Harmon has his own [Vertical SQL Toolbelt](https://github.com/DougHarmon/v-sql-tb) that contains shell scripts and other helpful diagnostic queries.

The unofficial [Vertica forums](http://www.vertica-forums.com) have some great people helping out the Vertica community.

[vertica.tips](http://www.vertica.tips) is a blog with authors from the community sharing expert knowledge.