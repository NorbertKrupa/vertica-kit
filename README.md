# Vertica Kit
It's my goal to create a kit that contains essential queries and resources for administering HP's Vertica. You can check out what I've done so far on [my blog](http://www.jadito.us).

## Vertica Diagnostic Queries
The goal of these queries is to provide as much information as possible covering monitoring, diagnostics and performance tuning. This idea is heavily inspired by [Glenn Barry's](http://www.sqlskills.com/blogs/glenn/category/dmv-queries/) SQL Server diagnostic queries and [Ola Hallengren's](http://ola.hallengren.com/) SQL Server maintenance solution.

The March 2014 release has the following changes:
* Added query labels to appropriate queries
* Moved profiling configuration into profiling section
* Updated documentation links to all use 6.1.x
* Added missing table aliases to columns for queries with joins
* Adds 8 queries

It contains 20 queries over 4 sections and covers the following:

* Configuration Information
 * Product Version
 * License and Compliance Status
 * Data Collector Status
 * Changed Configuration Parameters
 * Configuration Change History
* Resource Information
 * Disk Space Utilization by Host
 * Processor Information by Host
 * Memory Information by Host
 * Compressed and Raw Estimate Data Space Usage by Schema
* Diagnostic Information
 * Distribution of Query Request Times
 * Proactively Examining Query Events
 * Outdated and Un-refreshed Projections
 * Outdated Column Statistics
 * Columns Requiring Statistics Updates
 * Load Events with Rejected Rows
 * Query Requests with Errors
* Query Profiling Information
 * Profiling Configuration
 * Clearing Profile Data
 * Enabling Global Query Profiling
 * Examining Query Profiles

## Other Resources
Doug Harmon has his own [Vertical SQL Toolbelt](https://github.com/DougHarmon/v-sql-tb) that contains shell scripts and other helpful diagnostic queries.

The unofficial [Vertica forums](http://www.vertica-forums.com) have some great people helping out the Vertica community.

[vertica.tips](http://www.vertica.tips) is a blog with authors from the community sharing expert knowledge.