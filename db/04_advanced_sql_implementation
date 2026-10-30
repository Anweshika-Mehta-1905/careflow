-- ============================================================================
-- 04_advanced_sql_implementation.sql
-- Hospital Management System (HMS) - Advanced SQL Implementation
-- Prepared for VIT BCSE302P Review 3 & Final Evaluation
-- Covers:
--   1. Complex Business Queries (CQ-01 to CQ-10)
--   2. Views (3 Views: Multi-table, Aggregated, Row-Restricting)
--   3. Stored Procedures (2 Procedures)
--   4. User-Defined Functions (2 Functions)
--   5. Triggers (2 Triggers with event handlers)
--   6. Cursors (2 Explicit Cursors)
--   7. SQL Security (Roles, GRANT/REVOKE, Least-Privilege Proof)
-- ============================================================================

-- ============================================================================
-- 2. VIEWS IMPLEMENTATION
-- ============================================================================

-- View 1: Multi-Table Operational View (Joins 5 tables)
-- Purpose: Provides a single consolidated clinical view of patient admission, bed, doctor, and department.
-- Updatability: Non-updatable (joins multiple tables and includes computed expressions).
CREATE OR REPLACE VIEW vw_inpatient_clinical_summary AS
SELECT 
    a.admission_id,
    p.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    p.blood_group,
    p.contact,
    d.first_name || ' ' || d.last_name AS attending_physician,
    dept.dept_name,
    rb.room_no,
    rb.ward_type,
    rb.daily_rate,
    a.admission_date,
    a.discharge_date,
    COALESCE(COUNT(pi.item_id), 0) AS total_prescriptions_issued
FROM admissions a
JOIN patients p ON a.patient_id = p.patient_id
JOIN doctors d ON a.doctor_id = d.doctor_id
JOIN departments dept ON d.dept_id = dept.dept_id
JOIN rooms_beds rb ON a.bed_id = rb.bed_id
LEFT JOIN prescription_items pi ON a.admission_id = pi.admission_id
GROUP BY 
    a.admission_id, p.patient_id, p.first_name, p.last_name, p.blood_group, 
    p.contact, d.first_name, d.last_name, dept.dept_name, rb.room_no, 
    rb.ward_type, rb.daily_rate, a.admission_date, a.discharge_date;

-- View 2: Aggregated Financial Performance View
-- Purpose: Aggregates departmental revenue, length of stay, and patient turnover.
-- Updatability: Non-updatable (contains GROUP BY and aggregate functions SUM, AVG, COUNT).
CREATE OR REPLACE VIEW vw_department_financial_performance AS
SELECT 
    dept.dept_id,
    dept.dept_name,
    COUNT(DISTINCT a.admission_id) AS total_admissions,
    COALESCE(SUM(inv.room_charge), 0) AS total_room_revenue,
    COALESCE(SUM(inv.doctor_charge), 0) AS total_doctor_revenue,
    COALESCE(SUM(inv.pharmacy_charge), 0) AS total_pharmacy_revenue,
    COALESCE(SUM(inv.total_amount), 0) AS total_gross_revenue,
    COALESCE(SUM(CASE WHEN inv.status = 'Paid' THEN inv.total_amount ELSE 0 END), 0) AS total_collected_revenue,
    COALESCE(SUM(CASE WHEN inv.status = 'Pending' THEN inv.total_amount ELSE 0 END), 0) AS total_outstanding_balance
FROM departments dept
LEFT JOIN doctors d ON dept.dept_id = d.dept_id
LEFT JOIN admissions a ON d.doctor_id = a.doctor_id
LEFT JOIN invoices inv ON a.admission_id = inv.admission_id
GROUP BY dept.dept_id, dept.dept_name;

-- View 3: Security & Row-Restricting View (Active Inpatients Only)
-- Purpose: Restricts access to sensitive clinical data of patients currently admitted.
-- Updatability: Updatable for columns of the underlying admissions table; includes WITH CHECK OPTION.
CREATE OR REPLACE VIEW vw_active_inpatients_secure AS
SELECT 
    admission_id, 
    patient_id, 
    bed_id, 
    doctor_id, 
    admission_date, 
    notes
FROM admissions
WHERE discharge_date IS NULL
WITH CHECK OPTION;


