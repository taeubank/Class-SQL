USE HealthcarePortfolio;
SET NOCOUNT ON;

------------------------------------------------------------
-- PARAMETERS (edit these)
------------------------------------------------------------
DECLARE
    @WipeFacts            BIT = 1,      -- 1 = wipe generated fact data first
    @NumPatients          INT = 200,
    @ApptsPerPatientMin   INT = 1,
    @ApptsPerPatientMax   INT = 6,
    @StartDate            DATE = '2026-01-01',
    @EndDate              DATE = '2026-03-31',
    @PctCompleted         INT = 60,      -- out of 100
    @PctCancelled         INT = 10,
    @PctNoShow            INT = 10,
    @PctCheckedIn         INT = 10,      -- Scheduled = remainder
    @MaxDiagnosesPerEnc   INT = 2,
    @MaxProcsPerEnc       INT = 3,
    @PctRx                INT = 35,
    @PctClaimSubmitted    INT = 70,
    @PctClaimPaid         INT = 55,
    @Seed                 INT = 42;

------------------------------------------------------------
-- SAFETY CHECKS
------------------------------------------------------------
IF DB_NAME() <> 'HealthcarePortfolio'
BEGIN
    RAISERROR('Run this in the HealthcarePortfolio database.', 16, 1);
    RETURN;
END

IF @ApptsPerPatientMax < @ApptsPerPatientMin
BEGIN
    RAISERROR('@ApptsPerPatientMax must be >= @ApptsPerPatientMin.', 16, 1);
    RETURN;
END

DECLARE @RangeDays INT = DATEDIFF(DAY, @StartDate, @EndDate) + 1;
IF @RangeDays <= 0
BEGIN
    RAISERROR('Invalid date range.', 16, 1);
    RETURN;
END

------------------------------------------------------------
-- 1) Ensure reference data exists
------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.Department)
    INSERT INTO dbo.Department (DepartmentName)
    VALUES ('Family Medicine'),('Pediatrics'),('Cardiology'),('Orthopedics'),('Dermatology');

IF NOT EXISTS (SELECT 1 FROM dbo.Provider)
BEGIN
    INSERT INTO dbo.Provider (NPI, FirstName, LastName, Specialty, DepartmentID, IsActive)
    SELECT TOP (12)
        RIGHT(CONVERT(VARCHAR(20), ABS(CHECKSUM(NEWID()))), 10),
        CONCAT('Prov', ROW_NUMBER() OVER (ORDER BY (SELECT NULL))),
        CONCAT('Last', ROW_NUMBER() OVER (ORDER BY (SELECT NULL))),
        CASE (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 5)
            WHEN 0 THEN 'Family Medicine'
            WHEN 1 THEN 'Pediatrics'
            WHEN 2 THEN 'Cardiology'
            WHEN 3 THEN 'Orthopedics'
            ELSE 'Dermatology'
        END,
        ((ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 5) + 1),
        1
    FROM sys.all_objects;
END

IF NOT EXISTS (SELECT 1 FROM dbo.Payer)
    INSERT INTO dbo.Payer (PayerName)
    VALUES ('Blue Cross Blue Shield'),('Aetna'),('UnitedHealthcare'),('Cigna');

IF NOT EXISTS (SELECT 1 FROM dbo.DiagnosisCode)
    INSERT INTO dbo.DiagnosisCode (DiagnosisCode, DiagnosisName)
    VALUES
    ('I10','Essential (primary) hypertension'),
    ('E11.9','Type 2 diabetes mellitus without complications'),
    ('J02.9','Acute pharyngitis, unspecified'),
    ('M54.5','Low back pain'),
    ('L20.9','Atopic dermatitis, unspecified'),
    ('R07.9','Chest pain, unspecified'),
    ('Z00.00','General adult medical exam without abnormal findings'),
    ('Z00.129','Routine child health exam without abnormal findings');

IF NOT EXISTS (SELECT 1 FROM dbo.ProcedureCode)
    INSERT INTO dbo.ProcedureCode (ProcedureCode, ProcedureName, BaseCharge)
    VALUES
    ('99213','Office/outpatient visit, established, level 3', 125.00),
    ('99214','Office/outpatient visit, established, level 4', 185.00),
    ('93000','Electrocardiogram w/ interpretation',           90.00),
    ('80053','Comprehensive metabolic panel',                 65.00),
    ('36415','Venipuncture',                                  15.00),
    ('90686','Influenza virus vaccine',                       45.00),
    ('73562','X-ray knee 3 views',                            120.00);

