-- ============================================================================
-- 02_seed_data.sql
-- Hospital Management System (HMS) - Complete Master Seed Data
-- Designed for Supabase PostgreSQL (VIT BCSE302P Evaluation)
-- Contains ≥ 10 realistic Indian records per table across all 9 tables
-- Safe to re-run: Truncates and restarts identity sequences cleanly
-- ============================================================================

-- Step 0: Clean existing data while preserving schema and triggers
TRUNCATE TABLE 
    invoices, 
    prescription_items, 
    admissions, 
    appointments, 
    medications, 
    rooms_beds, 
    patients, 
    doctors, 
    departments 
RESTART IDENTITY CASCADE;

-- ============================================================================
-- 1. DEPARTMENTS (10 Records)
-- ============================================================================
INSERT INTO departments (dept_name, floor) VALUES
('Cardiology', 3),
('Neurology', 4),
('Pediatrics', 2),
('Orthopedics', 1),
('General Surgery', 3),
('Obstetrics & Gynecology', 2),
('Dermatology', 1),
('Oncology', 5),
('Nephrology', 4),
('Emergency & Trauma', 1);

-- ============================================================================
-- 2. DOCTORS (10 Records - Indian Physicians with realistic fees in INR)
-- ============================================================================
INSERT INTO doctors (dept_id, first_name, last_name, specialization, fee, phone) VALUES
(1, 'Rajesh', 'Sharma', 'Interventional Cardiologist', 1500.00, '+91-9811223344'),
(2, 'Sunita', 'Verma', 'Senior Neurologist', 1600.00, '+91-9822334455'),
(3, 'Priya', 'Nair', 'Consultant Pediatrician', 900.00, '+91-9833445566'),
(4, 'Vikram', 'Malhotra', 'Orthopedic & Joint Replacement Surgeon', 1400.00, '+91-9844556677'),
(5, 'Amit', 'Patel', 'Laparoscopic General Surgeon', 1200.00, '+91-9855667788'),
(6, 'Ananya', 'Iyer', 'Obstetrician & Gynecologist', 1100.00, '+91-9866778899'),
(7, 'Suresh', 'Reddy', 'Clinical Dermatologist', 800.00, '+91-9877889900'),
(8, 'Meenakshi', 'Sundaram', 'Medical Oncologist', 2000.00, '+91-9888990011'),
(9, 'Arvind', 'Swaminathan', 'Consultant Nephrologist', 1300.00, '+91-9899001122'),
(10, 'Deepa', 'Mukherjee', 'Emergency Care Specialist', 1000.00, '+91-9800112233');

-- Update Department Heads (Assigning senior doctors as Heads of Departments)
UPDATE departments SET head_doctor_id = 1 WHERE dept_id = 1;
UPDATE departments SET head_doctor_id = 2 WHERE dept_id = 2;
UPDATE departments SET head_doctor_id = 3 WHERE dept_id = 3;
UPDATE departments SET head_doctor_id = 4 WHERE dept_id = 4;
UPDATE departments SET head_doctor_id = 5 WHERE dept_id = 5;
UPDATE departments SET head_doctor_id = 6 WHERE dept_id = 6;
UPDATE departments SET head_doctor_id = 7 WHERE dept_id = 7;
UPDATE departments SET head_doctor_id = 8 WHERE dept_id = 8;
UPDATE departments SET head_doctor_id = 9 WHERE dept_id = 9;
UPDATE departments SET head_doctor_id = 10 WHERE dept_id = 10;

-- ============================================================================
-- 3. PATIENTS (12 Records - All 8 Blood Groups, diverse genders & ages)
-- ============================================================================
INSERT INTO patients (first_name, last_name, dob, gender, blood_group, contact) VALUES
('Ravi', 'Kumar', '1988-05-14', 'Male', 'O+', '+91-9123456780'),
('Sneha', 'Gupta', '1995-10-22', 'Female', 'A+', '+91-9123456781'),
('Amitabh', 'Das', '1962-02-18', 'Male', 'B+', '+91-9123456782'),
('Deepika', 'Menon', '1991-08-09', 'Female', 'AB+', '+91-9123456783'),
('Rohan', 'Joshi', '2001-12-03', 'Male', 'O-', '+91-9123456784'),
('Kavita', 'Krishnan', '1979-04-30', 'Female', 'A-', '+91-9123456785'),
('Manoj', 'Tiwari', '1974-09-17', 'Male', 'B-', '+91-9123456786'),
('Pooja', 'Hegde', '1998-03-25', 'Female', 'AB-', '+91-9123456787'),
('Arvind', 'Kejriwal', '1968-08-16', 'Male', 'O+', '+91-9123456788'),
('Shilpa', 'Shetty', '1982-06-08', 'Female', 'A+', '+91-9123456789'),
('Harish', 'Rao', '1955-11-29', 'Male', 'B+', '+91-9123456790'),
('Neha', 'Deshmukh', '2004-07-12', 'Other', 'O+', '+91-9123456791');