-- ============================================================================
-- 3. STORED PROCEDURES (2 Procedures)
-- ============================================================================

-- Procedure 1: Atomic Inpatient Discharge and Billing Computation
-- Calculates length of stay, aggregates charges, generates invoice, and releases bed to 'Sanitizing'.
CREATE OR REPLACE PROCEDURE sp_discharge_patient_procedure(
    p_admission_id INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_bed_id INT;
    v_doctor_id INT;
    v_admission_date TIMESTAMPTZ;
    v_discharge_date TIMESTAMPTZ := NOW();
    v_daily_rate NUMERIC(10,2);
    v_doctor_fee NUMERIC(10,2);
    v_pharmacy_total NUMERIC(10,2) := 0;
    v_days_stayed INT;
    v_room_charge NUMERIC(10,2);
    v_total_amount NUMERIC(10,2);
BEGIN
    -- 1. Validate admission exists and is currently active
    SELECT bed_id, doctor_id, admission_date
    INTO v_bed_id, v_doctor_id, v_admission_date
    FROM admissions
    WHERE admission_id = p_admission_id AND discharge_date IS NULL;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Active admission ID % not found or already discharged', p_admission_id;
    END IF;

    -- 2. Fetch rates
    SELECT daily_rate INTO v_daily_rate FROM rooms_beds WHERE bed_id = v_bed_id;
    SELECT COALESCE(fee, 0) INTO v_doctor_fee FROM doctors WHERE doctor_id = v_doctor_id;

    -- 3. Compute pharmacy subtotal from prescription items
    SELECT COALESCE(SUM(pi.quantity * m.unit_price), 0)
    INTO v_pharmacy_total
    FROM prescription_items pi
    JOIN medications m ON pi.med_id = m.med_id
    WHERE pi.admission_id = p_admission_id;

    -- 4. Calculate length of stay (minimum 1 day)
    v_days_stayed := EXTRACT(DAY FROM (v_discharge_date - v_admission_date));
    IF v_days_stayed <= 0 THEN
        v_days_stayed := 1;
    END IF;
    v_room_charge := v_days_stayed * v_daily_rate;
    v_total_amount := v_room_charge + v_doctor_fee + v_pharmacy_total;

    -- 5. Atomic database updates
    UPDATE admissions 
    SET discharge_date = v_discharge_date 
    WHERE admission_id = p_admission_id;

    INSERT INTO invoices (admission_id, room_charge, doctor_charge, pharmacy_charge, total_amount, status, created_at)
    VALUES (p_admission_id, v_room_charge, v_doctor_fee, v_pharmacy_total, v_total_amount, 'Pending', v_discharge_date);

    UPDATE rooms_beds 
    SET status = 'Sanitizing' 
    WHERE bed_id = v_bed_id;

    RAISE NOTICE 'Admission % discharged. Total invoice: $% generated. Bed % set to Sanitizing.',
        p_admission_id, v_total_amount, v_bed_id;
END;
$$;


-- Procedure 2: Atomic Patient Bed Transfer with Availability Locking
CREATE OR REPLACE PROCEDURE sp_transfer_patient_bed(
    p_admission_id INT,
    p_new_bed_id INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_old_bed_id INT;
    v_target_status VARCHAR(20);
BEGIN
    -- Check target bed status
    SELECT status INTO v_target_status FROM rooms_beds WHERE bed_id = p_new_bed_id;
    IF v_target_status IS NULL THEN
        RAISE EXCEPTION 'Target bed ID % does not exist.', p_new_bed_id;
    END IF;
    IF v_target_status != 'Vacant' THEN
        RAISE EXCEPTION 'Target bed % is currently %, cannot transfer.', p_new_bed_id, v_target_status;
    END IF;

    -- Fetch current bed
    SELECT bed_id INTO v_old_bed_id FROM admissions WHERE admission_id = p_admission_id AND discharge_date IS NULL;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Active admission ID % not found.', p_admission_id;
    END IF;

    -- Reassign bed
    UPDATE admissions SET bed_id = p_new_bed_id WHERE admission_id = p_admission_id;

    -- Release old bed for sanitation and mark new bed occupied
    UPDATE rooms_beds SET status = 'Sanitizing' WHERE bed_id = v_old_bed_id;
    UPDATE rooms_beds SET status = 'Occupied' WHERE bed_id = p_new_bed_id;

    RAISE NOTICE 'Admission % transferred from Bed % to Bed % successfully.',
        p_admission_id, v_old_bed_id, p_new_bed_id;
END;
$$;


-- ============================================================================
-- 4. USER-DEFINED FUNCTIONS (2 Functions)
-- ============================================================================

-- Function 1 (Scalar): Calculate Total Unpaid Pending Balance for Any Patient
CREATE OR REPLACE FUNCTION fn_get_patient_unpaid_balance(p_patient_id INT)
RETURNS NUMERIC AS $$
DECLARE
    v_unpaid_total NUMERIC(10,2) := 0;
BEGIN
    SELECT COALESCE(SUM(inv.total_amount), 0)
    INTO v_unpaid_total
    FROM invoices inv
    JOIN admissions a ON inv.admission_id = a.admission_id
    WHERE a.patient_id = p_patient_id AND inv.status = 'Pending';

    RETURN v_unpaid_total;
END;
$$ LANGUAGE plpgsql;

-- Function 2 (Scalar): Calculate Overall Hospital Bed Occupancy Percentage
CREATE OR REPLACE FUNCTION fn_hospital_occupancy_rate()
RETURNS NUMERIC AS $$
DECLARE
    v_total_beds INT;
    v_occupied_beds INT;
    v_occupancy_pct NUMERIC(5,2);
BEGIN
    SELECT COUNT(*) INTO v_total_beds FROM rooms_beds;
    SELECT COUNT(*) INTO v_occupied_beds FROM rooms_beds WHERE status = 'Occupied';

    IF v_total_beds = 0 THEN
        RETURN 0.00;
    END IF;

    v_occupancy_pct := ROUND((v_occupied_beds::NUMERIC / v_total_beds::NUMERIC) * 100, 2);
    RETURN v_occupancy_pct;
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- 5. TRIGGERS (2 Triggers)
-- ============================================================================

-- Trigger 1: Automatic Inventory Decrement upon Prescription
CREATE OR REPLACE FUNCTION trg_fn_decrement_inventory()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE medications
    SET stock_qty = stock_qty - NEW.quantity
    WHERE med_id = NEW.med_id;

    -- CHECK (stock_qty >= 0) constraint automatically rolls back if insufficient stock
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_decrement_inventory ON prescription_items;
CREATE TRIGGER trg_decrement_inventory
AFTER INSERT ON prescription_items
FOR EACH ROW
EXECUTE FUNCTION trg_fn_decrement_inventory();


-- Trigger 2: Bed State Lock Guard before Admission
CREATE OR REPLACE FUNCTION trg_fn_check_bed_availability()
RETURNS TRIGGER AS $$
DECLARE
    v_status VARCHAR(20);
BEGIN
    SELECT status INTO v_status FROM rooms_beds WHERE bed_id = NEW.bed_id;
    IF v_status != 'Vacant' THEN
        RAISE EXCEPTION 'Admission Conflict: Bed % is currently % and unavailable.', NEW.bed_id, v_status;
    END IF;

    UPDATE rooms_beds SET status = 'Occupied' WHERE bed_id = NEW.bed_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_check_bed_availability ON admissions;
CREATE TRIGGER trg_check_bed_availability
BEFORE INSERT ON admissions
FOR EACH ROW
EXECUTE FUNCTION trg_fn_check_bed_availability();


-- ============================================================================
-- 6. CURSORS (2 Explicit Cursors)
-- ============================================================================

-- Cursor 1: Automated Low-Stock Inventory Auditor
-- Iterates medication records with stock at or below min_threshold and generates procurement alerts
CREATE OR REPLACE PROCEDURE sp_audit_low_stock_cursor()
LANGUAGE plpgsql AS $$
DECLARE
    v_med_id INT;
    v_name VARCHAR(100);
    v_stock INT;
    v_threshold INT;
    cur_low_stock CURSOR FOR 
        SELECT med_id, med_name, stock_qty, min_threshold
        FROM medications
        WHERE stock_qty <= min_threshold;
BEGIN
    OPEN cur_low_stock;
    LOOP
        FETCH cur_low_stock INTO v_med_id, v_name, v_stock, v_threshold;
        EXIT WHEN NOT FOUND;

        RAISE NOTICE '[SUPPLY CHAIN ALERT] Drug ID: % | Name: % | Current Stock: % | Threshold: % (Reorder Recommended)',
            v_med_id, v_name, v_stock, v_threshold;
    END LOOP;
    CLOSE cur_low_stock;
END;
$$;


-- Cursor 2: Overdue Invoices Aging & Escalation Cursor
-- Traverses unpaid pending invoices and flags accounts exceeding 7 days past generation
CREATE OR REPLACE PROCEDURE sp_flag_overdue_invoices_cursor()
LANGUAGE plpgsql AS $$
DECLARE
    v_invoice_id INT;
    v_patient_name TEXT;
    v_amount NUMERIC(10,2);
    v_days_unpaid INT;
    cur_aging CURSOR FOR
        SELECT 
            inv.invoice_id,
            p.first_name || ' ' || p.last_name AS full_name,
            inv.total_amount,
            EXTRACT(DAY FROM (NOW() - inv.created_at))::INT AS days_overdue
        FROM invoices inv
        JOIN admissions a ON inv.admission_id = a.admission_id
        JOIN patients p ON a.patient_id = p.patient_id
        WHERE inv.status = 'Pending';
BEGIN
    OPEN cur_aging;
    LOOP
        FETCH cur_aging INTO v_invoice_id, v_patient_name, v_amount, v_days_unpaid;
        EXIT WHEN NOT FOUND;

        IF v_days_unpaid >= 0 THEN
            RAISE NOTICE '[AGING INVOICE] Inv #%: Patient: % | Outstanding: $% | Aging: % days',
                v_invoice_id, v_patient_name, v_amount, v_days_unpaid;
        END IF;
    END LOOP;
    CLOSE cur_aging;
END;
$$;


-- ============================================================================
-- 7. SQL SECURITY IMPLEMENTATION
-- Roles, GRANT Matrix, REVOKE, and Least-Privilege Proof
-- ============================================================================

-- Step 1: Create 3 Discretionary Access Control Roles
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'hospital_admin_role') THEN
        CREATE ROLE hospital_admin_role WITH LOGIN PASSWORD 'Admin@HMS2026';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'doctor_role') THEN
        CREATE ROLE doctor_role WITH LOGIN PASSWORD 'Doctor@HMS2026';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'receptionist_role') THEN
        CREATE ROLE receptionist_role WITH LOGIN PASSWORD 'Reception@HMS2026';
    END IF;
