SET NOCOUNT ON;

PRINT '--- Creating indexes (safe version) ---';

------------------------------------------------------------
-- APPOINTMENT
------------------------------------------------------------
IF OBJECT_ID('dbo.Appointment') IS NOT NULL
BEGIN
    IF COL_LENGTH('dbo.Appointment','ProviderID') IS NOT NULL
       AND COL_LENGTH('dbo.Appointment','ScheduledStart') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Appointment_Provider_ScheduledStart' AND object_id=OBJECT_ID('dbo.Appointment'))
    BEGIN
        CREATE NONCLUSTERED INDEX IX_Appointment_Provider_ScheduledStart
        ON dbo.Appointment (ProviderID, ScheduledStart)
        INCLUDE (PatientID, AppointmentStatusID, ScheduledEnd);
        PRINT 'CREATED: IX_Appointment_Provider_ScheduledStart';
    END

    IF COL_LENGTH('dbo.Appointment','PatientID') IS NOT NULL
       AND COL_LENGTH('dbo.Appointment','ScheduledStart') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Appointment_Patient_ScheduledStart' AND object_id=OBJECT_ID('dbo.Appointment'))
    BEGIN
        CREATE NONCLUSTERED INDEX IX_Appointment_Patient_ScheduledStart
        ON dbo.Appointment (PatientID, ScheduledStart)
        INCLUDE (ProviderID, AppointmentStatusID, ScheduledEnd);
        PRINT 'CREATED: IX_Appointment_Patient_ScheduledStart';
    END

    -- Filtered exceptions (UPDATE status IDs if needed)
    IF COL_LENGTH('dbo.Appointment','AppointmentStatusID') IS NOT NULL
       AND COL_LENGTH('dbo.Appointment','ScheduledStart') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Appointment_StatusExceptions_ScheduledStart' AND object_id=OBJECT_ID('dbo.Appointment'))
    BEGIN
        CREATE NONCLUSTERED INDEX IX_Appointment_StatusExceptions_ScheduledStart
        ON dbo.Appointment (ScheduledStart)
        INCLUDE (ProviderID, PatientID, AppointmentStatusID)
        WHERE AppointmentStatusID IN (4,5);
        PRINT 'CREATED: IX_Appointment_StatusExceptions_ScheduledStart (verify status IDs)';
    END
END


------------------------------------------------------------
-- ENCOUNTER
-- (creates index only if one of these date columns exists)
------------------------------------------------------------
IF OBJECT_ID('dbo.Encounter') IS NOT NULL
BEGIN
    -- Pick ONE you actually have; script checks them in order
    IF COL_LENGTH('dbo.Encounter','EncounterDate') IS NOT NULL
       AND COL_LENGTH('dbo.Encounter','ProviderID') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Encounter_Provider_Date' AND object_id=OBJECT_ID('dbo.Encounter'))
    BEGIN
        CREATE NONCLUSTERED INDEX IX_Encounter_Provider_Date
        ON dbo.Encounter (ProviderID, EncounterDate)
        INCLUDE (PatientID, AppointmentID);
        PRINT 'CREATED: IX_Encounter_Provider_Date (EncounterDate)';
    END
    ELSE IF COL_LENGTH('dbo.Encounter','VisitDate') IS NOT NULL
       AND COL_LENGTH('dbo.Encounter','ProviderID') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Encounter_Provider_Date' AND object_id=OBJECT_ID('dbo.Encounter'))
    BEGIN
        CREATE NONCLUSTERED INDEX IX_Encounter_Provider_Date
        ON dbo.Encounter (ProviderID, VisitDate)
        INCLUDE (PatientID, AppointmentID);
        PRINT 'CREATED: IX_Encounter_Provider_Date (VisitDate)';
    END
    ELSE IF COL_LENGTH('dbo.Encounter','ServiceDate') IS NOT NULL
       AND COL_LENGTH('dbo.Encounter','ProviderID') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Encounter_Provider_Date' AND object_id=OBJECT_ID('dbo.Encounter'))
    BEGIN
        CREATE NONCLUSTERED INDEX IX_Encounter_Provider_Date
        ON dbo.Encounter (ProviderID, ServiceDate)
        INCLUDE (PatientID, AppointmentID);
        PRINT 'CREATED: IX_Encounter_Provider_Date (ServiceDate)';
    END
    ELSE
        PRINT 'SKIP: IX_Encounter_Provider_Date (no EncounterDate/VisitDate/ServiceDate found).';

    IF COL_LENGTH('dbo.Encounter','AppointmentID') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Encounter_AppointmentID' AND object_id=OBJECT_ID('dbo.Encounter'))
    BEGIN
        CREATE NONCLUSTERED INDEX IX_Encounter_AppointmentID
        ON dbo.Encounter (AppointmentID)
        INCLUDE (EncounterID, ProviderID);
        PRINT 'CREATED: IX_Encounter_AppointmentID';
    END
