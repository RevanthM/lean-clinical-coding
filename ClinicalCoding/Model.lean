import Std

namespace ClinicalCoding

inductive Concept where
  | fever | hypertension | unsupported
  deriving DecidableEq, Repr

inductive Certainty where
  | affirmed | uncertain | negated
  deriving DecidableEq, Repr

inductive Setting where
  | outpatient | inpatient
  deriving DecidableEq, Repr

/-- Semantic annotations belong to the reviewed input, not the model proposal. -/
structure ReviewedNote where
  id : String
  text : String
  encounterDate : Nat
  setting : Setting
  clinicianReviewed : Bool
  concept : Concept
  certainty : Certainty
  currentEncounter : Bool
  deriving Repr

structure Certificate where
  noteId : String
  release : String
  concept : Concept
  offset : Nat
  quotation : String
  deriving Repr

def canonicalText : Concept → String
  | .fever => "Fever"
  | .hypertension => "Essential hypertension"
  | .unsupported => ""

def code : Concept → Option String
  | .fever => some "R50.9"
  | .hypertension => some "I10"
  | .unsupported => none

/-- Offsets count Unicode scalar values, not bytes or UTF-16 units. -/
def span (text : String) (offset length : Nat) : String :=
  String.ofList ((text.toList.drop offset).take length)

def validCalendarDate (date : Nat) : Bool :=
  let year := date / 10000
  let month := (date / 100) % 100
  let day := date % 100
  let leap := year % 400 == 0 || (year % 4 == 0 && year % 100 != 0)
  let days := if month == 2 then (if leap then 29 else 28)
    else if [4, 6, 9, 11].contains month then 30 else 31
  decide (1 ≤ year ∧ 1 ≤ month ∧ month ≤ 12 ∧ 1 ≤ day ∧ day ≤ days)

/-- A deliberately narrow, reviewed-input fixture policy; not the ICD-10 corpus. -/
def Conditions (n : ReviewedNote) (c : Certificate) : Prop :=
  c.noteId = n.id ∧
  c.release = "FY2027-fixture-v1" ∧
  n.clinicianReviewed = true ∧
  n.setting = .outpatient ∧
  20261001 ≤ n.encounterDate ∧ n.encounterDate < 20271001 ∧
  n.currentEncounter = true ∧
  n.certainty = .affirmed ∧
  c.concept = n.concept ∧
  c.concept ≠ .unsupported ∧
  0 < c.quotation.length ∧
  c.offset + c.quotation.length ≤ n.text.length ∧
  span n.text c.offset c.quotation.length = c.quotation ∧
  c.quotation = canonicalText n.concept ∧
  validCalendarDate n.encounterDate = true

instance (n : ReviewedNote) (c : Certificate) : Decidable (Conditions n c) :=
  inferInstanceAs (Decidable (_ ∧ _ ∧ _ ∧ _ ∧ _ ∧ _ ∧ _ ∧ _ ∧ _ ∧ _ ∧ _ ∧ _ ∧ _ ∧ _ ∧ _))

def verify (n : ReviewedNote) (c : Certificate) : Bool := decide (Conditions n c)

def result (n : ReviewedNote) (c : Certificate) : Option String :=
  if verify n c then code c.concept else none

theorem verification_iff (n : ReviewedNote) (c : Certificate) :
    verify n c = true ↔ Conditions n c := by
  simp [verify]

theorem accepted_requires_review (n : ReviewedNote) (c : Certificate)
    (h : verify n c = true) : n.clinicianReviewed = true := by
  have hc := (verification_iff n c).mp h
  exact hc.2.2.1

theorem accepted_is_outpatient (n : ReviewedNote) (c : Certificate)
    (h : verify n c = true) : n.setting = .outpatient := by
  exact ((verification_iff n c).mp h).2.2.2.1

theorem accepted_is_affirmed (n : ReviewedNote) (c : Certificate)
    (h : verify n c = true) : n.certainty = .affirmed := by
  exact ((verification_iff n c).mp h).2.2.2.2.2.2.2.1

theorem accepted_concept_matches (n : ReviewedNote) (c : Certificate)
    (h : verify n c = true) : c.concept = n.concept := by
  exact ((verification_iff n c).mp h).2.2.2.2.2.2.2.2.1

theorem accepted_quote_exists (n : ReviewedNote) (c : Certificate)
    (h : verify n c = true) :
    span n.text c.offset c.quotation.length = c.quotation := by
  exact ((verification_iff n c).mp h).2.2.2.2.2.2.2.2.2.2.2.2.1

theorem accepted_date_in_window (n : ReviewedNote) (c : Certificate)
    (h : verify n c = true) :
    20261001 ≤ n.encounterDate ∧ n.encounterDate < 20271001 := by
  have hc := (verification_iff n c).mp h
  exact ⟨hc.2.2.2.2.1, hc.2.2.2.2.2.1⟩

theorem uncertain_refused (n : ReviewedNote) (c : Certificate)
    (h : n.certainty = .uncertain) : verify n c = false := by
  cases hv : verify n c
  · rfl
  · have ha := accepted_is_affirmed n c hv
    rw [h] at ha
    contradiction

theorem negated_refused (n : ReviewedNote) (c : Certificate)
    (h : n.certainty = .negated) : verify n c = false := by
  cases hv : verify n c
  · rfl
  · have ha := accepted_is_affirmed n c hv
    rw [h] at ha
    contradiction

theorem rejection_has_no_code (n : ReviewedNote) (c : Certificate)
    (h : verify n c = false) : result n c = none := by
  simp [result, h]

theorem accepted_quote_in_bounds (n : ReviewedNote) (c : Certificate)
    (h : verify n c = true) : c.offset + c.quotation.length ≤ n.text.length := by
  exact ((verification_iff n c).mp h).2.2.2.2.2.2.2.2.2.2.2.1

theorem unsupported_refused (n : ReviewedNote) (c : Certificate)
    (h : c.concept = .unsupported) : verify n c = false := by
  cases hv : verify n c
  · rfl
  · have hc := ((verification_iff n c).mp hv).2.2.2.2.2.2.2.2.2.1
    exact False.elim (hc h)

end ClinicalCoding
