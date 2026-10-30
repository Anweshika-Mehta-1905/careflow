-- ============================================================================
-- 03_review2_queries.sql
-- Complete Query Suite for Review 2 Evaluation (VIT BCSE302P)
-- Hospital Management System (HMS)
-- Covers Categories A through G as per the exact evaluation rubric
-- ============================================================================

-- ============================================================================
-- CATEGORY A: BASIC QUERIES (Min 6 Required - 7 Provided)
-- Coverage: SELECT, WHERE, ORDER BY, DISTINCT, BETWEEN, IN, LIKE, IS NULL
-- ============================================================================

-- Q-A01 [SELECT & WHERE]: Retrieve all active doctors with fee above 1000 INR
SELECT doctor_id, first_name, last_name, specialization, fee, phone 
FROM doctors 
WHERE fee >= 1000.00;

-- Q-A02 [ORDER BY]: List all patients sorted by date of birth (youngest first)
SELECT patient_id, first_name, last_name, dob, gender, blood_group 
FROM patients 
ORDER BY dob DESC;

-- Q-A03 [DISTINCT]: List all distinct ward types currently configured in hospital
SELECT DISTINCT ward_type 
FROM rooms_beds;

-- Q-A04 [BETWEEN]: Medications priced between 10.00 and 50.00 INR
SELECT med_id, med_name, unit_price, stock_qty 
FROM medications 
WHERE unit_price BETWEEN 10.00 AND 50.00;

-- Q-A05 [IN]: Patients with universal donor / specific emergency blood groups
SELECT patient_id, first_name, last_name, blood_group, contact 
FROM patients 
WHERE blood_group IN ('O+', 'O-', 'AB+');

-- Q-A06 [LIKE]: Pattern search for doctors whose last name starts with 'S'
SELECT doctor_id, first_name, last_name, specialization, phone 
FROM doctors 
WHERE last_name LIKE 'S%';

-- Q-A07 [IS NULL]: List active inpatient admissions (patients currently in hospital)
SELECT admission_id, patient_id, bed_id, doctor_id, admission_date 
FROM admissions 
WHERE discharge_date IS NULL;



-- ============================================================================
-- CATEGORY B: AGGREGATE QUERIES (Min 5 Required - 5 Provided)
-- Coverage: COUNT, SUM, AVG, MIN, MAX, GROUP BY, HAVING
-- Mandatory requirement: Contrast WHERE vs. HAVING in one query
-- ============================================================================

-- Q-B01 [COUNT, MIN, MAX]: Overall demographic summary of registered patients
SELECT 
    COUNT(*) AS total_patients_registered,
    MIN(dob) AS oldest_patient_birthdate,
    MAX(dob) AS youngest_patient_birthdate
FROM patients;

-- Q-B02 [AVG & SUM]: Revenue potential and average doctor consultation fee
SELECT 
    ROUND(AVG(fee), 2) AS average_consultation_fee,
    SUM(fee) AS potential_single_round_revenue
FROM doctors;

-- Q-B03 [GROUP BY with COUNT]: Count of beds and average daily rate per ward type
SELECT 
    ward_type, 
    COUNT(*) AS total_beds, 
    ROUND(AVG(daily_rate), 2) AS avg_daily_rate
FROM rooms_beds 
GROUP BY ward_type;

-- Q-B04 [MANDATORY WHERE vs. HAVING CONTRAST QUERY]:
-- Demonstrates the fundamental difference:
-- - WHERE filters individual doctor rows BEFORE grouping (fee >= 1000)
-- - HAVING filters aggregated department groups AFTER grouping (COUNT >= 1)
SELECT 
    d.dept_id, 
    dp.dept_name, 
    COUNT(d.doctor_id) AS senior_doctor_count, 
    ROUND(AVG(d.fee), 2) AS avg_senior_fee
FROM doctors d
JOIN departments dp ON d.dept_id = dp.dept_id
WHERE d.fee >= 1000.00             -- WHERE: Filters individual rows before grouping
GROUP BY d.dept_id, dp.dept_name
HAVING COUNT(d.doctor_id) >= 1;    -- HAVING: Filters groups after aggregation