IF NOT EXISTS (SELECT 1 FROM dbo.Medication)
    INSERT INTO dbo.Medication (MedicationName)
    VALUES ('Amoxicillin'),('Lisinopril'),('Metformin'),('Hydrocortisone topical'),('Ibuprofen');

IF NOT EXISTS (SELECT 1 FROM dbo.AppointmentStatus)
    INSERT INTO dbo.AppointmentStatus (AppointmentStatusID, StatusName)
    VALUES (1,'Scheduled'),(2,'CheckedIn'),(3,'Completed'),(4,'Cancelled'),(5,'NoShow');

IF NOT EXISTS (SELECT 1 FROM dbo.ClaimStatus)
    INSERT INTO dbo.ClaimStatus (ClaimStatusID, StatusName)
    VALUES (1,'Draft'),(2,'Submitted'),(3,'Adjudicated'),(4,'Denied'),(5,'Paid');

------------------------------------------------------------
-- 2) Optional wipe (FACTS + patients/insurance)
------------------------------------------------------------
IF @WipeFacts = 1
BEGIN
    DELETE FROM dbo.Payment;
    DELETE FROM dbo.ClaimLine;
    DELETE FROM dbo.Claim;

    DELETE FROM dbo.Prescription;
    DELETE FROM dbo.EncounterProcedure;
    DELETE FROM dbo.EncounterDiagnosis;
    DELETE FROM dbo.Encounter;

    DELETE FROM dbo.Appointment;

    DELETE FROM dbo.PatientInsurance;
    DELETE FROM dbo.Patient;

    PRINT 'Wiped facts + patients.';
END

------------------------------------------------------------
-- 3) Tally table (#Nums)
------------------------------------------------------------
IF OBJECT_ID('tempdb..#Nums') IS NOT NULL DROP TABLE #Nums;

;WITH n AS (
    SELECT TOP (200000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
)
SELECT n INTO #Nums FROM n;

------------------------------------------------------------
-- 4) Create Patients
------------------------------------------------------------
DECLARE @PatientStartMRN INT = 100000;

INSERT INTO dbo.Patient
(MRN, FirstName, LastName, DateOfBirth, Sex, Phone, Email, AddressLine1, City, StateCode, PostalCode)
SELECT TOP (@NumPatients)
    CONCAT('MRN', @PatientStartMRN + n) AS MRN,
    CONCAT('First', n),
    CONCAT('Last', n),
    DATEADD(DAY, -1 * (ABS(CHECKSUM(CONCAT(@Seed, n))) % 25000), CAST('2026-01-01' AS DATE)),
    CASE ABS(CHECKSUM(CONCAT('S',@Seed,n))) % 3 WHEN 0 THEN 'M' WHEN 1 THEN 'F' ELSE 'X' END,
    CONCAT('555-', RIGHT('000'+CAST(ABS(CHECKSUM(CONCAT('P',@Seed,n)))%1000 AS VARCHAR(3)),3),'-',
                 RIGHT('0000'+CAST(ABS(CHECKSUM(CONCAT('Q',@Seed,n)))%10000 AS VARCHAR(4)),4)),
    CONCAT('user', n, '@example.com'),
    CONCAT(ABS(CHECKSUM(CONCAT('A',@Seed,n))) % 9999, ' Main St'),
    'New York',
    'NY',
    RIGHT('00000'+CAST(ABS(CHECKSUM(CONCAT('Z',@Seed,n)))%99999 AS VARCHAR(5)),5)
FROM #Nums
ORDER BY n;

PRINT CONCAT('Patients inserted: ', @@ROWCOUNT);

------------------------------------------------------------
-- 5) Create PatientInsurance (1 primary per patient)
------------------------------------------------------------
INSERT INTO dbo.PatientInsurance
(PatientID, PayerID, MemberID, GroupNumber, EffectiveStartDate, EffectiveEndDate, IsPrimary)
SELECT
    p.PatientID,
    1 + (ABS(CHECKSUM(CONCAT('PAY',@Seed,p.PatientID))) % (SELECT COUNT(*) FROM dbo.Payer)),
    CONCAT('MEM-', p.PatientID, '-', ABS(CHECKSUM(CONCAT('M',@Seed,p.PatientID))) % 99999),
    CONCAT('GRP-', 1 + (ABS(CHECKSUM(CONCAT('G',@Seed,p.PatientID))) % 50)),
    DATEADD(DAY, -1 * (ABS(CHECKSUM(CONCAT('E',@Seed,p.PatientID))) % 600), @StartDate),
    NULL,
    1