END


------------------------------------------------------------
-- PRESCRIPTION
-- (creates index only if a likely date column exists)
------------------------------------------------------------
IF OBJECT_ID('dbo.Prescription') IS NOT NULL
BEGIN
    IF COL_LENGTH('dbo.Prescription','PatientID') IS NOT NULL
       AND COL_LENGTH('dbo.Prescription','PrescribedDate') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Prescription_Patient_Date' AND object_id=OBJECT_ID('dbo.Prescription'))
    BEGIN
        CREATE NONCLUSTERED INDEX IX_Prescription_Patient_Date
        ON dbo.Prescription (PatientID, PrescribedDate)
        INCLUDE (ProviderID);
        PRINT 'CREATED: IX_Prescription_Patient_Date (PrescribedDate)';
    END
    ELSE IF COL_LENGTH('dbo.Prescription','OrderDate') IS NOT NULL
       AND COL_LENGTH('dbo.Prescription','PatientID') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Prescription_Patient_Date' AND object_id=OBJECT_ID('dbo.Prescription'))
    BEGIN
        CREATE NONCLUSTERED INDEX IX_Prescription_Patient_Date
        ON dbo.Prescription (PatientID, OrderDate)
        INCLUDE (ProviderID);
        PRINT 'CREATED: IX_Prescription_Patient_Date (OrderDate)';
    END
    ELSE
        PRINT 'SKIP: IX_Prescription_Patient_Date (no PrescribedDate/OrderDate found).';

    -- If you have IsActive bit:
    IF COL_LENGTH('dbo.Prescription','IsActive') IS NOT NULL
       AND COL_LENGTH('dbo.Prescription','PatientID') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Prescription_Active_ByPatient' AND object_id=OBJECT_ID('dbo.Prescription'))
    BEGIN
        CREATE NONCLUSTERED INDEX IX_Prescription_Active_ByPatient
        ON dbo.Prescription (PatientID)
        INCLUDE (ProviderID)
        WHERE IsActive = 1;
        PRINT 'CREATED: IX_Prescription_Active_ByPatient';
    END
END


------------------------------------------------------------
-- CLAIM
-- (creates payer/status/date index only if those columns exist)
------------------------------------------------------------
IF OBJECT_ID('dbo.Claim') IS NOT NULL
BEGIN
    IF COL_LENGTH('dbo.Claim','EncounterID') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Claim_EncounterID' AND object_id=OBJECT_ID('dbo.Claim'))
    BEGIN
        CREATE NONCLUSTERED INDEX IX_Claim_EncounterID
        ON dbo.Claim (EncounterID);
        PRINT 'CREATED: IX_Claim_EncounterID';
    END

    -- Try common payer cols: PayerID OR InsuranceID
    IF COL_LENGTH('dbo.Claim','ClaimStatusID') IS NOT NULL
    BEGIN
        IF COL_LENGTH('dbo.Claim','PayerID') IS NOT NULL AND COL_LENGTH('dbo.Claim','ServiceDate') IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Claim_Payer_Status_Date' AND object_id=OBJECT_ID('dbo.Claim'))
        BEGIN
            CREATE NONCLUSTERED INDEX IX_Claim_Payer_Status_Date
            ON dbo.Claim (PayerID, ClaimStatusID, ServiceDate)
            INCLUDE (EncounterID);
            PRINT 'CREATED: IX_Claim_Payer_Status_Date (PayerID/ServiceDate)';
        END
        ELSE IF COL_LENGTH('dbo.Claim','InsuranceID') IS NOT NULL AND COL_LENGTH('dbo.Claim','ServiceDate') IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Claim_Payer_Status_Date' AND object_id=OBJECT_ID('dbo.Claim'))
        BEGIN
            CREATE NONCLUSTERED INDEX IX_Claim_Payer_Status_Date
            ON dbo.Claim (InsuranceID, ClaimStatusID, ServiceDate)
            INCLUDE (EncounterID);
            PRINT 'CREATED: IX_Claim_Payer_Status_Date (InsuranceID/ServiceDate)';
        END
        ELSE
            PRINT 'SKIP: IX_Claim_Payer_Status_Date (need payer + ServiceDate + ClaimStatusID).';
    END