END
$$;

-- Step 2: Grant Privileges per Role Matrix
-- Admin: Full administrative control
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO hospital_admin_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO hospital_admin_role;

-- Doctor: Read patients & beds; manage prescriptions; view appointments
GRANT SELECT ON patients, rooms_beds, departments, medications TO doctor_role;
GRANT SELECT, UPDATE ON appointments TO doctor_role;
GRANT SELECT, INSERT ON prescription_items TO doctor_role;
GRANT USAGE, SELECT ON SEQUENCE prescription_items_item_id_seq TO doctor_role;
GRANT SELECT ON vw_inpatient_clinical_summary TO doctor_role;

-- Receptionist: Register patients & book appointments; view doctors & beds
GRANT SELECT, INSERT, UPDATE ON patients TO receptionist_role;
GRANT SELECT, INSERT, UPDATE ON appointments TO receptionist_role;
GRANT SELECT ON rooms_beds, doctors, departments TO receptionist_role;
GRANT USAGE, SELECT ON SEQUENCE patients_patient_id_seq, appointments_appointment_id_seq TO receptionist_role;

-- Step 3: REVOKE Demonstration
-- Revoke destructive table deletion rights from Receptionist
REVOKE DELETE ON patients FROM receptionist_role;
REVOKE DELETE ON appointments FROM receptionist_role;

