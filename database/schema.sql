--
-- PostgreSQL database dump
--

\restrict 7V3m3fF88cR0V6817P8dFpqLQkFJ2tXymU2rjlFDtpfvjwq75JJTgvCdybtWWCV

-- Dumped from database version 18.6 (Ubuntu 18.6-0ubuntu0.26.04.1)
-- Dumped by pg_dump version 18.6 (Ubuntu 18.6-0ubuntu0.26.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: bookstore; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA bookstore;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: account_transfers; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.account_transfers (
    document_id bigint NOT NULL,
    source_account_id bigint NOT NULL,
    destination_account_id bigint NOT NULL,
    amount numeric(12,2) NOT NULL,
    CONSTRAINT account_transfers_amount_check CHECK ((amount > (0)::numeric)),
    CONSTRAINT account_transfers_check CHECK ((source_account_id <> destination_account_id))
);


--
-- Name: audit_log; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.audit_log (
    audit_id bigint NOT NULL,
    user_id bigint NOT NULL,
    entity_type character varying(60) NOT NULL,
    entity_id bigint NOT NULL,
    action_type character varying(20) NOT NULL,
    old_values jsonb,
    new_values jsonb,
    reason text,
    action_date timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT audit_log_action_type_check CHECK (((action_type)::text = ANY ((ARRAY['CREATE'::character varying, 'UPDATE'::character varying, 'POST'::character varying, 'VOID'::character varying, 'REVERSE'::character varying, 'APPROVE'::character varying, 'LOGIN'::character varying])::text[])))
);


--
-- Name: audit_log_audit_id_seq; Type: SEQUENCE; Schema: bookstore; Owner: -
--

ALTER TABLE bookstore.audit_log ALTER COLUMN audit_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME bookstore.audit_log_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: books; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.books (
    book_id bigint NOT NULL,
    title character varying(250) NOT NULL,
    author character varying(200) NOT NULL,
    category_id bigint,
    barcode character varying(80) NOT NULL,
    retail_price numeric(12,2) DEFAULT 0 NOT NULL,
    wholesale_price numeric(12,2) DEFAULT 0 NOT NULL,
    average_cost numeric(12,4) DEFAULT 0 NOT NULL,
    stock_quantity integer DEFAULT 0 NOT NULL,
    target_stock_quantity integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT books_average_cost_check CHECK ((average_cost >= (0)::numeric)),
    CONSTRAINT books_retail_price_check CHECK ((retail_price >= (0)::numeric)),
    CONSTRAINT books_stock_quantity_check CHECK ((stock_quantity >= 0)),
    CONSTRAINT books_target_stock_quantity_check CHECK ((target_stock_quantity >= 0)),
    CONSTRAINT books_wholesale_price_check CHECK ((wholesale_price >= (0)::numeric))
);


--
-- Name: books_book_id_seq; Type: SEQUENCE; Schema: bookstore; Owner: -
--

ALTER TABLE bookstore.books ALTER COLUMN book_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME bookstore.books_book_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: categories; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.categories (
    category_id bigint NOT NULL,
    category_name character varying(120) NOT NULL,
    is_active boolean DEFAULT true NOT NULL
);


--
-- Name: categories_category_id_seq; Type: SEQUENCE; Schema: bookstore; Owner: -
--

ALTER TABLE bookstore.categories ALTER COLUMN category_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME bookstore.categories_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: daily_closings; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.daily_closings (
    document_id bigint NOT NULL,
    drawer_account_id bigint NOT NULL,
    treasury_account_id bigint NOT NULL,
    closed_by bigint NOT NULL,
    closing_date date NOT NULL,
    expected_cash numeric(12,2) NOT NULL,
    actual_cash numeric(12,2) NOT NULL,
    difference numeric(12,2) GENERATED ALWAYS AS ((actual_cash - expected_cash)) STORED,
    transferred_amount numeric(12,2) NOT NULL,
    difference_reason text,
    closed_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT daily_closings_actual_cash_check CHECK ((actual_cash >= (0)::numeric)),
    CONSTRAINT daily_closings_check CHECK ((transferred_amount = actual_cash)),
    CONSTRAINT daily_closings_check1 CHECK ((drawer_account_id <> treasury_account_id)),
    CONSTRAINT daily_closings_expected_cash_check CHECK ((expected_cash >= (0)::numeric)),
    CONSTRAINT daily_closings_transferred_amount_check CHECK ((transferred_amount >= (0)::numeric))
);


--
-- Name: documents; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.documents (
    document_id bigint NOT NULL,
    document_number character varying(40) NOT NULL,
    document_type character varying(30) NOT NULL,
    document_date timestamp with time zone DEFAULT now() NOT NULL,
    status character varying(12) DEFAULT 'DRAFT'::character varying NOT NULL,
    created_by bigint NOT NULL,
    approved_by bigint,
    approved_at timestamp with time zone,
    notes text,
    CONSTRAINT documents_document_type_check CHECK (((document_type)::text = ANY ((ARRAY['PURCHASE'::character varying, 'SALE'::character varying, 'SALE_RETURN'::character varying, 'OFFICE_ISSUE'::character varying, 'OFFICE_RETURN'::character varying, 'PAYMENT'::character varying, 'EXPENSE'::character varying, 'TRANSFER'::character varying, 'DAILY_CLOSING'::character varying, 'STOCK_COUNT'::character varying, 'SUPPLIER_REPLACEMENT'::character varying, 'STOCK_ADJUSTMENT'::character varying])::text[]))),
    CONSTRAINT documents_status_check CHECK (((status)::text = ANY ((ARRAY['DRAFT'::character varying, 'POSTED'::character varying, 'VOIDED'::character varying])::text[])))
);


--
-- Name: documents_document_id_seq; Type: SEQUENCE; Schema: bookstore; Owner: -
--

ALTER TABLE bookstore.documents ALTER COLUMN document_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME bookstore.documents_document_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: expense_categories; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.expense_categories (
    category_id bigint NOT NULL,
    category_name character varying(120) NOT NULL,
    is_active boolean DEFAULT true NOT NULL
);


--
-- Name: expense_categories_category_id_seq; Type: SEQUENCE; Schema: bookstore; Owner: -
--

ALTER TABLE bookstore.expense_categories ALTER COLUMN category_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME bookstore.expense_categories_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: expenses; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.expenses (
    document_id bigint NOT NULL,
    category_id bigint NOT NULL,
    financial_account_id bigint NOT NULL,
    wage_recipient_id bigint,
    amount numeric(12,2) NOT NULL,
    description text,
    CONSTRAINT expenses_amount_check CHECK ((amount > (0)::numeric))
);


--
-- Name: financial_accounts; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.financial_accounts (
    account_id bigint NOT NULL,
    account_name character varying(120) NOT NULL,
    account_type character varying(20) NOT NULL,
    owner_user_id bigint,
    is_default boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT financial_accounts_account_type_check CHECK (((account_type)::text = ANY ((ARRAY['CASH_DRAWER'::character varying, 'TREASURY'::character varying, 'INSTAPAY'::character varying, 'MOBILE_WALLET'::character varying, 'BANK'::character varying, 'OTHER'::character varying])::text[])))
);


--
-- Name: financial_accounts_account_id_seq; Type: SEQUENCE; Schema: bookstore; Owner: -
--

ALTER TABLE bookstore.financial_accounts ALTER COLUMN account_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME bookstore.financial_accounts_account_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: financial_transactions; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.financial_transactions (
    transaction_id bigint NOT NULL,
    document_id bigint NOT NULL,
    from_account_id bigint,
    to_account_id bigint,
    amount numeric(12,2) NOT NULL,
    transaction_date timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT financial_transactions_amount_check CHECK ((amount > (0)::numeric)),
    CONSTRAINT financial_transactions_check CHECK ((((from_account_id IS NOT NULL) AND (to_account_id IS NULL)) OR ((from_account_id IS NULL) AND (to_account_id IS NOT NULL)) OR ((from_account_id IS NOT NULL) AND (to_account_id IS NOT NULL) AND (from_account_id <> to_account_id))))
);


--
-- Name: financial_transactions_transaction_id_seq; Type: SEQUENCE; Schema: bookstore; Owner: -
--

ALTER TABLE bookstore.financial_transactions ALTER COLUMN transaction_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME bookstore.financial_transactions_transaction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: office_issue_items; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.office_issue_items (
    issue_item_id bigint NOT NULL,
    document_id bigint NOT NULL,
    book_id bigint NOT NULL,
    quantity integer NOT NULL,
    default_unit_price numeric(12,2) NOT NULL,
    actual_unit_price numeric(12,2) NOT NULL,
    line_total numeric(12,2) NOT NULL,
    unit_cost_snapshot numeric(12,4) NOT NULL,
    CONSTRAINT office_issue_items_actual_unit_price_check CHECK ((actual_unit_price >= (0)::numeric)),
    CONSTRAINT office_issue_items_default_unit_price_check CHECK ((default_unit_price >= (0)::numeric)),
    CONSTRAINT office_issue_items_line_total_check CHECK ((line_total >= (0)::numeric)),
    CONSTRAINT office_issue_items_quantity_check CHECK ((quantity > 0)),
    CONSTRAINT office_issue_items_unit_cost_snapshot_check CHECK ((unit_cost_snapshot >= (0)::numeric))
);


--
-- Name: office_issue_items_issue_item_id_seq; Type: SEQUENCE; Schema: bookstore; Owner: -
--

ALTER TABLE bookstore.office_issue_items ALTER COLUMN issue_item_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME bookstore.office_issue_items_issue_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: office_issues; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.office_issues (
    document_id bigint NOT NULL,
    office_party_id bigint NOT NULL,
    taken_by_name character varying(160) NOT NULL,
    subtotal numeric(12,2) NOT NULL,
    discount_amount numeric(12,2) DEFAULT 0 NOT NULL,
    total_amount numeric(12,2) NOT NULL,
    CONSTRAINT office_issues_check CHECK ((discount_amount <= subtotal)),
    CONSTRAINT office_issues_discount_amount_check CHECK ((discount_amount >= (0)::numeric)),
    CONSTRAINT office_issues_subtotal_check CHECK ((subtotal >= (0)::numeric)),
    CONSTRAINT office_issues_total_amount_check CHECK ((total_amount >= (0)::numeric))
);


--
-- Name: office_return_items; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.office_return_items (
    office_return_item_id bigint NOT NULL,
    document_id bigint NOT NULL,
    issue_item_id bigint NOT NULL,
    quantity integer NOT NULL,
    original_unit_price numeric(12,2) NOT NULL,
    line_total numeric(12,2) NOT NULL,
    CONSTRAINT office_return_items_line_total_check CHECK ((line_total >= (0)::numeric)),
    CONSTRAINT office_return_items_original_unit_price_check CHECK ((original_unit_price >= (0)::numeric)),
    CONSTRAINT office_return_items_quantity_check CHECK ((quantity > 0))
);


--
-- Name: office_return_items_office_return_item_id_seq; Type: SEQUENCE; Schema: bookstore; Owner: -
--

ALTER TABLE bookstore.office_return_items ALTER COLUMN office_return_item_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME bookstore.office_return_items_office_return_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: office_returns; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.office_returns (
    document_id bigint NOT NULL,
    original_issue_id bigint NOT NULL,
    total_return_value numeric(12,2) NOT NULL,
    CONSTRAINT office_returns_total_return_value_check CHECK ((total_return_value >= (0)::numeric))
);


--
-- Name: parties; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.parties (
    party_id bigint NOT NULL,
    party_name character varying(200) NOT NULL,
    phone character varying(40),
    notes text,
    is_active boolean DEFAULT true NOT NULL
);


--
-- Name: parties_party_id_seq; Type: SEQUENCE; Schema: bookstore; Owner: -
--

ALTER TABLE bookstore.parties ALTER COLUMN party_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME bookstore.parties_party_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: party_accounts; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.party_accounts (
    party_account_id bigint NOT NULL,
    party_id bigint NOT NULL,
    account_type character varying(12) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT party_accounts_account_type_check CHECK (((account_type)::text = ANY ((ARRAY['RECEIVABLE'::character varying, 'PAYABLE'::character varying])::text[])))
);


--
-- Name: party_accounts_party_account_id_seq; Type: SEQUENCE; Schema: bookstore; Owner: -
--

ALTER TABLE bookstore.party_accounts ALTER COLUMN party_account_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME bookstore.party_accounts_party_account_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: party_ledger_entries; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.party_ledger_entries (
    entry_id bigint NOT NULL,
    party_account_id bigint NOT NULL,
    document_id bigint NOT NULL,
    entry_type character varying(30) NOT NULL,
    debit numeric(12,2) DEFAULT 0 NOT NULL,
    credit numeric(12,2) DEFAULT 0 NOT NULL,
    entry_date timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT party_ledger_entries_check CHECK ((((debit > (0)::numeric) AND (credit = (0)::numeric)) OR ((credit > (0)::numeric) AND (debit = (0)::numeric)))),
    CONSTRAINT party_ledger_entries_credit_check CHECK ((credit >= (0)::numeric)),
    CONSTRAINT party_ledger_entries_debit_check CHECK ((debit >= (0)::numeric))
);


--
-- Name: party_ledger_entries_entry_id_seq; Type: SEQUENCE; Schema: bookstore; Owner: -
--

ALTER TABLE bookstore.party_ledger_entries ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME bookstore.party_ledger_entries_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: party_roles; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.party_roles (
    party_role_id bigint NOT NULL,
    party_id bigint NOT NULL,
    role_type character varying(24) NOT NULL,
    CONSTRAINT party_roles_role_type_check CHECK (((role_type)::text = ANY ((ARRAY['SUPPLIER'::character varying, 'OFFICE'::character varying, 'WHOLESALE_CUSTOMER'::character varying])::text[])))
);


--
-- Name: party_roles_party_role_id_seq; Type: SEQUENCE; Schema: bookstore; Owner: -
--

ALTER TABLE bookstore.party_roles ALTER COLUMN party_role_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME bookstore.party_roles_party_role_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: payments; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.payments (
    document_id bigint NOT NULL,
    party_id bigint,
    financial_account_id bigint NOT NULL,
    payment_direction character varying(8) NOT NULL,
    amount numeric(12,2) NOT NULL,
    payment_method character varying(15),
    related_document_id bigint,
    CONSTRAINT payments_amount_check CHECK ((amount > (0)::numeric)),
    CONSTRAINT payments_check CHECK (((party_id IS NOT NULL) OR (related_document_id IS NOT NULL))),
    CONSTRAINT payments_payment_direction_check CHECK (((payment_direction)::text = ANY ((ARRAY['RECEIVED'::character varying, 'PAID'::character varying])::text[]))),
    CONSTRAINT payments_payment_method_check CHECK (((payment_method)::text = ANY ((ARRAY['CASH'::character varying, 'INSTAPAY'::character varying, 'WALLET'::character varying, 'BANK'::character varying, 'OTHER'::character varying])::text[])))
);


--
-- Name: purchase_items; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.purchase_items (
    purchase_item_id bigint NOT NULL,
    document_id bigint NOT NULL,
    book_id bigint NOT NULL,
    quantity integer NOT NULL,
    unit_cost numeric(12,4) NOT NULL,
    line_total numeric(12,2) NOT NULL,
    CONSTRAINT purchase_items_line_total_check CHECK ((line_total >= (0)::numeric)),
    CONSTRAINT purchase_items_quantity_check CHECK ((quantity > 0)),
    CONSTRAINT purchase_items_unit_cost_check CHECK ((unit_cost >= (0)::numeric))
);


--
-- Name: purchase_items_purchase_item_id_seq; Type: SEQUENCE; Schema: bookstore; Owner: -
--

ALTER TABLE bookstore.purchase_items ALTER COLUMN purchase_item_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME bookstore.purchase_items_purchase_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: purchases; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.purchases (
    document_id bigint NOT NULL,
    supplier_party_id bigint NOT NULL,
    subtotal numeric(12,2) NOT NULL,
    supplier_discount numeric(12,2) DEFAULT 0 NOT NULL,
    total_amount numeric(12,2) NOT NULL,
    CONSTRAINT purchases_check CHECK ((supplier_discount <= subtotal)),
    CONSTRAINT purchases_subtotal_check CHECK ((subtotal >= (0)::numeric)),
    CONSTRAINT purchases_supplier_discount_check CHECK ((supplier_discount >= (0)::numeric)),
    CONSTRAINT purchases_total_amount_check CHECK ((total_amount >= (0)::numeric))
);


--
-- Name: sale_items; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.sale_items (
    sale_item_id bigint NOT NULL,
    document_id bigint NOT NULL,
    book_id bigint NOT NULL,
    quantity integer NOT NULL,
    default_unit_price numeric(12,2) NOT NULL,
    actual_unit_price numeric(12,2) NOT NULL,
    line_total numeric(12,2) NOT NULL,
    unit_cost_snapshot numeric(12,4) NOT NULL,
    CONSTRAINT sale_items_actual_unit_price_check CHECK ((actual_unit_price >= (0)::numeric)),
    CONSTRAINT sale_items_default_unit_price_check CHECK ((default_unit_price >= (0)::numeric)),
    CONSTRAINT sale_items_line_total_check CHECK ((line_total >= (0)::numeric)),
    CONSTRAINT sale_items_quantity_check CHECK ((quantity > 0)),
    CONSTRAINT sale_items_unit_cost_snapshot_check CHECK ((unit_cost_snapshot >= (0)::numeric))
);


--
-- Name: sale_items_sale_item_id_seq; Type: SEQUENCE; Schema: bookstore; Owner: -
--

ALTER TABLE bookstore.sale_items ALTER COLUMN sale_item_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME bookstore.sale_items_sale_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: sale_return_items; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.sale_return_items (
    return_item_id bigint NOT NULL,
    document_id bigint NOT NULL,
    sale_item_id bigint NOT NULL,
    quantity integer NOT NULL,
    condition character varying(10) NOT NULL,
    disposition character varying(10) NOT NULL,
    CONSTRAINT sale_return_items_check CHECK (((((condition)::text = 'GOOD'::text) AND ((disposition)::text = 'RESTOCK'::text)) OR (((condition)::text = 'DAMAGED'::text) AND ((disposition)::text = ANY ((ARRAY['DAMAGE'::character varying, 'DISPOSE'::character varying])::text[]))))),
    CONSTRAINT sale_return_items_condition_check CHECK (((condition)::text = ANY ((ARRAY['GOOD'::character varying, 'DAMAGED'::character varying])::text[]))),
    CONSTRAINT sale_return_items_disposition_check CHECK (((disposition)::text = ANY ((ARRAY['RESTOCK'::character varying, 'DAMAGE'::character varying, 'DISPOSE'::character varying])::text[]))),
    CONSTRAINT sale_return_items_quantity_check CHECK ((quantity > 0))
);


--
-- Name: sale_return_items_return_item_id_seq; Type: SEQUENCE; Schema: bookstore; Owner: -
--

ALTER TABLE bookstore.sale_return_items ALTER COLUMN return_item_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME bookstore.sale_return_items_return_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: sale_returns; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.sale_returns (
    document_id bigint NOT NULL,
    original_sale_id bigint NOT NULL,
    refund_amount numeric(12,2) DEFAULT 0 NOT NULL,
    CONSTRAINT sale_returns_refund_amount_check CHECK ((refund_amount >= (0)::numeric))
);


--
-- Name: sales; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.sales (
    document_id bigint NOT NULL,
    party_id bigint,
    sale_type character varying(20) NOT NULL,
    subtotal numeric(12,2) NOT NULL,
    discount_amount numeric(12,2) DEFAULT 0 NOT NULL,
    total_amount numeric(12,2) NOT NULL,
    CONSTRAINT sales_check CHECK ((discount_amount <= subtotal)),
    CONSTRAINT sales_discount_amount_check CHECK ((discount_amount >= (0)::numeric)),
    CONSTRAINT sales_sale_type_check CHECK (((sale_type)::text = ANY ((ARRAY['RETAIL'::character varying, 'WHOLESALE_DIRECT'::character varying])::text[]))),
    CONSTRAINT sales_subtotal_check CHECK ((subtotal >= (0)::numeric)),
    CONSTRAINT sales_total_amount_check CHECK ((total_amount >= (0)::numeric))
);


--
-- Name: stock_count_items; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.stock_count_items (
    count_item_id bigint NOT NULL,
    document_id bigint NOT NULL,
    book_id bigint NOT NULL,
    system_quantity integer NOT NULL,
    actual_quantity integer NOT NULL,
    difference integer GENERATED ALWAYS AS ((actual_quantity - system_quantity)) STORED,
    CONSTRAINT stock_count_items_actual_quantity_check CHECK ((actual_quantity >= 0)),
    CONSTRAINT stock_count_items_system_quantity_check CHECK ((system_quantity >= 0))
);


--
-- Name: stock_count_items_count_item_id_seq; Type: SEQUENCE; Schema: bookstore; Owner: -
--

ALTER TABLE bookstore.stock_count_items ALTER COLUMN count_item_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME bookstore.stock_count_items_count_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: stock_counts; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.stock_counts (
    document_id bigint NOT NULL,
    count_date timestamp with time zone DEFAULT now() NOT NULL,
    status character varying(12) DEFAULT 'DRAFT'::character varying NOT NULL,
    CONSTRAINT stock_counts_status_check CHECK (((status)::text = ANY ((ARRAY['DRAFT'::character varying, 'APPROVED'::character varying, 'CANCELLED'::character varying])::text[])))
);


--
-- Name: stock_movements; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.stock_movements (
    movement_id bigint NOT NULL,
    document_id bigint NOT NULL,
    book_id bigint NOT NULL,
    movement_type character varying(30) NOT NULL,
    quantity_delta integer NOT NULL,
    movement_date timestamp with time zone DEFAULT now() NOT NULL,
    created_by bigint NOT NULL,
    notes text,
    CONSTRAINT chk_stock_movement_direction CHECK (
CASE movement_type
    WHEN 'PURCHASE'::text THEN (quantity_delta > 0)
    WHEN 'RETAIL_SALE'::text THEN (quantity_delta < 0)
    WHEN 'WHOLESALE_SALE'::text THEN (quantity_delta < 0)
    WHEN 'OFFICE_ISSUE'::text THEN (quantity_delta < 0)
    WHEN 'OFFICE_RETURN'::text THEN (quantity_delta > 0)
    WHEN 'CUSTOMER_RETURN'::text THEN (quantity_delta > 0)
    WHEN 'DAMAGE'::text THEN (quantity_delta < 0)
    WHEN 'SUPPLIER_REPLACEMENT_OUT'::text THEN (quantity_delta < 0)
    WHEN 'SUPPLIER_REPLACEMENT_IN'::text THEN (quantity_delta > 0)
    WHEN 'STOCK_ADJUSTMENT'::text THEN (quantity_delta <> 0)
    ELSE false
END),
    CONSTRAINT stock_movements_movement_type_check CHECK (((movement_type)::text = ANY ((ARRAY['PURCHASE'::character varying, 'RETAIL_SALE'::character varying, 'WHOLESALE_SALE'::character varying, 'OFFICE_ISSUE'::character varying, 'OFFICE_RETURN'::character varying, 'CUSTOMER_RETURN'::character varying, 'DAMAGE'::character varying, 'STOCK_ADJUSTMENT'::character varying, 'SUPPLIER_REPLACEMENT_OUT'::character varying, 'SUPPLIER_REPLACEMENT_IN'::character varying])::text[]))),
    CONSTRAINT stock_movements_quantity_delta_check CHECK ((quantity_delta <> 0))
);


--
-- Name: stock_movements_movement_id_seq; Type: SEQUENCE; Schema: bookstore; Owner: -
--

ALTER TABLE bookstore.stock_movements ALTER COLUMN movement_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME bookstore.stock_movements_movement_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: supplier_replacement_items; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.supplier_replacement_items (
    replacement_item_id bigint NOT NULL,
    document_id bigint NOT NULL,
    original_purchase_item_id bigint,
    book_id bigint NOT NULL,
    quantity integer NOT NULL,
    status character varying(12) NOT NULL,
    replacement_book_id bigint,
    CONSTRAINT supplier_replacement_items_quantity_check CHECK ((quantity > 0)),
    CONSTRAINT supplier_replacement_items_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'REPLACED'::character varying, 'REJECTED'::character varying])::text[])))
);


