import valuation.field
import valuation.canonical

/-!
# The valuation on the completion of the valuation field

In this file we extend the canonical valuation on the the valuation field of (R, v) to its
completion (for the topological field structure coming from the valuation).
-/

noncomputable theory

open valuation uniform_space
local attribute [instance] valued.subgroups_basis valued.uniform_space

variables {Γ₀ : Type*} [linear_ordered_comm_group_with_zero Γ₀]
variables {R : Type*} [comm_ring R] (v : valuation R Γ₀)

local notation `hat` K := completion K

namespace valuation_field

instance : valued (valuation_field v) :=
⟨value_monoid v, valuation_field.canonical_valuation v⟩

instance : topological_space (valuation_field v) :=
subgroups_basis.topology _

instance : topological_ring (valuation_field v) :=
ring_filter_basis.is_topological_ring _ rfl

instance : uniform_add_group (valuation_field v) :=
topological_add_group_is_uniform

instance : comm_ring (hat v.valuation_field) :=
completion.comm_ring _

instance : ring (hat v.valuation_field) :=
comm_ring.to_ring _

end valuation_field

/--The valuation on the completion of the valuation field of a valued ring.-/
def valuation_on_completion (v : valuation R Γ₀) :
  valuation (hat v.valuation_field) (value_monoid v) :=
valued.extension_valuation

instance valuation_field.completion_valued : valued (completion $ valuation_field v) :=
⟨value_monoid v, valuation_on_completion v⟩


#sanity_check
#doc_blame


