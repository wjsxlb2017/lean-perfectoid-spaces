import data.padics

import for_mathlib.field_power
import for_mathlib.ideal_operations
import for_mathlib.padics

import adic_space

/-!
# The p-adics form a Huber ring

In this file we show that ℤ_[p] and ℚ_[p] are Huber rings. They are the fundamental examples
of Huber rings.
-/

noncomputable theory

namespace polynomial

lemma monic.as_sum {R : Type*} [comm_ring R] {f : polynomial R} (hf : f.monic) :
  f = X^(f.nat_degree) + ((finset.range f.nat_degree).sum $ λ i, C (f.coeff i) * X^i) :=
begin
  rw polynomial.ext, intro n,
  rw [coeff_add, coeff_X_pow],
  rw show coeff (finset.sum (finset.range (nat_degree f)) (λ (i : ℕ), C (coeff f i) * X ^ i)) n =
    (finset.sum (finset.range (nat_degree f)) (λ (i : ℕ), coeff (C (coeff f i) * X ^ i) n)),
  { symmetry,
    let tmp : _ := _,
    refine @finset.sum_hom _ _ _ _ _ _ _ (λ f, coeff f n) tmp,
    exact { map_add := λ f g, coeff_add f g n, map_zero := rfl }, },
  split_ifs with h,
  { subst h, convert (add_zero _).symm, { symmetry, exact hf },
    apply finset.sum_eq_zero,
    intros i hi, rw finset.mem_range at hi, replace hi := ne_of_gt hi,
    simp [hi], },
  { rw zero_add,
    by_cases hn : n < nat_degree f,
    { rw finset.sum_eq_single n, { simp, },
      { intros i hi hin, simp [hin.symm], },
      { rw finset.mem_range, intro H, contradiction, } },
    { push_neg at hn, replace hn := lt_of_le_of_ne hn h.symm,
      rw [finset.sum_eq_zero, coeff_eq_zero_of_degree_lt],
      { refine lt_of_le_of_lt degree_le_nat_degree _, rwa with_bot.coe_lt_coe },
      { intros i hi, rw finset.mem_range at hi, have : n ≠ i, by linarith, simp [this], } } }
end

end polynomial

lemma finset.fold_max_lt {α : Type*} {β : Type*} [decidable_eq α] [decidable_linear_order β]
  (s : finset α) (f : α → β) (b x : β) :
  s.fold max b f < x ↔ (b < x ∧ ∀ a∈s, f a < x) :=
begin
  apply finset.induction_on s, { simp, },
  clear s, intros a s ha IH,
  rw [finset.fold_insert ha, max_lt_iff, IH, ← and_assoc, and_comm (f a < x), and_assoc],
  apply and_congr iff.rfl,
  split,
  { rintro ⟨h₁, h₂⟩, intros b hb, rw finset.mem_insert at hb,
    rcases hb with rfl|hb; solve_by_elim },
  { intro h, split,
    { exact h a (finset.mem_insert_self _ _), },
    { intros b hb, apply h b, rw finset.mem_insert, right, exact hb } }
end

open local_ring

local attribute [instance] padic_int.algebra

variables (p : ℕ) [nat.prime p]

namespace padic_int

