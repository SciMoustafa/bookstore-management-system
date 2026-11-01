-- Bookstore Management System - PostgreSQL schema v1.0
-- Foundation DDL. Run in a NEW database. Amounts use NUMERIC, not FLOAT.
BEGIN;
CREATE SCHEMA IF NOT EXISTS bookstore;
SET search_path TO bookstore, public;

CREATE TABLE users (
 user_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 username VARCHAR(60) NOT NULL UNIQUE,
 password_hash TEXT NOT NULL,
 full_name VARCHAR(160) NOT NULL,
 role VARCHAR(10) NOT NULL CHECK (role IN ('OWNER','WORKER')),
 is_active BOOLEAN NOT NULL DEFAULT TRUE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE documents (
 document_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 document_number VARCHAR(40) NOT NULL UNIQUE,
 document_type VARCHAR(30) NOT NULL CHECK (document_type IN
 ('PURCHASE','SALE','SALE_RETURN','OFFICE_ISSUE','OFFICE_RETURN','PAYMENT','EXPENSE','TRANSFER','DAILY_CLOSING','STOCK_COUNT','SUPPLIER_REPLACEMENT','STOCK_ADJUSTMENT')),
 document_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 status VARCHAR(12) NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT','POSTED','VOIDED')),
 created_by BIGINT NOT NULL REFERENCES users(user_id),
 approved_by BIGINT REFERENCES users(user_id),
 approved_at TIMESTAMPTZ,
 notes TEXT,
 CHECK (status <> 'POSTED' OR approved_at IS NOT NULL)
);

CREATE TABLE categories (
 category_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 category_name VARCHAR(120) NOT NULL UNIQUE,
 is_active BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE books (
 book_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 title VARCHAR(250) NOT NULL,
 author VARCHAR(200) NOT NULL,
 category_id BIGINT REFERENCES categories(category_id),
 barcode VARCHAR(80) NOT NULL UNIQUE,
 retail_price NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (retail_price >= 0),
 wholesale_price NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (wholesale_price >= 0),
 average_cost NUMERIC(12,4) NOT NULL DEFAULT 0 CHECK (average_cost >= 0),
 stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
 target_stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK (target_stock_quantity >= 0),
 is_active BOOLEAN NOT NULL DEFAULT TRUE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_books_title ON books(title);

CREATE TABLE parties (
 party_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 party_name VARCHAR(200) NOT NULL,
 phone VARCHAR(40), notes TEXT,
 is_active BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE party_roles (
 party_role_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 party_id BIGINT NOT NULL REFERENCES parties(party_id),
 role_type VARCHAR(24) NOT NULL CHECK (role_type IN ('SUPPLIER','OFFICE','WHOLESALE_CUSTOMER')),
 UNIQUE(party_id, role_type)
);
CREATE TABLE party_accounts (
 party_account_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 party_id BIGINT NOT NULL REFERENCES parties(party_id),
 account_type VARCHAR(12) NOT NULL CHECK (account_type IN ('RECEIVABLE','PAYABLE')),
 is_active BOOLEAN NOT NULL DEFAULT TRUE,
 UNIQUE(party_id, account_type)
);
CREATE TABLE party_ledger_entries (
 entry_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 party_account_id BIGINT NOT NULL REFERENCES party_accounts(party_account_id),
 document_id BIGINT NOT NULL REFERENCES documents(document_id),
 entry_type VARCHAR(30) NOT NULL,
 debit NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (debit >= 0),
 credit NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (credit >= 0),
 entry_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 CHECK ((debit > 0 AND credit = 0) OR (credit > 0 AND debit = 0))
);
CREATE INDEX idx_party_ledger_account_date ON party_ledger_entries(party_account_id, entry_date);

CREATE TABLE purchases (
 document_id BIGINT PRIMARY KEY REFERENCES documents(document_id),
 supplier_party_id BIGINT NOT NULL REFERENCES parties(party_id),
 subtotal NUMERIC(12,2) NOT NULL CHECK (subtotal >= 0),
 supplier_discount NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (supplier_discount >= 0),
 total_amount NUMERIC(12,2) NOT NULL CHECK (total_amount >= 0),
 CHECK (supplier_discount <= subtotal)
);
CREATE TABLE purchase_items (
 purchase_item_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 document_id BIGINT NOT NULL REFERENCES purchases(document_id),
 book_id BIGINT NOT NULL REFERENCES books(book_id),
 quantity INTEGER NOT NULL CHECK (quantity > 0),
 unit_cost NUMERIC(12,4) NOT NULL CHECK (unit_cost >= 0),
 line_total NUMERIC(12,2) NOT NULL CHECK (line_total >= 0)
);

CREATE TABLE sales (
 document_id BIGINT PRIMARY KEY REFERENCES documents(document_id),
 party_id BIGINT REFERENCES parties(party_id),
 sale_type VARCHAR(20) NOT NULL CHECK (sale_type IN ('RETAIL','WHOLESALE_DIRECT')),
 subtotal NUMERIC(12,2) NOT NULL CHECK (subtotal >= 0),
 discount_amount NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
 total_amount NUMERIC(12,2) NOT NULL CHECK (total_amount >= 0),
 CHECK (discount_amount <= subtotal)
);
CREATE TABLE sale_items (
 sale_item_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 document_id BIGINT NOT NULL REFERENCES sales(document_id),
 book_id BIGINT NOT NULL REFERENCES books(book_id),
 quantity INTEGER NOT NULL CHECK (quantity > 0),
 default_unit_price NUMERIC(12,2) NOT NULL CHECK (default_unit_price >= 0),
 actual_unit_price NUMERIC(12,2) NOT NULL CHECK (actual_unit_price >= 0),
 line_total NUMERIC(12,2) NOT NULL CHECK (line_total >= 0),
 unit_cost_snapshot NUMERIC(12,4) NOT NULL CHECK (unit_cost_snapshot >= 0)
);

CREATE TABLE office_issues (
 document_id BIGINT PRIMARY KEY REFERENCES documents(document_id),
 office_party_id BIGINT NOT NULL REFERENCES parties(party_id),
 taken_by_name VARCHAR(160) NOT NULL,
 subtotal NUMERIC(12,2) NOT NULL CHECK (subtotal >= 0),
 discount_amount NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
 total_amount NUMERIC(12,2) NOT NULL CHECK (total_amount >= 0),
 CHECK (discount_amount <= subtotal)
);
CREATE TABLE office_issue_items (
 issue_item_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 document_id BIGINT NOT NULL REFERENCES office_issues(document_id),
 book_id BIGINT NOT NULL REFERENCES books(book_id),
 quantity INTEGER NOT NULL CHECK (quantity > 0),
 default_unit_price NUMERIC(12,2) NOT NULL CHECK (default_unit_price >= 0),
 actual_unit_price NUMERIC(12,2) NOT NULL CHECK (actual_unit_price >= 0),
 line_total NUMERIC(12,2) NOT NULL CHECK (line_total >= 0),
 unit_cost_snapshot NUMERIC(12,4) NOT NULL CHECK (unit_cost_snapshot >= 0)
);
CREATE TABLE sale_returns (
 document_id BIGINT PRIMARY KEY REFERENCES documents(document_id),
 original_sale_id BIGINT NOT NULL REFERENCES sales(document_id),
 refund_amount NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (refund_amount >= 0)
);
CREATE TABLE sale_return_items (
 return_item_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 document_id BIGINT NOT NULL REFERENCES sale_returns(document_id),
 sale_item_id BIGINT NOT NULL REFERENCES sale_items(sale_item_id),
 quantity INTEGER NOT NULL CHECK (quantity > 0),
 condition VARCHAR(10) NOT NULL CHECK (condition IN ('GOOD','DAMAGED')),
 disposition VARCHAR(10) NOT NULL CHECK (disposition IN ('RESTOCK','DAMAGE','DISPOSE')),
 CHECK ((condition='GOOD' AND disposition='RESTOCK') OR (condition='DAMAGED' AND disposition IN ('DAMAGE','DISPOSE')))
);
CREATE TABLE office_returns (
 document_id BIGINT PRIMARY KEY REFERENCES documents(document_id),
 original_issue_id BIGINT NOT NULL REFERENCES office_issues(document_id),
 total_return_value NUMERIC(12,2) NOT NULL CHECK (total_return_value >= 0)
);
CREATE TABLE office_return_items (
 office_return_item_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 document_id BIGINT NOT NULL REFERENCES office_returns(document_id),
 issue_item_id BIGINT NOT NULL REFERENCES office_issue_items(issue_item_id),
 quantity INTEGER NOT NULL CHECK (quantity > 0),
 original_unit_price NUMERIC(12,2) NOT NULL CHECK (original_unit_price >= 0),
 line_total NUMERIC(12,2) NOT NULL CHECK (line_total >= 0)
);

CREATE TABLE stock_movements (
 movement_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 document_id BIGINT NOT NULL REFERENCES documents(document_id),
 book_id BIGINT NOT NULL REFERENCES books(book_id),
 movement_type VARCHAR(30) NOT NULL CHECK (movement_type IN ('PURCHASE','RETAIL_SALE','WHOLESALE_SALE','OFFICE_ISSUE','OFFICE_RETURN','CUSTOMER_RETURN','DAMAGE','STOCK_ADJUSTMENT','SUPPLIER_REPLACEMENT_OUT','SUPPLIER_REPLACEMENT_IN')),
 quantity_delta INTEGER NOT NULL CHECK (quantity_delta <> 0),
 movement_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 created_by BIGINT NOT NULL REFERENCES users(user_id),
 notes TEXT
);
CREATE INDEX idx_stock_movements_book_date ON stock_movements(book_id, movement_date);

CREATE TABLE financial_accounts (
 account_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 account_name VARCHAR(120) NOT NULL UNIQUE,
 account_type VARCHAR(20) NOT NULL CHECK (account_type IN ('CASH_DRAWER','TREASURY','INSTAPAY','MOBILE_WALLET','BANK','OTHER')),
 owner_user_id BIGINT REFERENCES users(user_id),
 is_default BOOLEAN NOT NULL DEFAULT FALSE,
 is_active BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE UNIQUE INDEX uq_default_financial_account ON financial_accounts(is_default) WHERE is_default;
CREATE TABLE payments (
 document_id BIGINT PRIMARY KEY REFERENCES documents(document_id),
 party_id BIGINT REFERENCES parties(party_id),
 financial_account_id BIGINT NOT NULL REFERENCES financial_accounts(account_id),
 payment_direction VARCHAR(8) NOT NULL CHECK (payment_direction IN ('RECEIVED','PAID')),
 amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
 payment_method VARCHAR(15) CHECK (payment_method IN ('CASH','INSTAPAY','WALLET','BANK','OTHER')),
 related_document_id BIGINT REFERENCES documents(document_id),
 CHECK (party_id IS NOT NULL OR related_document_id IS NOT NULL)
);
CREATE TABLE financial_transactions (
 transaction_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 document_id BIGINT NOT NULL REFERENCES documents(document_id),
 from_account_id BIGINT REFERENCES financial_accounts(account_id),
 to_account_id BIGINT REFERENCES financial_accounts(account_id),
 amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
 transaction_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 CHECK ((from_account_id IS NOT NULL AND to_account_id IS NULL) OR
        (from_account_id IS NULL AND to_account_id IS NOT NULL) OR
        (from_account_id IS NOT NULL AND to_account_id IS NOT NULL AND from_account_id <> to_account_id))
);
CREATE TABLE account_transfers (
 document_id BIGINT PRIMARY KEY REFERENCES documents(document_id),
 source_account_id BIGINT NOT NULL REFERENCES financial_accounts(account_id),
 destination_account_id BIGINT NOT NULL REFERENCES financial_accounts(account_id),
 amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
 CHECK (source_account_id <> destination_account_id)
);
CREATE TABLE expense_categories (
 category_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 category_name VARCHAR(120) NOT NULL UNIQUE,
 is_active BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE expenses (
 document_id BIGINT PRIMARY KEY REFERENCES documents(document_id),
 category_id BIGINT NOT NULL REFERENCES expense_categories(category_id),
 financial_account_id BIGINT NOT NULL REFERENCES financial_accounts(account_id),
 wage_recipient_id BIGINT REFERENCES users(user_id),
 amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
 description TEXT
);

CREATE TABLE stock_counts (
 document_id BIGINT PRIMARY KEY REFERENCES documents(document_id),
 count_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 status VARCHAR(12) NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT','APPROVED','CANCELLED'))
);
CREATE TABLE stock_count_items (
 count_item_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 document_id BIGINT NOT NULL REFERENCES stock_counts(document_id),
 book_id BIGINT NOT NULL REFERENCES books(book_id),
 system_quantity INTEGER NOT NULL CHECK (system_quantity >= 0),
 actual_quantity INTEGER NOT NULL CHECK (actual_quantity >= 0),
 difference INTEGER GENERATED ALWAYS AS (actual_quantity - system_quantity) STORED,
 UNIQUE(document_id, book_id)
);
CREATE TABLE supplier_replacements (
 document_id BIGINT PRIMARY KEY REFERENCES documents(document_id),
 supplier_party_id BIGINT NOT NULL REFERENCES parties(party_id),
 status VARCHAR(12) NOT NULL CHECK (status IN ('PENDING','REPLACED','REJECTED','CLOSED')),
 notes TEXT
);
CREATE TABLE supplier_replacement_items (
 replacement_item_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 document_id BIGINT NOT NULL REFERENCES supplier_replacements(document_id),
 original_purchase_item_id BIGINT REFERENCES purchase_items(purchase_item_id),
 book_id BIGINT NOT NULL REFERENCES books(book_id),
 quantity INTEGER NOT NULL CHECK (quantity > 0),
 status VARCHAR(12) NOT NULL CHECK (status IN ('PENDING','REPLACED','REJECTED')),
 replacement_book_id BIGINT REFERENCES books(book_id)
);
CREATE TABLE daily_closings (
 document_id BIGINT PRIMARY KEY REFERENCES documents(document_id),
 drawer_account_id BIGINT NOT NULL REFERENCES financial_accounts(account_id),
 treasury_account_id BIGINT NOT NULL REFERENCES financial_accounts(account_id),
 closed_by BIGINT NOT NULL REFERENCES users(user_id),
 closing_date DATE NOT NULL UNIQUE,
 expected_cash NUMERIC(12,2) NOT NULL CHECK (expected_cash >= 0),
 actual_cash NUMERIC(12,2) NOT NULL CHECK (actual_cash >= 0),
 difference NUMERIC(12,2) GENERATED ALWAYS AS (actual_cash - expected_cash) STORED,
 transferred_amount NUMERIC(12,2) NOT NULL CHECK (transferred_amount >= 0),
 difference_reason TEXT,
 closed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 CHECK (transferred_amount = actual_cash),
 CHECK (drawer_account_id <> treasury_account_id)
);
CREATE TABLE audit_log (
 audit_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 user_id BIGINT NOT NULL REFERENCES users(user_id),
 entity_type VARCHAR(60) NOT NULL,
 entity_id BIGINT NOT NULL,
 action_type VARCHAR(20) NOT NULL CHECK (action_type IN ('CREATE','UPDATE','POST','VOID','REVERSE','APPROVE','LOGIN')),
 old_values JSONB,
 new_values JSONB,
 reason TEXT,
 action_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_documents_type_date ON documents(document_type, document_date);
CREATE INDEX idx_financial_transactions_date ON financial_transactions(transaction_date);
CREATE INDEX idx_audit_entity ON audit_log(entity_type, entity_id, action_date);

COMMIT;

-- Application/trigger work still required before production:
-- * Post each document and its stock, party-ledger, and financial effects atomically.
-- * Enforce one matching subtype per posted document_type.
-- * Validate header totals against item totals.
-- * Prevent over-returns and over-issues; serialize stock updates to avoid race conditions.
-- * Update stock_quantity and moving weighted average cost atomically on purchase/sale/return.
-- * Use the single payments table for retail and party payments; do not duplicate payment tables.
-- * Create exactly one financial effect per receipt/payment/expense/transfer.
-- * Enforce worker/owner permissions and immutable posted documents.
-- * Seed expense categories and financial accounts before operational use.
