-- V8: Retire the SUPER_ADMIN_GATE status and restore stuck orders to SPA_GATE
-- so SPA can see and continue working on them.
UPDATE orders
SET status = 'SPA_GATE'
WHERE status = 'SUPER_ADMIN_GATE';