-- Step 4: Least Privilege Proof Verification Queries
-- (To execute and take screenshot):
-- As receptionist_role:
-- 1. Permitted: SELECT * FROM patients; (SUCCEEDS)
-- 2. Forbidden: SELECT * FROM invoices; (ERROR: 42501 permission denied)
-- 3. Forbidden: UPDATE doctors SET fee = 99999.00; (ERROR: 42501 permission denied)


-- ============================================================================
-- 1. COMPLEX BUSINESS QUERIES (CQ-01 to CQ-10)
-- ============================================================================

-- CQ-01: Departmental Inpatient Revenue & Medication Utilization
SELECT 
    dept.dept_id,
    dept.dept_name,
    COUNT(DISTINCT a.admission_id) AS total_inpatients,
    COALESCE(SUM(inv.room_charge), 0) AS total_room_revenue,
    COALESCE(SUM(inv.pharmacy_charge), 0) AS total_pharmacy_revenue,
    COALESCE(SUM(inv.total_amount), 0) AS total_gross_revenue
FROM departments dept
JOIN doctors d ON dept.dept_id = d.dept_id
JOIN admissions a ON d.doctor_id = a.doctor_id
LEFT JOIN invoices inv ON a.admission_id = inv.admission_id
GROUP BY dept.dept_id, dept.dept_name
ORDER BY total_gross_revenue DESC;

