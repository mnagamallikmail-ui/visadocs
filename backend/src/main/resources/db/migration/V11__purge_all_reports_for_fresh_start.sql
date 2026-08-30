-- V11: Purge all orders, order inputs, order documents, and revisions for fresh production start
DELETE FROM order_documents;
DELETE FROM order_inputs;
DELETE FROM revisions;
DELETE FROM performance_ledger;
DELETE FROM orders;
