# Vertica Kit
It's my goal to create a kit that contains essential queries and resources for administering HP's Vertica. You can check out what I've done so far at [vertica.tips](http://www.vertica.tips).

## License
Vertica Kit is free: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

## Vertica Diagnostic Queries
The goal of these queries is to provide as much information as possible covering monitoring, diagnostics and performance tuning. This idea is heavily inspired by [Glenn Barry's](http://www.sqlskills.com/blogs/glenn/category/dmv-queries/) SQL Server diagnostic queries and [Ola Hallengren's](http://ola.hallengren.com/) SQL Server maintenance solution.

The June 2015 release has the following changes:
* Updated Tables Without Primary Keys query to check for additional constraints as it may have reported incorrect information (hat tip to Allen Cook at Conclusive Analytics)

### Diagnostic Views

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

### Diagnostic Query 
 
The core diagnostic query list contains 34 queries over 5 sections and covers the following:

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
* Diagnostic Information (15)
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
 * Open sessions
 * Request Distribution 
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
Doug Harmon has his own [Vertica SQL Toolbelt](https://github.com/DougHarmon/v-sql-tb) which contains shell scripts and other helpful diagnostic queries.

The unofficial [Vertica forums](http://www.vertica-forums.com) have Vertica professionals helping the Vertica community.

[vertica.tips](http://www.vertica.tips) is a blog with authors from the community sharing expert knowledge as well as a site for valuable materials, videos, news, and training.