--
-- Name: supplier_replacement_items_replacement_item_id_seq; Type: SEQUENCE; Schema: bookstore; Owner: -
--

ALTER TABLE bookstore.supplier_replacement_items ALTER COLUMN replacement_item_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME bookstore.supplier_replacement_items_replacement_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: supplier_replacements; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.supplier_replacements (
    document_id bigint NOT NULL,
    supplier_party_id bigint NOT NULL,
    status character varying(12) NOT NULL,
    notes text,
    CONSTRAINT supplier_replacements_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'REPLACED'::character varying, 'REJECTED'::character varying, 'CLOSED'::character varying])::text[])))
);


--
-- Name: users; Type: TABLE; Schema: bookstore; Owner: -
--

CREATE TABLE bookstore.users (
    user_id bigint NOT NULL,
    username character varying(60) NOT NULL,
    password_hash text NOT NULL,
    full_name character varying(160) NOT NULL,
    role character varying(10) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT users_role_check CHECK (((role)::text = ANY ((ARRAY['OWNER'::character varying, 'WORKER'::character varying])::text[])))
);


--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: bookstore; Owner: -
--

ALTER TABLE bookstore.users ALTER COLUMN user_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME bookstore.users_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: account_transfers account_transfers_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.account_transfers
    ADD CONSTRAINT account_transfers_pkey PRIMARY KEY (document_id);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (audit_id);