-- ============================================================================
-- 4. ROOMS & BEDS (15 Records - General, Private, ICU wards)
-- All inserted as Vacant initially; the admissions trigger will update occupied beds
-- ============================================================================
INSERT INTO rooms_beds (room_no, ward_type, daily_rate, status) VALUES
('GEN-101', 'General', 800.00, 'Vacant'),
('GEN-102', 'General', 800.00, 'Vacant'),
('GEN-103', 'General', 800.00, 'Vacant'),
('GEN-104', 'General', 800.00, 'Vacant'),
('GEN-105', 'General', 800.00, 'Vacant'),
('PVT-201', 'Private', 2500.00, 'Vacant'),
('PVT-202', 'Private', 2500.00, 'Vacant'),
('PVT-203', 'Private', 2500.00, 'Vacant'),
('PVT-204', 'Private', 2500.00, 'Vacant'),
('PVT-205', 'Private', 2500.00, 'Vacant'),
('ICU-301', 'ICU', 6000.00, 'Vacant'),
('ICU-302', 'ICU', 6000.00, 'Vacant'),
('ICU-303', 'ICU', 6000.00, 'Vacant'),
('ICU-304', 'ICU', 6000.00, 'Vacant'),
('ICU-305', 'ICU', 6000.00, 'Vacant');

-- ============================================================================
-- 5. MEDICATIONS (12 Records - Standard Indian Hospital Formulary)
-- High initial stock ensures prescription triggers succeed without negative overdraft
-- Includes items near min_threshold to test low-stock detection
-- ============================================================================
INSERT INTO medications (med_name, unit_price, stock_qty, min_threshold) VALUES
('Paracetamol 650mg (Dolo)', 3.50, 500, 50),
('Amoxicillin-Clavulanate 625mg (Augmentin)', 22.00, 250, 30),
('Atorvastatin 20mg (Atorva)', 18.50, 180, 25),
('Metformin 500mg (Glycomet)', 6.00, 400, 40),
('Pantoprazole 40mg (Pan-40)', 11.50, 350, 35),
('Azithromycin 500mg (Azee)', 24.00, 120, 20),
('Telmisartan 40mg (Telma)', 14.00, 200, 25),
('Ondansetron 4mg (Emeset)', 8.00, 160, 20),
('Ceftriaxone 1g Injection (Monocef)', 65.00, 80, 15),
('Human Insulin 100IU (Huminsulin)', 185.00, 14, 20),  -- LOW STOCK (< min_threshold)
('Tramadol 50mg Injection (Tramazac)', 35.00, 10, 15),   -- LOW STOCK (< min_threshold)
('Budesonide Respules 0.5mg (Budecort)', 28.00, 95, 15);

-- ============================================================================
-- 6. APPOINTMENTS (12 Records - Scheduled, Completed, Cancelled)
-- Strict conflict avoidance: Each (doctor_id, appt_date, time_slot) is UNIQUE
-- ============================================================================
INSERT INTO appointments (patient_id, doctor_id, appt_date, time_slot, status) VALUES
(1, 1, CURRENT_DATE, '09:00 AM', 'Completed'),
(2, 1, CURRENT_DATE, '10:00 AM', 'Scheduled'),
(3, 2, CURRENT_DATE, '09:00 AM', 'Completed'),
(4, 2, CURRENT_DATE, '11:00 AM', 'Scheduled'),
(5, 3, CURRENT_DATE, '10:00 AM', 'Scheduled'),
(6, 4, CURRENT_DATE, '02:00 PM', 'Scheduled'),
(7, 5, CURRENT_DATE, '03:00 PM', 'Cancelled'),
(8, 6, CURRENT_DATE + INTERVAL '1 day', '09:00 AM', 'Scheduled'),
(9, 7, CURRENT_DATE + INTERVAL '1 day', '10:00 AM', 'Scheduled'),
(10, 8, CURRENT_DATE + INTERVAL '1 day', '11:00 AM', 'Scheduled'),
(11, 9, CURRENT_DATE + INTERVAL '2 days', '02:00 PM', 'Scheduled'),
(12, 10, CURRENT_DATE + INTERVAL '2 days', '04:00 PM', 'Scheduled');

-- ============================================================================
-- 7. ADMISSIONS (10 Records)
-- The trigger `trg_check_bed_availability` automatically marks beds 1-10 as 'Occupied'
-- 5 active admissions (discharge_date IS NULL)
-- 5 discharged admissions with completed dates
-- ============================================================================
INSERT INTO admissions (patient_id, bed_id, doctor_id, admission_date, discharge_date, notes) VALUES
-- Active Admissions (Currently in hospital)
(1, 1, 1, NOW() - INTERVAL '4 days', NULL, 'Admitted with acute angina; under telemetry monitoring in General ward'),
(2, 6, 2, NOW() - INTERVAL '3 days', NULL, 'Post-stroke observational monitoring; stable vitals'),
(3, 11, 8, NOW() - INTERVAL '2 days', NULL, 'Critical care monitoring following high-dose chemo cycle'),
(4, 2, 4, NOW() - INTERVAL '1 day', NULL, 'Fracture reduction and internal fixation post-trauma'),
(5, 7, 5, NOW() - INTERVAL '6 hours', NULL, 'Pre-operative preparation for laparoscopic cholecystectomy'),

