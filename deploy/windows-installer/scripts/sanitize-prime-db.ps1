<#
.SYNOPSIS
Sanitizes the MariaDB 10.4 prime-db.sql dump so MySQL 8.0 can import it.

The dump (produced by mysqldump on MariaDB 10.4) contains constructs that
MySQL 8.0 rejects or treats differently:

  1. NO_AUTO_CREATE_USER sql_mode - removed in MySQL 8 (error 1231).
  2. CREATE DATABASE `prime` / USE `prime` lines - they would land all data in
     the wrong schema; the installer imports into a specific database instead.
  3. STORED generated columns are dumped WITH their values in INSERT
     statements (MariaDB behavior). MySQL 8 rejects explicit values for
     generated columns (error 3105), which - under --force - silently drops
     every row of such tables. inventory_stock.quantity_available is the one
     case in this dump: we rewrite its INSERT with an explicit column list
     that excludes the generated column and drop the corresponding value from
     each row tuple, so the seed stock rows actually import.

Output is written UTF-8 WITHOUT BOM (mysqld refuses a UTF-8 BOM in batch
input). Exit code 0 = success, 1 = failure (thrown - the installer fails
loudly rather than importing a dump that silently lost rows).

.PARAMETER Source
Path to the MariaDB prime-db.sql dump.

.PARAMETER Out
Path to write the MySQL 8 compatible copy.
#>
param(
  [Parameter(Mandatory = $true)][string]$Source,
  [Parameter(Mandatory = $true)][string]$Out
)

$ErrorActionPreference = 'Stop'

$c = [IO.File]::ReadAllText($Source)

# --- 1. NO_AUTO_CREATE_USER was removed in MySQL 8 (error 1231) ---
$c = $c -replace 'NO_AUTO_CREATE_USER,', '' `
         -replace ',NO_AUTO_CREATE_USER', '' `
         -replace 'NO_AUTO_CREATE_USER', ''

# --- 2. Drop the dump's own CREATE DATABASE `prime` / USE `prime` ---
$c = $c -replace '(?m)^CREATE DATABASE.*?;\r?\n', '' `
         -replace '(?m)^USE `prime`;\r?\n', ''

# --- 3. STORED generated column values (error 3105) ---
# inventory_stock.quantity_available is GENERATED ALWAYS AS
# (quantity_on_hand - quantity_reserved) STORED. The MariaDB dump emits a
# value for it in the positional INSERT, which MySQL 8 rejects. Rewrite the
# statement with an explicit column list excluding the generated column and
# drop the 7th value (its position in the dump's column order) from every row
# tuple. Safe for this dump: no string value contains a comma or parenthesis.
$before = [regex]::Matches($c, '(?m)^INSERT INTO `inventory_stock` VALUES').Count
$colList = '(`id`,`item_id`,`facilityId`,`store_location`,`quantity_on_hand`,`quantity_reserved`,`minimum_stock_level`,`maximum_stock_level`,`last_stock_take_date`,`last_stock_take_by`,`created_at`,`updated_at`)'
$c = [regex]::Replace(
  $c,
  '(?m)^(INSERT INTO `inventory_stock` VALUES )(\(.*?\));\r?$',
  {
    param($m)
    $tuples = $m.Groups[2].Value -split '\),\('
    $fixed = foreach ($t in $tuples) {
      # drop the 7th comma-separated field (the generated column value)
      # (the split leaves the leading '(' on the first tuple and the trailing
      # ')' on the last one - normalize both edges before editing fields)
      $t = $t -replace '^\(', '' -replace '\)$', ''
      $t -replace '^((?:[^,)]*,){6})[^,)]*,', '$1'
    }
    'INSERT INTO `inventory_stock` ' + $colList + ' VALUES (' + ($fixed -join '),(') + ');'
  }
)
$after = [regex]::Matches($c, '(?m)^INSERT INTO `inventory_stock` \(').Count
if ($before -gt 0 -and $after -ne $before) {
  throw "inventory_stock INSERT rewrite failed ($before statement(s) found, $after rewritten) - refusing to write a dump that would silently drop seed stock rows."
}

[IO.File]::WriteAllText($Out, $c, (New-Object System.Text.UTF8Encoding($false)))