FROM dbo.Patient p;

PRINT CONCAT('PatientInsurance inserted: ', @@ROWCOUNT);

------------------------------------------------------------
-- 6) Create Appointments
------------------------------------------------------------
DECLARE @ProviderCount INT = (SELECT COUNT(*) FROM dbo.Provider);

;WITH appt_counts AS (
    SELECT
        p.PatientID,
        (@ApptsPerPatientMin
          + (ABS(CHECKSUM(CONCAT('C',@Seed,p.PatientID)))
             % (@ApptsPerPatientMax-@ApptsPerPatientMin+1))
        ) AS ApptCount
    FROM dbo.Patient p
),
expanded AS (
    SELECT ac.PatientID, n.n AS k
    FROM appt_counts ac
    JOIN #Nums n ON n.n <= ac.ApptCount
),
base AS (
    SELECT
        e.PatientID,
        1 + (ABS(CHECKSUM(CONCAT('PR',@Seed,e.PatientID,e.k))) % @ProviderCount) AS ProviderPick,
        ABS(CHECKSUM(CONCAT('D',@Seed,e.PatientID,e.k))) % @RangeDays AS DayOffset,
        (8 + (ABS(CHECKSUM(CONCAT('H',@Seed,e.PatientID,e.k))) % 9)) AS HourOfDay,
        (ABS(CHECKSUM(CONCAT('MIN',@Seed,e.PatientID,e.k))) % 4) * 15 AS MinuteOfHour,
        ABS(CHECKSUM(CONCAT('R',@Seed,e.PatientID,e.k))) % 100 AS R
    FROM expanded e
)
INSERT INTO dbo.Appointment
(PatientID, ProviderID, ScheduledStart, ScheduledEnd, AppointmentStatusID, ReasonForVisit)
SELECT
    b.PatientID,
    pr.ProviderID,
    DATEADD(MINUTE, b.MinuteOfHour,
        DATEADD(HOUR, b.HourOfDay,
            CAST(DATEADD(DAY, b.DayOffset, @StartDate) AS DATETIME2)
        )
    ),
    DATEADD(MINUTE, 30,
        DATEADD(MINUTE, b.MinuteOfHour,
            DATEADD(HOUR, b.HourOfDay,
                CAST(DATEADD(DAY, b.DayOffset, @StartDate) AS DATETIME2)
            )
        )
    ),
    CASE
        WHEN b.R < @PctCompleted THEN 3
        WHEN b.R < @PctCompleted + @PctCancelled THEN 4
        WHEN b.R < @PctCompleted + @PctCancelled + @PctNoShow THEN 5
        WHEN b.R < @PctCompleted + @PctCancelled + @PctNoShow + @PctCheckedIn THEN 2
        ELSE 1
    END,
    CASE (b.R % 6)
        WHEN 0 THEN 'Annual physical'
        WHEN 1 THEN 'Sore throat'
        WHEN 2 THEN 'Follow-up visit'
        WHEN 3 THEN 'Knee pain'
        WHEN 4 THEN 'Rash'
        ELSE 'General consult'
    END
FROM base b
JOIN (
    SELECT ProviderID, ROW_NUMBER() OVER (ORDER BY ProviderID) AS rn
    FROM dbo.Provider
) pr ON pr.rn = b.ProviderPick;

PRINT CONCAT('Appointments inserted: ', @@ROWCOUNT);

------------------------------------------------------------
-- 7) Create Encounters for Completed appointments
------------------------------------------------------------
DECLARE @Enc TABLE (EncounterID INT, AppointmentID INT);

INSERT INTO dbo.Encounter
(AppointmentID, PatientID, ProviderID, EncounterStart, EncounterEnd, ChiefComplaint, Notes)
OUTPUT inserted.EncounterID, inserted.AppointmentID INTO @Enc(EncounterID, AppointmentID)
SELECT
    a.AppointmentID,
    a.PatientID,
    a.ProviderID,
    DATEADD(MINUTE, 5, a.ScheduledStart),
    DATEADD(MINUTE, 25, a.ScheduledStart),
    a.ReasonForVisit,
    CONCAT('Auto-note: visit documented for appt ', a.AppointmentID)
FROM dbo.Appointment a
WHERE a.AppointmentStatusID = 3;

PRINT CONCAT('Encounters inserted: ', @@ROWCOUNT);

------------------------------------------------------------
-- 8) EncounterDiagnosis (1..@MaxDiagnosesPerEnc)
------------------------------------------------------------
DECLARE @DxCount INT = (SELECT COUNT(*) FROM dbo.DiagnosisCode);