-- Q-B05 [GROUP BY with HAVING]: Ward types with total bed capacity greater than 3
SELECT 
    ward_type,
    COUNT(bed_id) AS total_beds_configured,
    MIN(daily_rate) AS min_rate,
    MAX(daily_rate) AS max_rate
FROM rooms_beds
GROUP BY ward_type
HAVING COUNT(bed_id) >= 3;



-- ============================================================================
-- CATEGORY C: JOINS (Min 6 Required - 6 Provided)
-- Coverage: INNER, LEFT, RIGHT, FULL OUTER, SELF, CROSS (Meaningful Use)
-- ============================================================================

-- Q-C01 [INNER JOIN]: Doctors paired with their primary clinical department
SELECT 
    d.doctor_id, 
    d.first_name || ' ' || d.last_name AS doctor_name, 
    d.specialization, 
    dp.dept_name, 
    dp.floor
FROM doctors d
INNER JOIN departments dp ON d.dept_id = dp.dept_id;

-- Q-C02 [LEFT JOIN]: All departments, preserving departments even if head doctor is unassigned
SELECT 
    dp.dept_id, 
    dp.dept_name, 
    dp.floor,
    COALESCE(d.first_name || ' ' || d.last_name, 'Unassigned') AS head_physician
FROM departments dp
LEFT JOIN doctors d ON dp.head_doctor_id = d.doctor_id;

-- Q-C03 [RIGHT JOIN]: All doctors, showing which department they head (if any)
SELECT 
    d.doctor_id, 
    d.first_name || ' ' || d.last_name AS doctor_name, 
    dp.dept_name AS heads_department
FROM departments dp
RIGHT JOIN doctors d ON dp.head_doctor_id = d.doctor_id;

-- Q-C04 [FULL OUTER JOIN]: Full matrix of beds and admissions (showing both vacant beds & past admissions)
SELECT 
    rb.bed_id, 
    rb.room_no, 
    rb.ward_type, 
    ad.admission_id, 
    ad.admission_date
FROM rooms_beds rb
FULL OUTER JOIN admissions ad ON rb.bed_id = ad.bed_id;

-- Q-C05 [SELF JOIN]: Pairs of distinct doctors who charge the exact same consultation fee
SELECT 
    d1.first_name || ' ' || d1.last_name AS doctor_1,
    d2.first_name || ' ' || d2.last_name AS doctor_2,
    d1.fee AS shared_consultation_fee
FROM doctors d1
JOIN doctors d2 ON d1.fee = d2.fee AND d1.doctor_id < d2.doctor_id;

-- Q-C06 [CROSS JOIN - Meaningful Use]: Staffing matrix - assigns every doctor against every ward type for emergency roster planning
SELECT 
    d.first_name || ' ' || d.last_name AS on_call_doctor,
    w.ward_type AS designated_ward_coverage
FROM doctors d
CROSS JOIN (SELECT DISTINCT ward_type FROM rooms_beds) w
ORDER BY on_call_doctor, designated_ward_coverage;



-- ============================================================================
-- CATEGORY D: SUBQUERIES (Min 6 Required - 7 Provided)
-- Coverage: Scalar, Single-Row, Multi-Row (IN/ANY/ALL), Correlated, EXISTS, NOT EXISTS, NOT IN (with NULL pitfall note)
-- ============================================================================

-- Q-D01 [Scalar Subquery]: Find doctors whose consultation fee is higher than the hospital average
SELECT 
    doctor_id, 
    first_name, 
    last_name, 
    fee
FROM doctors
WHERE fee > (SELECT AVG(fee) FROM doctors);

-- Q-D02 [Single-Row Subquery]: Retrieve the cheapest medication available in the pharmacy
SELECT 
    med_id, 
    med_name, 
    unit_price
FROM medications
WHERE unit_price = (SELECT MIN(unit_price) FROM medications);

