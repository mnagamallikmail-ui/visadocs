-- V11: Purge all orders, order inputs, order documents, transactions, and revisions for fresh production start
DELETE FROM transactions WHERE order_id IS NOT NULL;
DELETE FROM order_documents;
DELETE FROM order_inputs;
DELETE FROM revisions;
DELETE FROM performance_ledger;
DELETE FROM orders;
