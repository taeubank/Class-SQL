--Create the appointment
INSERT INTO dbo.Appointment
(PatientID, ProviderID, ScheduledStart, ScheduledEnd, AppointmentStatusID, ReasonForVisit)
VALUES
(5, 4, '2026-02-20T09:00:00', '2026-02-20T09:30:00', 1, 'Right knee pain');

--Check-in the appointment
UPDATE dbo.Appointment
SET AppointmentStatusID = 2
WHERE PatientID = 5
  AND ScheduledStart = '2026-02-20T09:00:00';

--Create an encounter from that appointment
DECLARE @ApptID INT =
(
  SELECT AppointmentID
  FROM dbo.Appointment
  WHERE PatientID = 5
    AND ScheduledStart = '2026-02-20T09:00:00'
);

INSERT INTO dbo.Encounter
(AppointmentID, PatientID, ProviderID, EncounterStart, ChiefComplaint, Notes)
VALUES
(@ApptID, 5, 4, '2026-02-20T09:05:00', 'Knee pain', 'Pain x 2 weeks; mild swelling.');

--Add diagnosis

DECLARE @EncID INT =
(
  SELECT EncounterID
  FROM dbo.Encounter
  WHERE AppointmentID = (SELECT AppointmentID FROM dbo.Appointment WHERE PatientID=5 AND ScheduledStart='2026-02-20T09:00:00')
);

INSERT INTO dbo.EncounterDiagnosis (EncounterID, DiagnosisCode, IsPrimary)
VALUES (@EncID, 'M54.5', 1);

--Add procedures
INSERT INTO dbo.EncounterProcedure (EncounterID, ProcedureCode, Quantity)
VALUES
(@EncID, '99213', 1),
(@EncID, '73562', 1);

--Add prescription
DECLARE @MedID INT = (SELECT MedicationID FROM dbo.Medication WHERE MedicationName = 'Ibuprofen');

INSERT INTO dbo.Prescription
(EncounterID, MedicationID, Dose, Route, Frequency, DaysSupply)
VALUES
(@EncID, @MedID, '400 mg', 'PO', 'TID PRN', 7);

--Create claim (Submitted) + claim lines from procedures
DECLARE @PatientInsuranceID INT =
(
  SELECT TOP (1) PatientInsuranceID
  FROM dbo.PatientInsurance
  WHERE PatientID = 5 AND IsPrimary = 1
  ORDER BY EffectiveStartDate DESC
);

INSERT INTO dbo.Claim (EncounterID, PatientInsuranceID, ClaimStatusID)
VALUES (@EncID, @PatientInsuranceID, 2);  -- 2 = Submitted

DECLARE @ClaimID INT = SCOPE_IDENTITY();

-- Insert claim lines with charges based on ProcedureCode.BaseCharge
INSERT INTO dbo.ClaimLine (ClaimID, ProcedureCode, Quantity, UnitCharge)
SELECT
  @ClaimID,
  ep.ProcedureCode,
  ep.Quantity,
  COALESCE(pc.BaseCharge, 0)
FROM dbo.EncounterProcedure ep
JOIN dbo.ProcedureCode pc
  ON pc.ProcedureCode = ep.ProcedureCode
WHERE ep.EncounterID = @EncID;


--Record payment (payer + patient) and show remaining balance
INSERT INTO dbo.Payment (ClaimID, PaymentDate, Amount, PaymentSource, ReferenceNumber)
VALUES
(@ClaimID, '2026-02-28', 150.00, 'Payer',   'EOB-NEW-01'),
(@ClaimID, '2026-03-05', 30.00,  'Patient', 'CC-NEW-01');

SELECT
  c.ClaimID,
  SUM(cl.Quantity * cl.UnitCharge) AS TotalCharges,
  COALESCE(SUM(p.Amount),0) AS TotalPayments,
  SUM(cl.Quantity * cl.UnitCharge) - COALESCE(SUM(p.Amount),0) AS Balance
FROM dbo.Claim c
JOIN dbo.ClaimLine cl ON cl.ClaimID = c.ClaimID
LEFT JOIN dbo.Payment p ON p.ClaimID = c.ClaimID
WHERE c.ClaimID = @ClaimID
GROUP BY c.ClaimID;