-- Discharged Admissions (Historical stays)
(6, 3, 3, NOW() - INTERVAL '10 days', NOW() - INTERVAL '7 days', 'Severe pediatric viral bronchitis; recovered and discharged'),
(7, 8, 6, NOW() - INTERVAL '8 days', NOW() - INTERVAL '5 days', 'Post-normal delivery observation; mother and newborn healthy'),
(8, 12, 9, NOW() - INTERVAL '6 days', NOW() - INTERVAL '3 days', 'Acute renal flare treated with hemodialysis in ICU'),
(9, 4, 7, NOW() - INTERVAL '5 days', NOW() - INTERVAL '2 days', 'Severe acute contact dermatitis; treated and stabilized'),
(10, 9, 10, NOW() - INTERVAL '4 days', NOW() - INTERVAL '1 day', 'Blunt trauma evaluation following motor accident; recovered');

-- Update bed statuses for the 5 discharged admissions (Set to Vacant or Sanitizing)
UPDATE rooms_beds SET status = 'Vacant' WHERE bed_id IN (3, 8, 12, 4);
UPDATE rooms_beds SET status = 'Sanitizing' WHERE bed_id = 9;

-- ============================================================================
-- 8. PRESCRIPTION ITEMS (12 Records)
-- The trigger `trg_decrement_inventory` will automatically decrement stock in medications!
-- ============================================================================
INSERT INTO prescription_items (admission_id, med_id, quantity, dosage_instructions) VALUES
(1, 1, 6, '1 tablet thrice daily after food'),
(1, 3, 4, '1 tablet at bedtime for cholesterol control'),
(1, 5, 4, '1 capsule before breakfast daily'),
(2, 2, 6, '1 tablet twice daily for 3 days'),
(2, 4, 6, '1 tablet after meals twice daily'),
(3, 8, 4, '1 tablet every 8 hours for nausea'),
(3, 9, 2, 'IV infusion stat in ICU'),
(4, 1, 10, '1 tablet as needed for pain relief'),
(4, 2, 8, '1 tablet twice daily post-surgery'),
(5, 5, 2, '1 tablet pre-anesthesia morning dose'),
(6, 1, 4, '1/2 tablet syrup equivalent twice daily'),
(8, 9, 3, '1 injection daily under ICU nephro protocol');

-- ============================================================================
-- 9. INVOICES (10 Records - 5 Paid, 5 Pending)
-- Accurately calculated breakdowns: (Length of stay * bed rate) + doctor fee + medication cost
-- ============================================================================
INSERT INTO invoices (admission_id, room_charge, doctor_charge, pharmacy_charge, total_amount, status, created_at) VALUES
-- Discharged stays (Finalized invoices)
(6, 2400.00, 900.00, 14.00, 3314.00, 'Paid', NOW() - INTERVAL '7 days'),
(7, 7500.00, 1100.00, 0.00, 8600.00, 'Paid', NOW() - INTERVAL '5 days'),
(8, 18000.00, 1300.00, 195.00, 19495.00, 'Paid', NOW() - INTERVAL '3 days'),
(9, 2400.00, 800.00, 0.00, 3200.00, 'Paid', NOW() - INTERVAL '2 days'),
(10, 7500.00, 1000.00, 0.00, 8500.00, 'Paid', NOW() - INTERVAL '1 day'),

-- Active stays (Provisional / Pending settlement invoices)
(1, 3200.00, 1500.00, 141.00, 4841.00, 'Pending', NOW() - INTERVAL '12 hours'),
(2, 7500.00, 1600.00, 168.00, 9268.00, 'Pending', NOW() - INTERVAL '10 hours'),
(3, 12000.00, 2000.00, 162.00, 14162.00, 'Pending', NOW() - INTERVAL '8 hours'),
(4, 800.00, 1400.00, 211.00, 2411.00, 'Pending', NOW() - INTERVAL '4 hours'),
(5, 2500.00, 1200.00, 23.00, 3723.00, 'Pending', NOW() - INTERVAL '1 hour');

-- ============================================================================
-- 10. VERIFICATION CHECK: Display Row Counts Across All Tables
-- ============================================================================
SELECT 'departments' AS table_name, COUNT(*) AS row_count FROM departments
UNION ALL
SELECT 'doctors', COUNT(*) FROM doctors
UNION ALL
SELECT 'patients', COUNT(*) FROM patients
UNION ALL
SELECT 'rooms_beds', COUNT(*) FROM rooms_beds
UNION ALL
SELECT 'medications', COUNT(*) FROM medications
UNION ALL
SELECT 'appointments', COUNT(*) FROM appointments
UNION ALL
SELECT 'admissions', COUNT(*) FROM admissions
UNION ALL
SELECT 'prescription_items', COUNT(*) FROM prescription_items
UNION ALL
SELECT 'invoices', COUNT(*) FROM invoices
ORDER BY table_name;