-- Q-D03 [Multi-Row Subquery with IN]: Patients who have at least one inpatient admission
SELECT 
    patient_id, 
    first_name, 
    last_name, 
    contact
FROM patients
WHERE patient_id IN (SELECT DISTINCT patient_id FROM admissions);

-- Q-D04 [Multi-Row Subquery with ALL]: Beds with daily rate higher than ALL General ward beds
SELECT 
    bed_id, 
    room_no, 
    ward_type, 
    daily_rate
FROM rooms_beds
WHERE daily_rate > ALL (
    SELECT daily_rate FROM rooms_beds WHERE ward_type = 'General'
);

-- Q-D05 [Correlated Subquery]: Doctors charging the maximum fee within their respective department
SELECT 
    d.doctor_id, 
    d.first_name, 
    d.last_name, 
    d.dept_id, 
    d.fee
FROM doctors d
WHERE d.fee = (
    SELECT MAX(sub.fee) 
    FROM doctors sub 
    WHERE sub.dept_id = d.dept_id
);

-- Q-D06 [EXISTS & NOT EXISTS]:
-- (a) Departments with active admitted patients:
SELECT dept_id, dept_name 
FROM departments dp
WHERE EXISTS (
    SELECT 1 FROM doctors doc 
    JOIN admissions adm ON doc.doctor_id = adm.doctor_id 
    WHERE doc.dept_id = dp.dept_id AND adm.discharge_date IS NULL
);

-- (b) Patients who have NEVER booked an outpatient appointment (NOT EXISTS):
SELECT p.patient_id, p.first_name, p.last_name 
FROM patients p
WHERE NOT EXISTS (
    SELECT 1 FROM appointments a WHERE a.patient_id = p.patient_id
);

-- Q-D07 [NOT IN WITH MANDATORY NULL-PITFALL NOTE]:
-- ⚠️ NULL PITFALL NOTE: In SQL 3-valued logic, if the subquery returns even a single NULL,
-- evaluating `val NOT IN (subquery)` results in UNKNOWN for all rows, producing an empty result set!
-- Therefore, an explicit `WHERE column IS NOT NULL` in the subquery is mandatory for correctness.
SELECT 
    patient_id, 
    first_name, 
    last_name 
FROM patients
WHERE patient_id NOT IN (
    SELECT patient_id 
    FROM appointments 
    WHERE patient_id IS NOT NULL   -- Prevents SQL NULL evaluation pitfall
);



-- ============================================================================
-- CATEGORY E: SET OPERATIONS (Min 4 Required - 4 Provided)
-- Coverage: UNION, UNION ALL, INTERSECT, EXCEPT/MINUS
-- ============================================================================

-- Q-E01 [UNION]: Consolidated emergency contact directory (removes duplicate phone numbers)
SELECT first_name, last_name, phone AS contact_number, 'Physician' AS designation 
FROM doctors 
WHERE phone IS NOT NULL
UNION
SELECT first_name, last_name, contact AS contact_number, 'Patient' AS designation 
FROM patients 
WHERE contact IS NOT NULL;

-- Q-E02 [UNION ALL]: Audit listing of all entity IDs across departments and bed units (preserves all records)
SELECT dept_id AS entity_id, dept_name AS entity_name, 'Department' AS entity_type 
FROM departments
UNION ALL
SELECT bed_id AS entity_id, room_no AS entity_name, 'Bed Unit' AS entity_type 
FROM rooms_beds;

-- Q-E03 [INTERSECT]: Patients who have BOTH an outpatient appointment AND an inpatient admission
SELECT patient_id FROM appointments
INTERSECT
SELECT patient_id FROM admissions;

-- Q-E04 [EXCEPT / MINUS]: Patients registered in system who have NEVER been admitted as inpatients
SELECT patient_id, first_name, last_name FROM patients
EXCEPT
SELECT p.patient_id, p.first_name, p.last_name 
FROM patients p 
JOIN admissions a ON p.patient_id = a.patient_id;