--
-- Name: books books_barcode_key; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.books
    ADD CONSTRAINT books_barcode_key UNIQUE (barcode);


--
-- Name: books books_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.books
    ADD CONSTRAINT books_pkey PRIMARY KEY (book_id);


--
-- Name: categories categories_category_name_key; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.categories
    ADD CONSTRAINT categories_category_name_key UNIQUE (category_name);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (category_id);


--
-- Name: daily_closings daily_closings_closing_date_key; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.daily_closings
    ADD CONSTRAINT daily_closings_closing_date_key UNIQUE (closing_date);


--
-- Name: daily_closings daily_closings_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.daily_closings
    ADD CONSTRAINT daily_closings_pkey PRIMARY KEY (document_id);


--
-- Name: documents documents_document_number_key; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.documents
    ADD CONSTRAINT documents_document_number_key UNIQUE (document_number);


--
-- Name: documents documents_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.documents
    ADD CONSTRAINT documents_pkey PRIMARY KEY (document_id);


--
-- Name: expense_categories expense_categories_category_name_key; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.expense_categories
    ADD CONSTRAINT expense_categories_category_name_key UNIQUE (category_name);


--
-- Name: expense_categories expense_categories_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.expense_categories
    ADD CONSTRAINT expense_categories_pkey PRIMARY KEY (category_id);