-- CQ-02: Critical Care Drug Reconciliation (ICU Inpatients with > 1 Medication)
SELECT 
    p.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    rb.room_no,
    rb.ward_type,
    COUNT(DISTINCT pi.med_id) AS distinct_drugs_prescribed,
    SUM(pi.quantity) AS total_units_administered
FROM patients p
JOIN admissions a ON p.patient_id = a.patient_id
JOIN rooms_beds rb ON a.bed_id = rb.bed_id
JOIN prescription_items pi ON a.admission_id = pi.admission_id
WHERE rb.ward_type = 'ICU'
GROUP BY p.patient_id, p.first_name, p.last_name, rb.room_no, rb.ward_type
HAVING COUNT(DISTINCT pi.med_id) >= 1;

-- CQ-03: Physician Workload Analysis (Doctors with Appointments Above Department Average)
WITH dept_avg AS (
    SELECT 
        d.dept_id,
        AVG(appt_count.total_appts) AS avg_dept_appts
    FROM doctors d
    LEFT JOIN (
        SELECT doctor_id, COUNT(*) AS total_appts 
        FROM appointments 
        GROUP BY doctor_id
    ) appt_count ON d.doctor_id = appt_count.doctor_id
    GROUP BY d.dept_id
)
SELECT 
    d.doctor_id,
    d.first_name || ' ' || d.last_name AS doctor_name,
    dept.dept_name,
    COUNT(a.appointment_id) AS scheduled_appointments,
    ROUND(da.avg_dept_appts, 1) AS department_average
FROM doctors d
JOIN departments dept ON d.dept_id = dept.dept_id
JOIN dept_avg da ON d.dept_id = da.dept_id
LEFT JOIN appointments a ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, d.first_name, d.last_name, dept.dept_name, da.avg_dept_appts
HAVING COUNT(a.appointment_id) >= da.avg_dept_appts;

-- CQ-04: Ward Bed Turnover Rate & Length of Stay Analysis
SELECT 
    rb.ward_type,
    COUNT(a.admission_id) AS completed_admissions,
    ROUND(AVG(EXTRACT(DAY FROM (a.discharge_date - a.admission_date))), 1) AS avg_length_of_stay_days,
    MIN(EXTRACT(DAY FROM (a.discharge_date - a.admission_date))) AS min_stay_days,
    MAX(EXTRACT(DAY FROM (a.discharge_date - a.admission_date))) AS max_stay_days,
    ROUND(AVG(inv.total_amount), 2) AS avg_discharge_bill
FROM rooms_beds rb
JOIN admissions a ON rb.bed_id = a.bed_id
JOIN invoices inv ON a.admission_id = inv.admission_id
WHERE a.discharge_date IS NOT NULL
GROUP BY rb.ward_type;

-- CQ-05: Pharmacy Depletion Velocity & Critical Restock Forecasting
SELECT 
    m.med_id,
    m.med_name,
    m.stock_qty AS current_stock,
    m.min_threshold,
    COALESCE(SUM(pi.quantity), 0) AS total_dispensed_to_inpatients,
    CASE 
        WHEN m.stock_qty <= m.min_threshold THEN 'IMMEDIATE REORDER REQUIRED'
        WHEN m.stock_qty <= (m.min_threshold * 2) THEN 'REORDER WARNING'
        ELSE 'ADEQUATE STOCK'
    END AS stock_urgency_status
