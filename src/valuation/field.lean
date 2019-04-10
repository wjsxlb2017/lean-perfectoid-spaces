import for_mathlib.topological_field
import for_mathlib.topology
import for_mathlib.division_ring
import valuation.topology

open filter set

local attribute [instance, priority 0] classical.decidable_linear_order
variables {Γ : Type*} [linear_ordered_comm_group Γ]


def valued_ring (R : Type*) [ring R] (v : valuation R Γ) := R

namespace valued_ring
variables {R : Type*} [ring R]
variables (v : valuation R Γ)

instance : ring (valued_ring R v) := ‹ring R›


instance : ring_with_zero_nhd (valued_ring R v) := valuation.ring_with_zero_nhd v

variables {K : Type*} [division_ring K] (ν : valuation K Γ)

instance : division_ring (valued_ring K ν) := ‹division_ring K›
end valued_ring

variables {K : Type*} [division_ring K] (v : valuation K Γ)

variables x y : units K

-- The following is meant to be the main technical lemma ensuring that inversion is continuous
-- in the topology induced by a valuation on a division ring (ie the next instance)
-- [BouAC, VI.5.1 Lemme 1]
lemma top_div_ring_aux {x y : units K} {γ : Γ} (h : v (x - y) < min (γ*((v y)*(v y))) (v y)) :
  v (x⁻¹.val - y⁻¹.val) < γ :=
begin
  have hyp1 : v (x - y) < γ*((v y)*(v y)),
    from lt_of_lt_of_le h (min_le_left _ _),
  have hyp1' : v (x - y)*((v y)*(v y))⁻¹ < γ,
    from with_zero.mul_inv_lt_of_lt_mul hyp1,
  have hyp2 : v (x - y) < v y,
    from lt_of_lt_of_le h (min_le_right _ _),
  have key : v x = v y, from valuation.map_eq_of_sub_lt v hyp2,
  have decomp : x⁻¹.val - y⁻¹.val = x⁻¹.val*(y.val-x.val)*y⁻¹.val,
  by rw [mul_sub_left_distrib, sub_mul, mul_assoc,
        show y.val * y⁻¹.val = 1, from y.val_inv,
        show x⁻¹.val * x.val = 1, from x.inv_val, mul_one, one_mul],
  calc
    v (x⁻¹.val - y⁻¹.val) = v (x⁻¹.val*(y.val-x.val)*y⁻¹.val) : by rw decomp
    ... = (v x⁻¹.val)*(v $ y.val-x.val)*(v y⁻¹.val) : by repeat { rw valuation.map_mul }
    ... = (v x)⁻¹*(v $ y.val-x.val)*(v y)⁻¹ : by repeat { rw valuation.map_inv }
    ... = (v $ y.val-x.val)*((v y)*(v y))⁻¹ : by rw [mul_assoc,mul_comm, key, mul_assoc, ← with_zero.mul_inv_rev]
    ... = (v $ y - x)*((v y)*(v y))⁻¹ : rfl
    ... = (v $ x - y)*((v y)*(v y))⁻¹ : by rw valuation.map_sub_swap
    ... < γ : hyp1',
end

/-- The topology coming from a valuation on a division ring make it a topological division ring
    [BouAC, VI.5.1 middle of Proposition 1] -/
instance valuation.topological_division_ring : topological_division_ring (valued_ring K v) :=
{ continuous_inv :=
    begin
      let Kv := valued_ring K v,
      have H : units.val ∘ (λ x : units Kv, x⁻¹) = (λ x : Kv, x⁻¹) ∘ units.val,
        by ext ;simp,
      rw continuous_iff_continuous_at,
      intro x,
      let emb := topological_ring.units_embedding Kv,
      apply emb.tendsto_iff emb H,
      unfold continuous_at,
      rw  topological_add_group.tendsto_nhds_nhds_iff (λ (x : Kv), x⁻¹) x.val x.val⁻¹,
      intros V V_in,
      cases (of_subgroups.nhds_zero _).1 V_in with γ Hγ,
      let x' : units K := units.mk (x.val : K) (x.inv : K) x.val_inv x.inv_val,
      use { k : Kv | v k < min (γ*((v x')*(v x'))) (v x')},
      split,
      { refine (of_subgroups.nhds_zero _).2 _,
        cases valuation.unit_is_some v x' with γ' hγ',
        use min (γ * γ' * γ') γ',
        intro k,
        simp only [hγ'],
        intro h, convert h, ext, convert iff.rfl,
        rw [with_zero.coe_min, mul_assoc], refl },
      { intros y ineq,
        apply Hγ,
        rw mem_set_of_eq,
        -- I sort of lost that y is a unit, but fortunately, it is easy to prove it's not zero
        have : y ≠ 0,
        { intro hy,
          simp [hy] at ineq,
          exact lt_irrefl _ ineq.2 },
        let yu := units.mk' this,
        change v ((yu : Kv) - (x : Kv)) < _ at ineq,
        convert top_div_ring_aux v ineq,
        apply congr_arg,
        congr,
        simp },
    end,
  ..(by apply_instance : topological_ring (valued_ring K v)) }

section
-- until the end of this section, all linearly ordered commutative groups will be endowed with
-- the discrete topology
def discrete_ordered_comm_group : topological_space Γ := ⊤
local attribute [instance] discrete_ordered_comm_group

def ordered_comm_group_is_discrete : discrete_topology Γ := ⟨rfl⟩
local attribute [instance] ordered_comm_group_is_discrete

instance discrete_top_group' {G : Type*} [group G] [topological_space G] [discrete_topology G] :
  topological_group G :=
{ continuous_mul := continuous_of_discrete_topology,
  continuous_inv := continuous_of_discrete_topology }


/-- The valuation map restricted to units of a field endowed with the valuation toplogy is
    continuous if we endow the target with discrete topology.
    [BouAC, VI.5.1 end of Proposition 1] -/
lemma continuous_unit_map :
@continuous _ _ (by apply_instance : topological_space (units $ valued_ring K v) ) _ v.unit_map :=
-- The ugly @ seems to comes from the valued_ring trick
begin
  rw continuous_into_discrete_iff,
  intro γ,
  rw is_open_iff_mem_nhds,
  intros x vx,
  rw [nhds_induced, ← nhds_translation_add_neg x.val, comap_comap_comp],
  use {y | v y < v.unit_map x },
  split,
  { -- Patrick has no idea why Lean needs so much baby-sitting. Patrick is tired
    exact @of_subgroups.mem_nhds_zero K _ Γ _ (λ γ : Γ, {k | v k < γ}) _ _ _ _ _ (v.unit_map x) },
  { intros z hz,
    rw [valuation.coe_unit_map] at hz,
    rw [mem_preimage_eq, mem_singleton_iff] at *,
    rw ← vx,
    exact valuation.unit_map.ext v x z (valuation.map_eq_of_sub_lt v hz),},
end
end