--
-- Name: expenses expenses_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.expenses
    ADD CONSTRAINT expenses_pkey PRIMARY KEY (document_id);


--
-- Name: financial_accounts financial_accounts_account_name_key; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.financial_accounts
    ADD CONSTRAINT financial_accounts_account_name_key UNIQUE (account_name);


--
-- Name: financial_accounts financial_accounts_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.financial_accounts
    ADD CONSTRAINT financial_accounts_pkey PRIMARY KEY (account_id);


--
-- Name: financial_transactions financial_transactions_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.financial_transactions
    ADD CONSTRAINT financial_transactions_pkey PRIMARY KEY (transaction_id);


--
-- Name: office_issue_items office_issue_items_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.office_issue_items
    ADD CONSTRAINT office_issue_items_pkey PRIMARY KEY (issue_item_id);


--
-- Name: office_issues office_issues_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.office_issues
    ADD CONSTRAINT office_issues_pkey PRIMARY KEY (document_id);


--
-- Name: office_return_items office_return_items_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.office_return_items
    ADD CONSTRAINT office_return_items_pkey PRIMARY KEY (office_return_item_id);


--
-- Name: office_returns office_returns_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.office_returns
    ADD CONSTRAINT office_returns_pkey PRIMARY KEY (document_id);


--
-- Name: parties parties_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.parties
    ADD CONSTRAINT parties_pkey PRIMARY KEY (party_id);


