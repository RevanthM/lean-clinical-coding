import ClinicalCoding

open ClinicalCoding

def feverNote : ReviewedNote :=
  ⟨"synthetic-1", "Fever", 20261115, .outpatient, true, .fever, .affirmed, true⟩

def feverCert : Certificate :=
  ⟨"synthetic-1", "FY2027-fixture-v1", .fever, 0, "Fever"⟩

def hypertensionNote : ReviewedNote :=
  { feverNote with id := "synthetic-2", text := "Essential hypertension", concept := .hypertension }

def hypertensionCert : Certificate :=
  { feverCert with noteId := "synthetic-2", concept := .hypertension, quotation := "Essential hypertension" }

def fixtures : List (String × Bool) := [
  ("affirmed symptom accepted", verify feverNote feverCert),
  ("confirmed diagnosis accepted", verify hypertensionNote hypertensionCert),
  ("uncertain diagnosis refused", !(verify { hypertensionNote with certainty := .uncertain } hypertensionCert)),
  ("negated symptom refused", !(verify { feverNote with certainty := .negated } feverCert)),
  ("symptom cannot support hypertension", !(verify feverNote { feverCert with concept := .hypertension })),
  ("wrong source id refused", !(verify feverNote { feverCert with noteId := "another-note" })),
  ("changed quotation refused", !(verify feverNote { feverCert with quotation := "fever" })),
  ("out-of-bounds offset refused", !(verify feverNote { feverCert with offset := 100 })),
  ("empty quotation refused", !(verify feverNote { feverCert with quotation := "" })),
  ("unsigned input refused", !(verify { feverNote with clinicianReviewed := false } feverCert)),
  ("inpatient input requires another policy", !(verify { feverNote with setting := .inpatient } feverCert)),
  ("historical condition refused", !(verify { feverNote with currentEncounter := false } feverCert)),
  ("before effective date refused", !(verify { feverNote with encounterDate := 20260930 } feverCert)),
  ("first effective date accepted", verify { feverNote with encounterDate := 20261001 } feverCert),
  ("last effective date accepted", verify { feverNote with encounterDate := 20270930 } feverCert),
  ("exclusive end date refused", !(verify { feverNote with encounterDate := 20271001 } feverCert)),
  ("wrong policy version refused", !(verify feverNote { feverCert with release := "FY2026" })),
  ("unsupported concept refused", !(verify { feverNote with concept := .unsupported } { feverCert with concept := .unsupported })),
  ("fever yields expected code", result feverNote feverCert == some "R50.9"),
  ("hypertension yields expected code", result hypertensionNote hypertensionCert == some "I10"),
  ("invalid calendar date refused", !(verify { feverNote with encounterDate := 20270230 } feverCert)),
  ("leap day validated", validCalendarDate 20280229),
  ("non-leap February 29 refused", !(validCalendarDate 20270229))
]

example : fixtures.all Prod.snd = true := by decide

def main : IO Unit := do
  for (name, passed) in fixtures do
    IO.println s!"{if passed then "PASS" else "FAIL"}: {name}"
  if fixtures.all Prod.snd then
    IO.println s!"{fixtures.length}/{fixtures.length} synthetic clinical fixtures passed."
  else
    throw (IO.userError "Synthetic clinical fixture failed")
