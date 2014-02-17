# Vertica Kit
It's my goal to create a kit that contains essential queries and resources for administering HP's Vertica. You can check out what I've done so far on [my blog](http://www.jadito.us).

## Vertica Diagnostic Queries
The goal of these queries is to provide as much information as possible covering monitoring, diagnostics and performance tuning. This idea is heavily inspired by [Glenn Barry's](http://www.sqlskills.com/blogs/glenn/category/dmv-queries/) SQL Server diagnostic queries and [Ola Hallengren's](http://ola.hallengren.com/) SQL Server maintenance solution.

The February 2014 release contains 12 queries over 3 sections and covers the following:

* Configuration Information
 * Product Version
 * License and Compliance Status
 * Data Collector Status
 * Profiling Configuration
* Resource Information
 * Disk Space Utilization by Host
 * Processor Information by Host
 * Memory Information by Host
 * Compressed and Raw Estimate Space Usage by Schema
* Diagnostic Information
 * Distribution of Query Request Times
 * Outdated and Un-refreshed Projections
 * Load Events with Rejected Rows
 * Query Requests with Errors

## Other Resources
Doug Harmon has his own [Vertical SQL Toolbelt](https://github.com/DougHarmon/v-sql-tb) that contains shell scripts and other helpful diagnostic queries.

The unofficial [Vertica forums](http://www.vertica-forums.com) have some great people helping out the Vertica community.