--
-- Name: party_accounts party_accounts_party_id_account_type_key; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.party_accounts
    ADD CONSTRAINT party_accounts_party_id_account_type_key UNIQUE (party_id, account_type);


--
-- Name: party_accounts party_accounts_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.party_accounts
    ADD CONSTRAINT party_accounts_pkey PRIMARY KEY (party_account_id);


--
-- Name: party_ledger_entries party_ledger_entries_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.party_ledger_entries
    ADD CONSTRAINT party_ledger_entries_pkey PRIMARY KEY (entry_id);


--
-- Name: party_roles party_roles_party_id_role_type_key; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.party_roles
    ADD CONSTRAINT party_roles_party_id_role_type_key UNIQUE (party_id, role_type);


--
-- Name: party_roles party_roles_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.party_roles
    ADD CONSTRAINT party_roles_pkey PRIMARY KEY (party_role_id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (document_id);


--
-- Name: purchase_items purchase_items_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.purchase_items
    ADD CONSTRAINT purchase_items_pkey PRIMARY KEY (purchase_item_id);


--
-- Name: purchases purchases_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.purchases
    ADD CONSTRAINT purchases_pkey PRIMARY KEY (document_id);


--
-- Name: sale_items sale_items_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.sale_items
    ADD CONSTRAINT sale_items_pkey PRIMARY KEY (sale_item_id);


--
-- Name: sale_return_items sale_return_items_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.sale_return_items
    ADD CONSTRAINT sale_return_items_pkey PRIMARY KEY (return_item_id);


--
-- Name: sale_returns sale_returns_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.sale_returns
    ADD CONSTRAINT sale_returns_pkey PRIMARY KEY (document_id);


--
-- Name: sales sales_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.sales
    ADD CONSTRAINT sales_pkey PRIMARY KEY (document_id);


--
-- Name: stock_count_items stock_count_items_document_id_book_id_key; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.stock_count_items
    ADD CONSTRAINT stock_count_items_document_id_book_id_key UNIQUE (document_id, book_id);


--
-- Name: stock_count_items stock_count_items_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.stock_count_items
    ADD CONSTRAINT stock_count_items_pkey PRIMARY KEY (count_item_id);


--
-- Name: stock_counts stock_counts_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.stock_counts
    ADD CONSTRAINT stock_counts_pkey PRIMARY KEY (document_id);


--
-- Name: stock_movements stock_movements_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.stock_movements
    ADD CONSTRAINT stock_movements_pkey PRIMARY KEY (movement_id);


--
-- Name: supplier_replacement_items supplier_replacement_items_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.supplier_replacement_items
    ADD CONSTRAINT supplier_replacement_items_pkey PRIMARY KEY (replacement_item_id);


--
-- Name: supplier_replacements supplier_replacements_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.supplier_replacements
    ADD CONSTRAINT supplier_replacements_pkey PRIMARY KEY (document_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: idx_audit_entity; Type: INDEX; Schema: bookstore; Owner: -
--

CREATE INDEX idx_audit_entity ON bookstore.audit_log USING btree (entity_type, entity_id, action_date);


--
-- Name: idx_books_title; Type: INDEX; Schema: bookstore; Owner: -
--

CREATE INDEX idx_books_title ON bookstore.books USING btree (title);


--
-- Name: idx_documents_type_date; Type: INDEX; Schema: bookstore; Owner: -
--

CREATE INDEX idx_documents_type_date ON bookstore.documents USING btree (document_type, document_date);


--
-- Name: idx_financial_transactions_date; Type: INDEX; Schema: bookstore; Owner: -
--

CREATE INDEX idx_financial_transactions_date ON bookstore.financial_transactions USING btree (transaction_date);


--
-- Name: idx_party_ledger_account_date; Type: INDEX; Schema: bookstore; Owner: -
--

CREATE INDEX idx_party_ledger_account_date ON bookstore.party_ledger_entries USING btree (party_account_id, entry_date);


--
-- Name: idx_stock_movements_book_date; Type: INDEX; Schema: bookstore; Owner: -
--

CREATE INDEX idx_stock_movements_book_date ON bookstore.stock_movements USING btree (book_id, movement_date);


--
-- Name: uq_default_financial_account; Type: INDEX; Schema: bookstore; Owner: -
--

CREATE UNIQUE INDEX uq_default_financial_account ON bookstore.financial_accounts USING btree (is_default) WHERE is_default;


--
-- Name: account_transfers account_transfers_destination_account_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.account_transfers
    ADD CONSTRAINT account_transfers_destination_account_id_fkey FOREIGN KEY (destination_account_id) REFERENCES bookstore.financial_accounts(account_id);


--
-- Name: account_transfers account_transfers_document_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.account_transfers
    ADD CONSTRAINT account_transfers_document_id_fkey FOREIGN KEY (document_id) REFERENCES bookstore.documents(document_id);


--
-- Name: account_transfers account_transfers_source_account_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.account_transfers
    ADD CONSTRAINT account_transfers_source_account_id_fkey FOREIGN KEY (source_account_id) REFERENCES bookstore.financial_accounts(account_id);


--
-- Name: audit_log audit_log_user_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.audit_log
    ADD CONSTRAINT audit_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES bookstore.users(user_id);


--
-- Name: books books_category_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.books
    ADD CONSTRAINT books_category_id_fkey FOREIGN KEY (category_id) REFERENCES bookstore.categories(category_id);


--
-- Name: daily_closings daily_closings_closed_by_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.daily_closings
    ADD CONSTRAINT daily_closings_closed_by_fkey FOREIGN KEY (closed_by) REFERENCES bookstore.users(user_id);


--
-- Name: daily_closings daily_closings_document_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.daily_closings
    ADD CONSTRAINT daily_closings_document_id_fkey FOREIGN KEY (document_id) REFERENCES bookstore.documents(document_id);


--
-- Name: daily_closings daily_closings_drawer_account_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.daily_closings
    ADD CONSTRAINT daily_closings_drawer_account_id_fkey FOREIGN KEY (drawer_account_id) REFERENCES bookstore.financial_accounts(account_id);


--
-- Name: daily_closings daily_closings_treasury_account_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.daily_closings
    ADD CONSTRAINT daily_closings_treasury_account_id_fkey FOREIGN KEY (treasury_account_id) REFERENCES bookstore.financial_accounts(account_id);


--
-- Name: documents documents_approved_by_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.documents
    ADD CONSTRAINT documents_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES bookstore.users(user_id);


--
-- Name: documents documents_created_by_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.documents
    ADD CONSTRAINT documents_created_by_fkey FOREIGN KEY (created_by) REFERENCES bookstore.users(user_id);


--
-- Name: expenses expenses_category_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.expenses
    ADD CONSTRAINT expenses_category_id_fkey FOREIGN KEY (category_id) REFERENCES bookstore.expense_categories(category_id);


--
-- Name: expenses expenses_document_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.expenses
    ADD CONSTRAINT expenses_document_id_fkey FOREIGN KEY (document_id) REFERENCES bookstore.documents(document_id);


--
-- Name: expenses expenses_financial_account_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.expenses
    ADD CONSTRAINT expenses_financial_account_id_fkey FOREIGN KEY (financial_account_id) REFERENCES bookstore.financial_accounts(account_id);


--
-- Name: expenses expenses_wage_recipient_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.expenses
    ADD CONSTRAINT expenses_wage_recipient_id_fkey FOREIGN KEY (wage_recipient_id) REFERENCES bookstore.users(user_id);


--
-- Name: financial_accounts financial_accounts_owner_user_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.financial_accounts
    ADD CONSTRAINT financial_accounts_owner_user_id_fkey FOREIGN KEY (owner_user_id) REFERENCES bookstore.users(user_id);


--
-- Name: financial_transactions financial_transactions_document_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.financial_transactions
    ADD CONSTRAINT financial_transactions_document_id_fkey FOREIGN KEY (document_id) REFERENCES bookstore.documents(document_id);


--
-- Name: financial_transactions financial_transactions_from_account_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.financial_transactions
    ADD CONSTRAINT financial_transactions_from_account_id_fkey FOREIGN KEY (from_account_id) REFERENCES bookstore.financial_accounts(account_id);


--
-- Name: financial_transactions financial_transactions_to_account_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.financial_transactions
    ADD CONSTRAINT financial_transactions_to_account_id_fkey FOREIGN KEY (to_account_id) REFERENCES bookstore.financial_accounts(account_id);


--
-- Name: office_issue_items office_issue_items_book_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.office_issue_items
    ADD CONSTRAINT office_issue_items_book_id_fkey FOREIGN KEY (book_id) REFERENCES bookstore.books(book_id);


--
-- Name: office_issue_items office_issue_items_document_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.office_issue_items
    ADD CONSTRAINT office_issue_items_document_id_fkey FOREIGN KEY (document_id) REFERENCES bookstore.office_issues(document_id);


--
-- Name: office_issues office_issues_document_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.office_issues
    ADD CONSTRAINT office_issues_document_id_fkey FOREIGN KEY (document_id) REFERENCES bookstore.documents(document_id);


--
-- Name: office_issues office_issues_office_party_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.office_issues
    ADD CONSTRAINT office_issues_office_party_id_fkey FOREIGN KEY (office_party_id) REFERENCES bookstore.parties(party_id);


--
-- Name: office_return_items office_return_items_document_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.office_return_items
    ADD CONSTRAINT office_return_items_document_id_fkey FOREIGN KEY (document_id) REFERENCES bookstore.office_returns(document_id);


--
-- Name: office_return_items office_return_items_issue_item_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.office_return_items
    ADD CONSTRAINT office_return_items_issue_item_id_fkey FOREIGN KEY (issue_item_id) REFERENCES bookstore.office_issue_items(issue_item_id);


--
-- Name: office_returns office_returns_document_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.office_returns
    ADD CONSTRAINT office_returns_document_id_fkey FOREIGN KEY (document_id) REFERENCES bookstore.documents(document_id);


--
-- Name: office_returns office_returns_original_issue_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.office_returns
    ADD CONSTRAINT office_returns_original_issue_id_fkey FOREIGN KEY (original_issue_id) REFERENCES bookstore.office_issues(document_id);


--
-- Name: party_accounts party_accounts_party_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.party_accounts
    ADD CONSTRAINT party_accounts_party_id_fkey FOREIGN KEY (party_id) REFERENCES bookstore.parties(party_id);


--
-- Name: party_ledger_entries party_ledger_entries_document_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.party_ledger_entries
    ADD CONSTRAINT party_ledger_entries_document_id_fkey FOREIGN KEY (document_id) REFERENCES bookstore.documents(document_id);


--
-- Name: party_ledger_entries party_ledger_entries_party_account_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.party_ledger_entries
    ADD CONSTRAINT party_ledger_entries_party_account_id_fkey FOREIGN KEY (party_account_id) REFERENCES bookstore.party_accounts(party_account_id);


--
-- Name: party_roles party_roles_party_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.party_roles
    ADD CONSTRAINT party_roles_party_id_fkey FOREIGN KEY (party_id) REFERENCES bookstore.parties(party_id);


--
-- Name: payments payments_document_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.payments
    ADD CONSTRAINT payments_document_id_fkey FOREIGN KEY (document_id) REFERENCES bookstore.documents(document_id);


--
-- Name: payments payments_financial_account_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.payments
    ADD CONSTRAINT payments_financial_account_id_fkey FOREIGN KEY (financial_account_id) REFERENCES bookstore.financial_accounts(account_id);


--
-- Name: payments payments_party_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.payments
    ADD CONSTRAINT payments_party_id_fkey FOREIGN KEY (party_id) REFERENCES bookstore.parties(party_id);


--
-- Name: payments payments_related_document_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.payments
    ADD CONSTRAINT payments_related_document_id_fkey FOREIGN KEY (related_document_id) REFERENCES bookstore.documents(document_id);


--
-- Name: purchase_items purchase_items_book_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.purchase_items
    ADD CONSTRAINT purchase_items_book_id_fkey FOREIGN KEY (book_id) REFERENCES bookstore.books(book_id);


--
-- Name: purchase_items purchase_items_document_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.purchase_items
    ADD CONSTRAINT purchase_items_document_id_fkey FOREIGN KEY (document_id) REFERENCES bookstore.purchases(document_id);


--
-- Name: purchases purchases_document_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.purchases
    ADD CONSTRAINT purchases_document_id_fkey FOREIGN KEY (document_id) REFERENCES bookstore.documents(document_id);


--
-- Name: purchases purchases_supplier_party_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.purchases
    ADD CONSTRAINT purchases_supplier_party_id_fkey FOREIGN KEY (supplier_party_id) REFERENCES bookstore.parties(party_id);


--
-- Name: sale_items sale_items_book_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.sale_items
    ADD CONSTRAINT sale_items_book_id_fkey FOREIGN KEY (book_id) REFERENCES bookstore.books(book_id);


--
-- Name: sale_items sale_items_document_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.sale_items
    ADD CONSTRAINT sale_items_document_id_fkey FOREIGN KEY (document_id) REFERENCES bookstore.sales(document_id);


--
-- Name: sale_return_items sale_return_items_document_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.sale_return_items
    ADD CONSTRAINT sale_return_items_document_id_fkey FOREIGN KEY (document_id) REFERENCES bookstore.sale_returns(document_id);


--
-- Name: sale_return_items sale_return_items_sale_item_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.sale_return_items
    ADD CONSTRAINT sale_return_items_sale_item_id_fkey FOREIGN KEY (sale_item_id) REFERENCES bookstore.sale_items(sale_item_id);


--
-- Name: sale_returns sale_returns_document_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.sale_returns
    ADD CONSTRAINT sale_returns_document_id_fkey FOREIGN KEY (document_id) REFERENCES bookstore.documents(document_id);


--
-- Name: sale_returns sale_returns_original_sale_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.sale_returns
    ADD CONSTRAINT sale_returns_original_sale_id_fkey FOREIGN KEY (original_sale_id) REFERENCES bookstore.sales(document_id);


--
-- Name: sales sales_document_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.sales
    ADD CONSTRAINT sales_document_id_fkey FOREIGN KEY (document_id) REFERENCES bookstore.documents(document_id);


--
-- Name: sales sales_party_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.sales
    ADD CONSTRAINT sales_party_id_fkey FOREIGN KEY (party_id) REFERENCES bookstore.parties(party_id);


--
-- Name: stock_count_items stock_count_items_book_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.stock_count_items
    ADD CONSTRAINT stock_count_items_book_id_fkey FOREIGN KEY (book_id) REFERENCES bookstore.books(book_id);


--
-- Name: stock_count_items stock_count_items_document_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.stock_count_items
    ADD CONSTRAINT stock_count_items_document_id_fkey FOREIGN KEY (document_id) REFERENCES bookstore.stock_counts(document_id);


--
-- Name: stock_counts stock_counts_document_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.stock_counts
    ADD CONSTRAINT stock_counts_document_id_fkey FOREIGN KEY (document_id) REFERENCES bookstore.documents(document_id);


--
-- Name: stock_movements stock_movements_book_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.stock_movements
    ADD CONSTRAINT stock_movements_book_id_fkey FOREIGN KEY (book_id) REFERENCES bookstore.books(book_id);


--
-- Name: stock_movements stock_movements_created_by_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.stock_movements
    ADD CONSTRAINT stock_movements_created_by_fkey FOREIGN KEY (created_by) REFERENCES bookstore.users(user_id);


--
-- Name: stock_movements stock_movements_document_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.stock_movements
    ADD CONSTRAINT stock_movements_document_id_fkey FOREIGN KEY (document_id) REFERENCES bookstore.documents(document_id);


--
-- Name: supplier_replacement_items supplier_replacement_items_book_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.supplier_replacement_items
    ADD CONSTRAINT supplier_replacement_items_book_id_fkey FOREIGN KEY (book_id) REFERENCES bookstore.books(book_id);


--
-- Name: supplier_replacement_items supplier_replacement_items_document_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.supplier_replacement_items
    ADD CONSTRAINT supplier_replacement_items_document_id_fkey FOREIGN KEY (document_id) REFERENCES bookstore.supplier_replacements(document_id);


--
-- Name: supplier_replacement_items supplier_replacement_items_original_purchase_item_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.supplier_replacement_items
    ADD CONSTRAINT supplier_replacement_items_original_purchase_item_id_fkey FOREIGN KEY (original_purchase_item_id) REFERENCES bookstore.purchase_items(purchase_item_id);


--
-- Name: supplier_replacement_items supplier_replacement_items_replacement_book_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.supplier_replacement_items
    ADD CONSTRAINT supplier_replacement_items_replacement_book_id_fkey FOREIGN KEY (replacement_book_id) REFERENCES bookstore.books(book_id);


--
-- Name: supplier_replacements supplier_replacements_document_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.supplier_replacements
    ADD CONSTRAINT supplier_replacements_document_id_fkey FOREIGN KEY (document_id) REFERENCES bookstore.documents(document_id);


--
-- Name: supplier_replacements supplier_replacements_supplier_party_id_fkey; Type: FK CONSTRAINT; Schema: bookstore; Owner: -
--

ALTER TABLE ONLY bookstore.supplier_replacements
    ADD CONSTRAINT supplier_replacements_supplier_party_id_fkey FOREIGN KEY (supplier_party_id) REFERENCES bookstore.parties(party_id);


--
-- PostgreSQL database dump complete
--

\unrestrict 7V3m3fF88cR0V6817P8dFpqLQkFJ2tXymU2rjlFDtpfvjwq75JJTgvCdybtWWCV

