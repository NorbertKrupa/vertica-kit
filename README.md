# Vertica Kit
It's my goal to create a kit that contains essential queries and resources for administering HP's Vertica. You can check out what I've done so far on [my blog](http://www.jadito.us).

## Vertica Diagnostic Queries
The goal of these queries is to provide as much information as possible covering monitoring, diagnostics and performance tuning. This idea is heavily inspired by [Glenn Barry's](http://www.sqlskills.com/blogs/glenn/category/dmv-queries/) SQL Server diagnostic queries and [Ola Hallengren's](http://ola.hallengren.com/) SQL Server maintenance solution.

The April 2014 release has the following changes:
* Modified raw estimate data space utilization to only include super projections
* Removed suggestion to disable global profiling when not in use
* Adds 6 queries
 * Fault tolerance of system by returning K-safety level and number of node failures before automatic shut down
 * Overview of event types
 * Queries that spilled to disk during execution
 * Query events in which rows were resegmented during execution
 * Possible data skew in segmented projections
 * Last run and interval for each service on each node

It contains 26 queries over 4 sections and covers the following:

* Configuration Information (6)
 * Product Version
 * License and Compliance Status
 * Data Collector Status
 * Changed Configuration Parameters
 * Configuration Change History
 * Fault Tolerance
* Resource Information (4)
 * Disk Space Utilization by Host
 * Processor Information by Host
 * Memory Information by Host
 * Compressed and Raw Estimate Data Space Usage by Schema
* Diagnostic Information (12)
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
* Query Profiling Information (4)
 * Profiling Configuration
 * Clearing Profile Data
 * Query, Session and EE Profiling
 * Examining Query Profiles

## Other Resources
Doug Harmon has his own [Vertical SQL Toolbelt](https://github.com/DougHarmon/v-sql-tb) that contains shell scripts and other helpful diagnostic queries.

The unofficial [Vertica forums](http://www.vertica-forums.com) have some great people helping out the Vertica community.

[vertica.tips](http://www.vertica.tips) is a blog with authors from the community sharing expert knowledge.