;WITH dx AS (
    SELECT EncounterID,
           1 + (ABS(CHECKSUM(CONCAT('DXN',@Seed,EncounterID))) % @MaxDiagnosesPerEnc) AS DxPerEnc
    FROM @Enc
),
expanded AS (
    SELECT d.EncounterID, n.n AS k
    FROM dx d
    JOIN #Nums n ON n.n <= d.DxPerEnc
),
picked AS (
    SELECT
        x.EncounterID,
        dc.DiagnosisCode,
        CASE WHEN x.k = 1 THEN 1 ELSE 0 END AS IsPrimary
    FROM expanded x
    JOIN (
        SELECT DiagnosisCode, ROW_NUMBER() OVER (ORDER BY DiagnosisCode) AS rn
        FROM dbo.DiagnosisCode
    ) dc ON dc.rn = 1 + (ABS(CHECKSUM(CONCAT('DXP',@Seed,x.EncounterID,x.k))) % @DxCount)
)
INSERT INTO dbo.EncounterDiagnosis (EncounterID, DiagnosisCode, IsPrimary)
SELECT EncounterID, DiagnosisCode, MAX(IsPrimary)
FROM picked
GROUP BY EncounterID, DiagnosisCode;

PRINT CONCAT('EncounterDiagnosis inserted: ', @@ROWCOUNT);

------------------------------------------------------------
-- 9) EncounterProcedure (1..@MaxProcsPerEnc)
------------------------------------------------------------
;WITH ProcPick AS (
    SELECT
        e.EncounterID,
        pc.ProcedureCode,
        ROW_NUMBER() OVER (
            PARTITION BY e.EncounterID
            ORDER BY CHECKSUM(CONCAT(@Seed, e.EncounterID, pc.ProcedureCode))
        ) AS rn
    FROM @Enc e
    CROSS JOIN dbo.ProcedureCode pc
),
TakeN AS (
    SELECT
        EncounterID,
        ProcedureCode
    FROM ProcPick
    WHERE rn <= 1 + (ABS(CHECKSUM(CONCAT('PP',@Seed,EncounterID))) % @MaxProcsPerEnc)
)
INSERT INTO dbo.EncounterProcedure (EncounterID, ProcedureCode, Quantity)
SELECT EncounterID, ProcedureCode, 1
FROM TakeN;

PRINT CONCAT('EncounterProcedure inserted: ', @@ROWCOUNT);

------------------------------------------------------------
-- 10) Prescriptions (~@PctRx)
------------------------------------------------------------
DECLARE @MedCount INT = (SELECT COUNT(*) FROM dbo.Medication);

INSERT INTO dbo.Prescription (EncounterID, MedicationID, Dose, Route, Frequency, DaysSupply)
SELECT
    e.EncounterID,
    m.MedicationID,
    CASE (ABS(CHECKSUM(CONCAT('DOSE',@Seed,e.EncounterID))) % 3)
        WHEN 0 THEN '500 mg' WHEN 1 THEN '10 mg' ELSE '400 mg' END,
    CASE (ABS(CHECKSUM(CONCAT('ROUTE',@Seed,e.EncounterID))) % 2)
        WHEN 0 THEN 'PO' ELSE 'Topical' END,
    CASE (ABS(CHECKSUM(CONCAT('FREQ',@Seed,e.EncounterID))) % 3)
        WHEN 0 THEN 'BID' WHEN 1 THEN 'Daily' ELSE 'TID PRN' END,
    7 + (ABS(CHECKSUM(CONCAT('DS',@Seed,e.EncounterID))) % 24)
FROM @Enc e
JOIN (
    SELECT MedicationID, ROW_NUMBER() OVER (ORDER BY MedicationID) AS rn
    FROM dbo.Medication
) m ON m.rn = 1 + (ABS(CHECKSUM(CONCAT('MED',@Seed,e.EncounterID))) % @MedCount)
WHERE (ABS(CHECKSUM(CONCAT('RX',@Seed,e.EncounterID))) % 100) < @PctRx;

PRINT CONCAT('Prescriptions inserted: ', @@ROWCOUNT);

------------------------------------------------------------
-- 11) Claims + ClaimLines
------------------------------------------------------------
DECLARE @Claims TABLE (ClaimID INT, EncounterID INT);

