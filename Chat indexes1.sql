------------------------------------------------------------
-- PRESCRIPTION INDEXES (FIXED: no IsActive assumption)
------------------------------------------------------------
IF OBJECT_ID('dbo.Prescription') IS NOT NULL
BEGIN
    -- Patient med history (date-based)
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

    -- Active meds filtered index (ONLY if a supported flag exists)
    IF COL_LENGTH('dbo.Prescription','PatientID') IS NOT NULL
       AND COL_LENGTH('dbo.Prescription','IsActive') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Prescription_Active_ByPatient' AND object_id=OBJECT_ID('dbo.Prescription'))
    BEGIN
        CREATE NONCLUSTERED INDEX IX_Prescription_Active_ByPatient
        ON dbo.Prescription (PatientID)
        INCLUDE (ProviderID)
        WHERE IsActive = 1;
        PRINT 'CREATED: IX_Prescription_Active_ByPatient (IsActive=1)';
    END
    ELSE IF COL_LENGTH('dbo.Prescription','PatientID') IS NOT NULL
       AND COL_LENGTH('dbo.Prescription','ActiveFlag') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Prescription_Active_ByPatient' AND object_id=OBJECT_ID('dbo.Prescription'))
    BEGIN
        CREATE NONCLUSTERED INDEX IX_Prescription_Active_ByPatient
        ON dbo.Prescription (PatientID)
        INCLUDE (ProviderID)
        WHERE ActiveFlag = 1;
        PRINT 'CREATED: IX_Prescription_Active_ByPatient (ActiveFlag=1)';
    END
    ELSE
        PRINT 'NOTE: No IsActive/ActiveFlag column found; skipping active-meds filtered index.';
END


SELECT c.name
FROM sys.columns c
WHERE c.object_id = OBJECT_ID('dbo.Prescription')
ORDER BY c.column_id;

/* ============================================================
   PRESCRIPTION INDEXES (based on your actual columns)
   Columns:
   PrescriptionID, EncounterID, MedicationID, Dose, Route,
   Frequency, DaysSupply, PrescribedAt
   ============================================================ */

-- 1) Fast: prescriptions for a given Encounter (most common drill-down)
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Prescription_EncounterID_PrescribedAt'
      AND object_id = OBJECT_ID('dbo.Prescription')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Prescription_EncounterID_PrescribedAt
    ON dbo.Prescription (EncounterID, PrescribedAt)
    INCLUDE (MedicationID, Dose, Route, Frequency, DaysSupply);
END
GO

-- 2) Fast: medication utilization reports (by med, by date range)
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Prescription_MedicationID_PrescribedAt'
      AND object_id = OBJECT_ID('dbo.Prescription')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Prescription_MedicationID_PrescribedAt
    ON dbo.Prescription (MedicationID, PrescribedAt)
    INCLUDE (EncounterID, Dose, Route, Frequency, DaysSupply);
END
GO

-- 3) Optional: if you often search "all prescriptions in a date range"
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Prescription_PrescribedAt'
      AND object_id = OBJECT_ID('dbo.Prescription')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Prescription_PrescribedAt
    ON dbo.Prescription (PrescribedAt)
    INCLUDE (EncounterID, MedicationID);
END
GO