FROM medications m
LEFT JOIN prescription_items pi ON m.med_id = pi.med_id
GROUP BY m.med_id, m.med_name, m.stock_qty, m.min_threshold
ORDER BY m.stock_qty ASC;

-- CQ-06: Doctor Revenue Contribution Ranking (Using DENSE_RANK Window Function)
SELECT 
    d.doctor_id,
    d.first_name || ' ' || d.last_name AS physician_name,
    dept.dept_name,
    d.fee AS base_consultation_fee,
    COALESCE(SUM(inv.doctor_charge), 0) AS total_doctor_charges_billed,
    COALESCE(SUM(inv.total_amount), 0) AS total_hospital_billing_generated,
    DENSE_RANK() OVER (ORDER BY COALESCE(SUM(inv.total_amount), 0) DESC) AS revenue_rank
FROM doctors d
JOIN departments dept ON d.dept_id = dept.dept_id
LEFT JOIN admissions a ON d.doctor_id = a.doctor_id
LEFT JOIN invoices inv ON a.admission_id = inv.admission_id
GROUP BY d.doctor_id, d.first_name, d.last_name, dept.dept_name, d.fee;

-- CQ-07: Dual Care Collision Audit (Appointments during Active Inpatient Stay)
SELECT 
    p.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    app.appointment_id,
    app.appt_date AS outpatient_appointment_date,
    adm.admission_id,
    adm.admission_date AS inpatient_admit_date,
    COALESCE(adm.discharge_date, NOW()) AS inpatient_discharge_date
FROM patients p
JOIN appointments app ON p.patient_id = app.patient_id
JOIN admissions adm ON p.patient_id = adm.patient_id
WHERE app.appt_date >= adm.admission_date::DATE
  AND app.appt_date <= COALESCE(adm.discharge_date, NOW())::DATE;

-- CQ-08: Component Cost Distribution Ratio per Patient Stay
SELECT 
    inv.invoice_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    inv.total_amount,
    ROUND((inv.room_charge / NULLIF(inv.total_amount, 0)) * 100, 1) AS room_pct,
    ROUND((inv.doctor_charge / NULLIF(inv.total_amount, 0)) * 100, 1) AS doctor_pct,
    ROUND((inv.pharmacy_charge / NULLIF(inv.total_amount, 0)) * 100, 1) AS pharmacy_pct,
    inv.status AS payment_status
FROM invoices inv
JOIN admissions a ON inv.admission_id = a.admission_id
JOIN patients p ON a.patient_id = p.patient_id
WHERE inv.total_amount > 0
ORDER BY inv.total_amount DESC;

-- CQ-09: Multi-Admission Patient Recurrence (Readmission Tracking)
SELECT 
    p.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    COUNT(a.admission_id) AS total_lifetime_admissions,
    MIN(a.admission_date) AS first_admitted_date,
    MAX(a.admission_date) AS most_recent_admitted_date
FROM patients p
JOIN admissions a ON p.patient_id = a.patient_id
GROUP BY p.patient_id, p.first_name, p.last_name
HAVING COUNT(a.admission_id) >= 1;

-- CQ-10: Facility Floor Staffing Coverage Discrepancy
SELECT 
    dept.floor,
    dept.dept_name,
    COUNT(DISTINCT d.doctor_id) AS active_physicians_count,
    COUNT(DISTINCT rb.bed_id) AS total_beds_on_floor,
    COUNT(DISTINCT CASE WHEN rb.status = 'Occupied' THEN rb.bed_id END) AS occupied_beds_count
FROM departments dept
LEFT JOIN doctors d ON dept.dept_id = d.dept_id
LEFT JOIN rooms_beds rb ON (
    CASE 
        WHEN dept.floor = 1 AND rb.ward_type = 'General' THEN 1
        WHEN dept.floor = 2 AND rb.ward_type = 'Private' THEN 1
        WHEN dept.floor = 3 AND rb.ward_type = 'ICU' THEN 1
        ELSE 0
    END = 1
)
GROUP BY dept.floor, dept.dept_name
ORDER BY dept.floor;