INSERT INTO dbo.Claim (EncounterID, PatientInsuranceID, ClaimStatusID)
OUTPUT inserted.ClaimID, inserted.EncounterID INTO @Claims(ClaimID, EncounterID)
SELECT
    e.EncounterID,
    pi.PatientInsuranceID,
    CASE WHEN (ABS(CHECKSUM(CONCAT('CS',@Seed,e.EncounterID))) % 100) < @PctClaimSubmitted THEN 2 ELSE 1 END
FROM @Enc e
JOIN dbo.Encounter enc ON enc.EncounterID = e.EncounterID
OUTER APPLY (
    SELECT TOP (1) PatientInsuranceID
    FROM dbo.PatientInsurance
    WHERE PatientID = enc.PatientID AND IsPrimary = 1
    ORDER BY EffectiveStartDate DESC
) pi;

INSERT INTO dbo.ClaimLine (ClaimID, ProcedureCode, Quantity, UnitCharge)
SELECT
    c.ClaimID,
    ep.ProcedureCode,
    ep.Quantity,
    COALESCE(pc.BaseCharge, 0)
FROM @Claims c
JOIN dbo.EncounterProcedure ep ON ep.EncounterID = c.EncounterID
JOIN dbo.ProcedureCode pc ON pc.ProcedureCode = ep.ProcedureCode;

PRINT CONCAT('Claims inserted: ', @@ROWCOUNT);
PRINT CONCAT('ClaimLines inserted: ', @@ROWCOUNT);

------------------------------------------------------------
-- 12) Payments (FIXED: temp table #Payable reused twice)
------------------------------------------------------------
IF OBJECT_ID('tempdb..#Payable') IS NOT NULL DROP TABLE #Payable;

SELECT
    c.ClaimID,
    SUM(cl.Quantity * cl.UnitCharge) AS TotalCharges,
    ABS(CHECKSUM(CONCAT('PAY', @Seed, c.ClaimID))) % 100 AS R
INTO #Payable
FROM dbo.Claim c
JOIN dbo.ClaimLine cl ON cl.ClaimID = c.ClaimID
GROUP BY c.ClaimID;

-- Payer payments
INSERT INTO dbo.Payment (ClaimID, PaymentDate, Amount, PaymentSource, ReferenceNumber)
SELECT
    ClaimID,
    DATEADD(DAY, 10 + (ABS(CHECKSUM(CONCAT('PD',@Seed,ClaimID))) % 30), @StartDate),
    CAST(ROUND(TotalCharges * (0.50 + (ABS(CHECKSUM(CONCAT('FR',@Seed,ClaimID))) % 40) / 100.0), 2) AS DECIMAL(10,2)),
    'Payer',
    CONCAT('EOB-', ClaimID)
FROM #Payable
WHERE R < @PctClaimPaid AND TotalCharges > 0;

-- Patient payments (subset)
INSERT INTO dbo.Payment (ClaimID, PaymentDate, Amount, PaymentSource, ReferenceNumber)
SELECT
    ClaimID,
    DATEADD(DAY, 25 + (ABS(CHECKSUM(CONCAT('PD2',@Seed,ClaimID))) % 40), @StartDate),
    CAST(ROUND(TotalCharges * (0.05 + (ABS(CHECKSUM(CONCAT('FR2',@Seed,ClaimID))) % 15) / 100.0), 2) AS DECIMAL(10,2)),
    'Patient',
    CONCAT('CC-', ClaimID)
FROM #Payable
WHERE R < (@PctClaimPaid / 2) AND TotalCharges > 0;

DROP TABLE #Payable;

------------------------------------------------------------
-- 13) Sanity counts
------------------------------------------------------------
SELECT 'Patients' AS [Table], COUNT(*) AS Cnt FROM dbo.Patient
UNION ALL SELECT 'Appointments', COUNT(*) FROM dbo.Appointment
UNION ALL SELECT 'Encounters', COUNT(*) FROM dbo.Encounter
UNION ALL SELECT 'EncounterDiagnosis', COUNT(*) FROM dbo.EncounterDiagnosis
UNION ALL SELECT 'EncounterProcedure', COUNT(*) FROM dbo.EncounterProcedure
UNION ALL SELECT 'Prescriptions', COUNT(*) FROM dbo.Prescription
UNION ALL SELECT 'Claims', COUNT(*) FROM dbo.Claim
UNION ALL SELECT 'ClaimLines', COUNT(*) FROM dbo.ClaimLine
UNION ALL SELECT 'Payments', COUNT(*) FROM dbo.Payment;

------------------------------------------------------------
-- Cleanup temp tables
------------------------------------------------------------
DROP TABLE IF EXISTS #Nums;
