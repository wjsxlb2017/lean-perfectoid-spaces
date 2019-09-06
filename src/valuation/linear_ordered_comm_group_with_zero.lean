import for_mathlib.linear_ordered_comm_group

import valuation.group_with_zero

set_option old_structure_cmd true

class linear_ordered_comm_group_with_zero (α : Type*)
  extends linear_ordered_comm_monoid α, comm_group_with_zero α :=
(zero_le' : ∀ a, (0:α) ≤ a)

namespace with_zero

instance (α : Type*) [linear_ordered_comm_group α] [decidable_eq α] :
  linear_ordered_comm_group_with_zero (with_zero α) :=
{ zero_le' := λ a, with_zero.zero_le,
  inv_zero := rfl,
  mul_inv_cancel := λ a h, mul_right_inv a h,
  .. (infer_instance : linear_ordered_comm_monoid (with_zero α)),
  .. (infer_instance : has_inv (with_zero α)),
  .. (infer_instance : zero_ne_one_class (with_zero α)),
  .. (infer_instance : mul_zero_class (with_zero α)) }

end with_zero

namespace linear_ordered_comm_group_with_zero
variables (α : Type*) [linear_ordered_comm_group_with_zero α]

instance units.linear_order : linear_order (units α) :=
linear_order.lift (coe : units α → α) (λ a b, units.ext) infer_instance

instance units.linear_ordered_comm_group : linear_ordered_comm_group (units α) :=
{ mul_le_mul_left := λ a b h c, mul_le_mul_left h _,
  .. units.linear_order α,
  .. (infer_instance : comm_group (units α))}


noncomputable def with_zero_units_equiv : with_zero (units α) ≃ α :=
equiv.symm $ @equiv.of_bijective α (with_zero (units α))
(λ a, if h : a = 0 then 0 else group_with_zero.mk₀ a h)
begin
  split,
  { intros a b, dsimp,
    split_ifs; simp [with_zero.coe_inj, units.ext_iff, *], },
  { intros a, with_zero_cases a,
    { exact ⟨0, dif_pos rfl⟩ },
    { refine ⟨a, _⟩, rw [dif_neg (group_with_zero.unit_ne_zero a)],
      simp [with_zero.coe_inj, units.ext_iff, *] } }
end

variable {α}

@[simp] lemma zero_le {a : α} : 0 ≤ a := zero_le' a

@[simp] lemma le_zero_iff {a : α} : a ≤ 0 ↔ a = 0 :=
⟨λ h, _root_.le_antisymm h zero_le, λ h, h ▸ le_refl _⟩

variables {a b c : α}

lemma le_of_le_mul_right (h : c ≠ 0) (hab : a * c ≤ b * c) : a ≤ b :=
by simpa [h] using linear_ordered_structure.mul_le_mul_right hab c⁻¹

lemma le_mul_inv_of_mul_le (h : c ≠ 0) (hab : a * c ≤ b) : a ≤ b * c⁻¹ :=
le_of_le_mul_right h (by simpa [h] using hab)

lemma mul_inv_le_of_le_mul (h : c ≠ 0) (hab : a ≤ b * c) : a * c⁻¹ ≤ b :=
le_of_le_mul_right h (by simpa [h] using hab)

def with_zero_adj_units {β : Type*} [linear_ordered_comm_group β] (f : β →* units α) :
  with_zero β →* α :=
monoid_hom.mk
(λ x, match x with
| 0 := 0
| some b := f b
end)
(show (f 1 : α) = 1, by { rw f.map_one, refl })
begin
  intros x y, with_zero_cases x y,
  { show (0 : α) = 0 * 0, exact (zero_mul _).symm },
  { show (0 : α) = 0 * _, exact (zero_mul _).symm },
  { show (0 : α) = _ * 0, exact (mul_zero _).symm },
  { show (f (x*y) : α) = f x * f y, rw f.map_mul, refl },
end

open group_with_zero

lemma div_le_div (a b c d : α) (hb : b ≠ 0) (hd : d ≠ 0) :
  a * b⁻¹ ≤ c * d⁻¹ ↔ a * d ≤ c * b :=
begin
  by_cases ha : a = 0,
  { simp [ha] },
  by_cases hc : c = 0,
  { replace hb := inv_ne_zero' _ hb,
    simp [hb, hc, hd], },
  exact (linear_ordered_structure.div_le_div
    (mk₀ a ha) (mk₀ b hb) (mk₀ c hc) (mk₀ d hd)),
end

section

local attribute [instance] classical.prop_decidable
local attribute [instance, priority 0] classical.decidable_linear_order

lemma lt_of_mul_lt_mul_left {a b c : α} (h : a * b < a * c) : b < c :=
begin
  by_cases ha : a = 0, { contrapose! h, simp [ha] },
  by_cases hc : c = 0, { contrapose! h, simp [hc] },
  by_cases hb : b = 0, { contrapose! hc, simpa [hb] using hc },
  exact linear_ordered_structure.lt_of_mul_lt_mul_left (mk₀ a ha) (mk₀ b hb) (mk₀ c hc) h
end

instance : actual_ordered_comm_monoid α :=
{ lt_of_mul_lt_mul_left := λ a b c, lt_of_mul_lt_mul_left,
  .. ‹linear_ordered_comm_group_with_zero α› }

end

end linear_ordered_comm_group_with_zero


namespace linear_ordered_structure
variables {α : Type*} [group_with_zero α]
variables {a b c d : α}

lemma ne_zero_iff_exists : a ≠ 0 ↔ ∃ u : units α, a = u :=
begin
  split,
  { intro h, use [group_with_zero.mk₀ a h], refl },
  { rintro ⟨u, rfl⟩, exact group_with_zero.unit_ne_zero u }
end

end linear_ordered_structure

namespace linear_ordered_structure
variables {α : Type*} [linear_ordered_comm_group_with_zero α]
variables {a b c d : α}

local attribute [instance] classical.prop_decidable
local attribute [instance, priority 0] classical.decidable_linear_order

@[move_cast] lemma coe_min (x y : units α) :
  ((min x y : units α) : α) = min (x : α) (y : α) :=
begin
  by_cases h: x ≤ y,
  { simp [min_eq_left, h] },
  { simp [min_eq_right, le_of_not_le h] }
end

lemma ne_zero_of_gt (h : a > b) : a ≠ 0 :=
by { contrapose! h, simp [h] }

@[simp] lemma zero_lt_unit (u : units α) : (0 : α) < u :=
by { have h := group_with_zero.unit_ne_zero u, contrapose! h, simpa using h }

lemma mul_lt_mul' : a < b → c < d → a*c < b*d :=
begin
  intros hab hcd,
  let b' := group_with_zero.mk₀ b (ne_zero_of_gt hab),
  let d' := group_with_zero.mk₀ d (ne_zero_of_gt hcd),
  have hbd : 0 < b * d,
  { have h := group_with_zero.unit_ne_zero (b' * d'), contrapose! h, simpa using h },
  by_cases ha : a = 0,
  { simp [ha, hbd], },
  by_cases hc : c = 0,
  { simp [hc, hbd], },
  let a' := group_with_zero.mk₀ a ha,
  let c' := group_with_zero.mk₀ c hc,
  show a' * c' < b' * d',
  exact linear_ordered_structure.mul_lt_mul hab hcd
end

lemma mul_inv_lt_of_lt_mul' {x y z : α} (h : x < y*z) : x*z⁻¹ < y :=
begin
  by_cases hx : x = 0, { contrapose! h, simp * at *, },
  by_cases hy : y = 0, { contrapose! h, simp [hy] },
  by_cases hz : z = 0, { contrapose! h, simp [hz] },
  change (group_with_zero.mk₀ _ hx) < (group_with_zero.mk₀ _ hy) * (group_with_zero.mk₀ _ hz) at h,
  exact mul_inv_lt_of_lt_mul h
end
.

lemma mul_lt_right' (γ : α) (h : a < b) (hγ : γ ≠ 0) : a*γ < b*γ :=
begin
  have hb : b ≠ 0 := ne_zero_of_gt h,
  by_cases ha : a = 0,
  { by_contra H, simp [ha] at H, tauto, },
  change (group_with_zero.mk₀ _ ha) < (group_with_zero.mk₀ _ hb) at h,
  exact linear_ordered_structure.mul_lt_right (group_with_zero.mk₀ _ hγ) h
end

end linear_ordered_structure