END


------------------------------------------------------------
-- PATIENT INSURANCE  (no OR filtered predicates)
------------------------------------------------------------
IF OBJECT_ID('dbo.PatientInsurance') IS NOT NULL
BEGIN
    IF COL_LENGTH('dbo.PatientInsurance','PatientID') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_PatientInsurance_Patient' AND object_id=OBJECT_ID('dbo.PatientInsurance'))
    BEGIN
        CREATE NONCLUSTERED INDEX IX_PatientInsurance_Patient
        ON dbo.PatientInsurance (PatientID);
        PRINT 'CREATED: IX_PatientInsurance_Patient';
    END

    IF COL_LENGTH('dbo.PatientInsurance','PatientID') IS NOT NULL
       AND COL_LENGTH('dbo.PatientInsurance','EffectiveEndDate') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_PatientInsurance_NoEndDate' AND object_id=OBJECT_ID('dbo.PatientInsurance'))
    BEGIN
        CREATE NONCLUSTERED INDEX IX_PatientInsurance_NoEndDate
        ON dbo.PatientInsurance (PatientID)
        WHERE EffectiveEndDate IS NULL;
        PRINT 'CREATED: IX_PatientInsurance_NoEndDate';
    END
END


------------------------------------------------------------
-- PATIENT
------------------------------------------------------------
IF OBJECT_ID('dbo.Patient') IS NOT NULL
BEGIN
    IF COL_LENGTH('dbo.Patient','MRN') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UX_Patient_MRN' AND object_id=OBJECT_ID('dbo.Patient'))
    BEGIN
        CREATE UNIQUE NONCLUSTERED INDEX UX_Patient_MRN
        ON dbo.Patient (MRN);
        PRINT 'CREATED: UX_Patient_MRN';
    END

    -- DOB might be DateOfBirth / BirthDate etc. (no guessing here; safe skip)
    IF COL_LENGTH('dbo.Patient','LastName') IS NOT NULL
       AND COL_LENGTH('dbo.Patient','FirstName') IS NOT NULL
       AND COL_LENGTH('dbo.Patient','DOB') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Patient_Last_First_DOB' AND object_id=OBJECT_ID('dbo.Patient'))
    BEGIN
        CREATE NONCLUSTERED INDEX IX_Patient_Last_First_DOB
        ON dbo.Patient (LastName, FirstName, DOB)
        INCLUDE (PatientID, MRN);
        PRINT 'CREATED: IX_Patient_Last_First_DOB (DOB)';
    END
    ELSE IF COL_LENGTH('dbo.Patient','LastName') IS NOT NULL
       AND COL_LENGTH('dbo.Patient','FirstName') IS NOT NULL
       AND COL_LENGTH('dbo.Patient','DateOfBirth') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Patient_Last_First_DOB' AND object_id=OBJECT_ID('dbo.Patient'))
    BEGIN
        CREATE NONCLUSTERED INDEX IX_Patient_Last_First_DOB
        ON dbo.Patient (LastName, FirstName, DateOfBirth)
        INCLUDE (PatientID, MRN);
        PRINT 'CREATED: IX_Patient_Last_First_DOB (DateOfBirth)';
    END
    ELSE
        PRINT 'SKIP: IX_Patient_Last_First_DOB (no DOB/DateOfBirth found).';
END


------------------------------------------------------------
-- PROVIDER
------------------------------------------------------------
IF OBJECT_ID('dbo.Provider') IS NOT NULL
BEGIN
    IF COL_LENGTH('dbo.Provider','DepartmentID') IS NOT NULL
       AND COL_LENGTH('dbo.Provider','ProviderID') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Provider_Department_Provider' AND object_id=OBJECT_ID('dbo.Provider'))
    BEGIN
        CREATE NONCLUSTERED INDEX IX_Provider_Department_Provider
        ON dbo.Provider (DepartmentID, ProviderID)
        INCLUDE (LastName, FirstName);
        PRINT 'CREATED: IX_Provider_Department_Provider';
    END
END

PRINT '--- Done ---';
