-- Migration 002
-- Document approval and stock movement constraints

ALTER TABLE bookstore.documents
DROP CONSTRAINT documents_check;

ALTER TABLE bookstore.stock_movements
ADD CONSTRAINT chk_stock_movement_direction
CHECK (
    CASE movement_type
        WHEN 'PURCHASE' THEN quantity_delta > 0
        WHEN 'RETAIL_SALE' THEN quantity_delta < 0
        WHEN 'WHOLESALE_SALE' THEN quantity_delta < 0
        WHEN 'OFFICE_ISSUE' THEN quantity_delta < 0
        WHEN 'OFFICE_RETURN' THEN quantity_delta > 0
        WHEN 'CUSTOMER_RETURN' THEN quantity_delta > 0
        WHEN 'DAMAGE' THEN quantity_delta < 0
        WHEN 'SUPPLIER_REPLACEMENT_OUT' THEN quantity_delta < 0
        WHEN 'SUPPLIER_REPLACEMENT_IN' THEN quantity_delta > 0
        WHEN 'STOCK_ADJUSTMENT' THEN quantity_delta <> 0
        ELSE FALSE
    END
);