-- ============================================================================
-- CATEGORY F: ADVANCED FUNCTIONS (Min 6 Required - 6 Provided)
-- Coverage: CASE, COALESCE, NULLIF, Date/Time, String, Numeric functions
-- ============================================================================

-- Q-F01 [CASE]: Categorize doctor fee rates into service tiers
SELECT 
    first_name || ' ' || last_name AS doctor_name, 
    fee,
    CASE 
        WHEN fee >= 1500 THEN 'Tier 1 - Senior Specialist'
        WHEN fee >= 1100 THEN 'Tier 2 - Consultant Physician'
        ELSE 'Tier 3 - General Practitioner'
    END AS fee_tier
FROM doctors;
-- Q-F02 [COALESCE]: Display department head or 'Interim / Vacant' fallback when NULL
SELECT 
    dp.dept_name,
    COALESCE(d.first_name || ' ' || d.last_name, 'Interim / Vacant') AS current_head
FROM departments dp
LEFT JOIN doctors d ON dp.head_doctor_id = d.doctor_id;
-- Q-F03 [NULLIF]: Safe division helper - returns NULL if count of occupied beds is 0
SELECT 
    ward_type,
    COUNT(*) AS total_beds,
    NULLIF(COUNT(CASE WHEN status = 'Occupied' THEN 1 END), 0) AS occupied_bed_count
FROM rooms_beds
GROUP BY ward_type;
-- Q-F04 [STRING FUNCTIONS]: Formatting patient names and generating formatted Hospital Record IDs
SELECT 
    UPPER(last_name) || ', ' || SUBSTRING(first_name, 1, 1) || '.' AS formal_display_name,
    CONCAT('HMS-PAT-', LPAD(patient_id::TEXT, 5, '0')) AS institutional_record_code
FROM patients;
-- Q-F05 [DATE/TIME FUNCTIONS]: Calculate exact patient age in years from DOB using AGE and EXTRACT
SELECT 
    first_name, 
    last_name, 
    dob,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, dob)) AS patient_age_years
FROM patients;

-- Q-F06 [NUMERIC FUNCTIONS]: Rounding medication prices with 18% GST and Ceiling calculation
SELECT 
    med_name, 
    unit_price,
    ROUND(unit_price * 1.18, 2) AS price_inclusive_gst,
    CEIL(unit_price) AS rounded_billing_rate
FROM medications;



-- ============================================================================
-- CATEGORY G: WINDOW / ANALYTIC FUNCTIONS (Min 2 Required - 3 Provided)
-- Coverage: RANK, ROW_NUMBER, Running Total (SUM OVER), LAG/LEAD
-- ============================================================================

-- Q-G01 [RANK() & ROW_NUMBER()]: Rank doctors by consultation fee within each department
SELECT 
    doctor_id, 
    first_name || ' ' || last_name AS doctor_name, 
    dept_id, 
    fee,
    RANK() OVER (PARTITION BY dept_id ORDER BY fee DESC) AS dept_rank,
    ROW_NUMBER() OVER (ORDER BY fee DESC) AS overall_hospital_rank
FROM doctors;

-- Q-G02 [Running Total with SUM() OVER]: Cumulative inventory valuation across medications
SELECT 
    med_id, 
    med_name, 
    unit_price, 
    stock_qty,
    (stock_qty * unit_price) AS item_valuation,
    SUM(stock_qty * unit_price) OVER (ORDER BY med_id) AS cumulative_pharmacy_valuation
FROM medications;

-- Q-G03 [LAG / LEAD]: Compare doctor fees against the immediately preceding fee in the sorted schedule
SELECT 
    doctor_id, 
    first_name || ' ' || last_name AS doctor_name, 
    specialization, 
    fee,
    LAG(fee, 1) OVER (ORDER BY fee ASC) AS prior_lower_fee,
    fee - COALESCE(LAG(fee, 1) OVER (ORDER BY fee ASC), fee) AS fee_difference_from_prev
FROM doctors;

