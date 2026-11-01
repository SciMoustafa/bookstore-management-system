-- Ensure each document creates at most one financial transaction.
ALTER TABLE bookstore.financial_transactions
ADD CONSTRAINT uq_financial_transactions_document
UNIQUE (document_id);