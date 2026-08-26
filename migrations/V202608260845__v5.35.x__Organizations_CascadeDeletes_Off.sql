-- Shipped Open App entities must not have CascadeDeletes = 1.
-- V202605131500 turned it on for Organizations so CodeGen would emit cascade
-- cleanup in spDeleteOrganization; on a joined DB that walk included Orders.
-- Do not edit that historical V. This flip plus the stripped delete proc in
-- V202608252150 restores consumer-blind deletes: FK violations if children exist.

UPDATE [${mjSchema}].[Entity]
SET [CascadeDeletes] = 0
WHERE [Name] = 'MJ_BizApps_Common: Organizations'
  AND [CascadeDeletes] = 1;
GO