/-- The topology on ℤ_[p] is adic with respect to the maximal ideal.-/
lemma is_adic : is_ideal_adic (nonunits_ideal ℤ_[p]) :=
begin
  rw is_ideal_adic_iff,
  split,
  { intro n,
    show is_open (↑(_ : ideal ℤ_[p]) : set ℤ_[p]),
    rw power_nonunits_ideal_eq_norm_le_pow,
    simp only [norm_le_pow_iff_norm_lt_pow_succ],
    rw ← ball_0_eq,
    exact metric.is_open_ball },
  { intros s hs,
    rcases metric.mem_nhds_iff.mp hs with ⟨ε, ε_pos, hε⟩,
    obtain ⟨n, hn⟩ : ∃ n : ℕ, (p : ℝ)^-(n:ℤ) < ε,
    { have hp : (1:ℝ) < p := by exact_mod_cast nat.prime.one_lt ‹_›,
      obtain ⟨n, hn⟩ : ∃ (n:ℕ), ε⁻¹ < p^n := pow_unbounded_of_one_lt ε⁻¹ hp,
      use n,
      have hp' : (0:ℝ) < p^n,
      { rw ← fpow_of_nat, apply fpow_pos_of_pos, exact_mod_cast nat.prime.pos ‹_› },
      rw [inv_lt ε_pos hp', inv_eq_one_div] at hn,
      rwa [fpow_neg, fpow_of_nat], },
    use n, show (↑(_ : ideal ℤ_[p]) : set ℤ_[p]) ⊆ _,
    refine set.subset.trans _ hε,
    rw power_nonunits_ideal_eq_norm_le_pow,
    rw ball_0_eq,
    intros x hx,
    rw set.mem_set_of_eq at *,
    exact lt_of_le_of_lt hx hn }
end

section
open polynomial

lemma is_integrally_closed : is_integrally_closed ℤ_[p] ℚ_[p] :=
{ inj := subtype.val_injective,
  closed :=
  begin
    rintros x ⟨f, f_monic, hf⟩,
    have bleh : eval₂ (algebra_map ℚ_[p]) x ((finset.range (nat_degree f)).sum (λ (i : ℕ), C (coeff f i) * X^i)) =
      ((finset.range (nat_degree f)).sum (λ (i : ℕ), eval₂ (algebra_map ℚ_[p]) x $ C (coeff f i) * X^i)),
    { exact (finset.sum_hom _).symm },
    erw subtype.val_range,
    show ∥x∥ ≤ 1,
    rw [f_monic.as_sum, aeval_def, eval₂_add, eval₂_pow, eval₂_X] at hf,
    rw [bleh] at hf,
    replace hf := congr_arg (@has_norm.norm ℚ_[p] _) hf,
    contrapose! hf with H,
    apply ne_of_gt,
    rw [norm_zero, padic_norm_e.add_eq_max_of_ne],
    { apply lt_of_lt_of_le _ (le_max_left _ _),
      rw [← fpow_of_nat, norm_fpow],
      apply fpow_pos_of_pos,
      exact lt_trans zero_lt_one H, },
    { apply ne_of_gt,
      apply lt_of_le_of_lt (padic.norm_sum _ _),
      rw finset.fold_max_lt,
      split,
      { rw [← fpow_of_nat, norm_fpow], apply fpow_pos_of_pos, exact lt_trans zero_lt_one H },
      { intros i hi,
        suffices : ∥algebra_map ℚ_[p] (coeff f i)∥ * ∥x∥ ^ i < ∥x∥ ^ nat_degree f,
        by simpa [eval₂_pow],
        refine lt_of_le_of_lt (mul_le_of_le_one_left _ _ : _ ≤ ∥x∥ ^ i) _,
        { rw [← fpow_of_nat], apply fpow_nonneg_of_nonneg, exact norm_nonneg _ },
        { exact (coeff f i).property },
        { rw [← fpow_of_nat, ← fpow_of_nat, (fpow_strict_mono H).lt_iff_lt],
          rw finset.mem_range at hi, exact_mod_cast hi, } } }
  end }

end

/-- The p-adic integers (ℤ_[p])form a Huber ring.-/
instance : Huber_ring ℤ_[p] :=
{ pod := ⟨ℤ_[p], infer_instance, infer_instance, by apply_instance,
  ⟨{ emb := open_embedding_id,
    J := (nonunits_ideal _),
    fin := nonunits_ideal_fg p,
    top := is_adic p,
    .. algebra.id ℤ_[p] }⟩⟩ }

end padic_int

section
variables {α : Type*} {β : Type*} [topological_space α] [topological_space β]
lemma is_open_map.image_nhds {f : α → β} (hf : is_open_map f)
  {x : α} {U : set α} (hU : U ∈ nhds x) : f '' U ∈ nhds (f x) :=
begin
  apply (is_open_map_iff_nhds_le f).mp hf x,
  change f ⁻¹' (f '' U) ∈ nhds x,
  filter_upwards [hU],
  exact set.subset_preimage_image f U
end
end

open local_ring set padic_int

/-- The p-adic numbers (ℚ_[p]) form a Huber ring.-/
instance padic.Huber_ring : Huber_ring ℚ_[p] :=
{ pod := ⟨ℤ_[p], infer_instance, infer_instance, by apply_instance,
  ⟨{ emb := coe_open_embedding,
    J := (nonunits_ideal _),
    fin := nonunits_ideal_fg p,
    top := is_adic p,
    .. padic_int.algebra }⟩⟩ }

@[reducible] def padic.Huber_pair : Huber_pair :=
{ plus := ℤ_[p],
  carrier := ℚ_[p],
  intel :=
  { is_power_bounded :=
    begin
      -- this entire goal ought to follow from some is_bounded.map lemma
      -- but we didn't prove that.
      suffices : is_bounded {x : ℚ_[p] | ∥x∥ ≤ 1},
      { rintro _ ⟨x, rfl⟩,
        show is_power_bounded (x:ℚ_[p]),
        refine is_bounded.subset _ this,
        rintro y ⟨n, rfl⟩,
        show ∥(x:ℚ_[p])^n∥ ≤ 1,
        rw _root_.norm_pow, -- TODO: put this in norm_field namespace in mathlib
        exact pow_le_one _ (norm_nonneg _) x.property, },
      have bnd := is_adic.is_bounded ⟨_, is_adic p⟩,
      intros U hU,
      rcases bnd ((coe : ℤ_[p] → ℚ_[p]) ⁻¹' U) _ with ⟨V, hV, H⟩,
      { use [(coe : ℤ_[p] → ℚ_[p]) '' V,
             coe_open_embedding.is_open_map.image_nhds hV],
        rintros _ ⟨v, v_in, rfl⟩ b hb,
        specialize H v v_in ⟨b, hb⟩ (mem_univ _),
        rwa [mem_preimage, coe_mul] at H },
      { rw ← padic_int.coe_zero at hU, -- TODO: put coe_zero from mathlib group_completion in a ns
        exact continuous_coe.continuous_at hU }
    end
    .. coe_open_embedding,
    .. is_integrally_closed p } }
.

@[simp] lemma nnreal.coe_max (x y : nnreal) : ((max x y : nnreal) : ℝ) = max (x : ℝ) (y : ℝ) :=
by { delta max, split_ifs; refl }

def padic.bundled_valuation : valuation ℚ_[p] nnreal :=
{ to_fun := λ x, ⟨∥x∥, norm_nonneg _⟩,
  map_zero' := subtype.val_injective norm_zero,
  map_one' := subtype.val_injective norm_one,
  map_mul' := λ x y, subtype.val_injective $ norm_mul _ _,
  map_add' := λ x y,
  begin
    apply le_trans (padic_norm_e.nonarchimedean x y),
    rw max_le_iff,
    simp [nnreal.coe_max],
    split,
    { apply le_trans (le_max_left ∥x∥ ∥y∥),
      apply le_of_eq, symmetry, convert nnreal.coe_max _ _,
      delta classical.decidable_linear_order nnreal.decidable_linear_order real.decidable_linear_order,
      congr, },
    { apply le_trans (le_max_right ∥x∥ ∥y∥),
      apply le_of_eq, symmetry, convert nnreal.coe_max _ _,
      delta classical.decidable_linear_order nnreal.decidable_linear_order real.decidable_linear_order,
      congr, },
  end }

def padic.Spa_inhabited : inhabited (Spa $ padic.Huber_pair p) :=
{ default := ⟨Spv.mk (padic.bundled_valuation p),
  begin
    refine mk_mem_spa.mpr _,
    split,
    { rintro r,
      change is_open {x : ℚ_[p] | _ },
      have := valuation.value_monoid.to_Γ₀_strict_mono (padic.bundled_valuation p),
      simp only [this.lt_iff_lt.symm],
      suffices : is_open {x : ℚ_[p] | ∥x∥ < ↑(valuation.value_monoid.to_Γ₀ (padic.bundled_valuation p) r)},
      { convert this, ext x, convert iff.rfl,
        have tmp := (valuation.canonical_valuation.to_Γ₀ (padic.bundled_valuation p)),
        rw show valuation.value_monoid.to_Γ₀ (padic.bundled_valuation p)
         ((valuation.canonical_valuation (padic.bundled_valuation p)) x) = padic.bundled_valuation p x,
        { sorry },
        refl, },
      rw ← ball_0_eq,
      exact metric.is_open_ball },
    { intro x, change ℤ_[p] at x, exact x.property },
  end⟩ }

@[extensionality]
lemma Spv.ext {R : Type*} [comm_ring R] (v₁ v₂ : Spv R) (h : (Spv.out v₁).is_equiv (Spv.out v₂)) :
  v₁ = v₂ :=
by simpa only [Spv.mk_out] using Spv.sound h

lemma Spv.ext_iff {R : Type*} [comm_ring R] {v₁ v₂ : Spv R} :
  v₁ = v₂ ↔ ((Spv.out v₁).is_equiv (Spv.out v₂)) :=
⟨λ h, Spv.is_equiv_of_eq_mk (by simpa only [Spv.mk_out] using h), Spv.ext _ _⟩

@[extensionality]
lemma spa.ext {A : Huber_pair} (v₁ v₂ : spa A) (h : (Spv.out ↑v₁).is_equiv (Spv.out (↑v₂ : Spv A))) :
  v₁ = v₂ :=
subtype.val_injective $ Spv.ext _ _ h

lemma spa.ext_iff {A : Huber_pair} {v₁ v₂ : spa A} :
  v₁ = v₂ ↔ ((Spv.out ↑v₁).is_equiv (Spv.out (↑v₂ : Spv A))) :=
by rw [subtype.coe_ext, Spv.ext_iff]

namespace valuation
variables {K : Type*} [discrete_field K]
variables {Γ₀ : Type*} [linear_ordered_comm_group_with_zero Γ₀]
variables {Γ'₀ : Type*} [linear_ordered_comm_group_with_zero Γ'₀]
variables (v : valuation K Γ₀) (v' : valuation K Γ'₀)

lemma is_equiv_of_val_le_one (h : ∀ {x:K}, v x ≤ 1 ↔ v' x ≤ 1) : v.is_equiv v' :=
begin
  intros x y,
  by_cases hy : y = 0, { simp [hy, zero_iff], },
  rw show y = 1 * y, by rw one_mul,
  rw show x = (x * y⁻¹) * y, { rw [mul_assoc, inv_mul_cancel hy, mul_one], },
  iterate 2 {rw [v.map_mul _ y, v'.map_mul _ y]},
  rw [v.map_one, v'.map_one],
  split; intro H,
  { apply actual_ordered_comm_monoid.mul_le_mul_right',
    replace hy := v.ne_zero_iff.mpr hy,
    replace H := linear_ordered_structure.le_of_le_mul_right hy H,
    rwa h at H, },
  { apply actual_ordered_comm_monoid.mul_le_mul_right',
    replace hy := v'.ne_zero_iff.mpr hy,
    replace H := linear_ordered_structure.le_of_le_mul_right hy H,
    rwa h, },
end

end valuation

namespace linear_ordered_comm_group_with_zero
variables {Γ₀ : Type*} [linear_ordered_comm_group_with_zero Γ₀]

lemma inv_lt_inv {x y : Γ₀} (hx : x ≠ 0) (hy : y ≠ 0) :
  y⁻¹ < x⁻¹ ↔ x < y :=
begin
  suffices : ∀ {x y : Γ₀}, x ≠ 0 → y ≠ 0 → x < y → y⁻¹ < x⁻¹,
  { refine ⟨_, this hx hy⟩, intro h, rw [← inv_inv'' x, ← inv_inv'' y],
    apply this _ _ h; solve_by_elim [inv_ne_zero'], },
  clear hx hy x y,
  intros x y hx hy h,
  have hx' : x⁻¹ ≠ 0 := by solve_by_elim [inv_ne_zero'],
  have hy' : y⁻¹ ≠ 0 := by solve_by_elim [inv_ne_zero'],
  replace h := linear_ordered_structure.mul_lt_right' _ h hx',
  replace h := linear_ordered_structure.mul_lt_right' _ h hy',
  rw [mul_inv_cancel' _ hx, one_mul] at h,
  erw [mul_comm y x⁻¹, mul_assoc, mul_inv_cancel' _ hy, mul_one] at h,
  exact h
end

end linear_ordered_comm_group_with_zero

def padic.Spa_unique : unique (Spa $ padic.Huber_pair p) :=
{ uniq :=
  begin
    intros v,
    ext,
    refine valuation.is_equiv.trans _ (Spv.out_mk _).symm,
    apply valuation.is_equiv_of_val_le_one,
    intros x, change ℚ_[p] at x,
    split; intro h,
    { classical,
      by_cases hx : ∃ y : ℤ_[p], x = y,
      { rcases hx with ⟨x, rfl⟩, exact x.property },
      { push_neg at hx,
        contrapose! h,
        obtain ⟨y, hy⟩ : ∃ y : ℤ_[p], x⁻¹ = y,
        { refine ⟨⟨x⁻¹, _⟩, rfl⟩, rw norm_inv, apply inv_le_one, apply le_of_lt, exact h },
        refine (linear_ordered_comm_group_with_zero.inv_lt_inv _ _).mp _,
        { exact one_ne_zero },
        { rw valuation.ne_zero_iff, contrapose! hx, use [0, hx] },
        { rw [inv_one', ← valuation.map_inv, hy],
          refine lt_of_le_of_ne (v.property.right y) _,
          -- the valuation can't map everything to 1
          -- because of continuity
          sorry
           },
         } },
    { exact v.property.right ⟨x, h⟩, }
  end,
  .. padic.Spa_inhabited p }
