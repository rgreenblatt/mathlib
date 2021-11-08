/-
Copyright (c) 2021 Chris Birkbeck. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Chris Birkbeck
-/
import group_theory.index
import group_theory.quotient_group
import group_theory.subgroup.pointwise
import group_theory.group_action.conj_act
/-!
# Commensurability for subgroups

This file defines commensurability for subgroups of a group `G`. It then goes on to prove that
commensurability defines an equivalence relation and finally defines the commensurator of a subgroup
of `G`.

## Main definitions

* `commensurable`: defines commensurability for two subgroups `H`, `K` of  `G`
* `commensurator`: defines the commensurator of a a subgroup `H` of `G`.
-/

variables {G : Type*} [group G]

/--Two subgroups `H K` of `G` are commensurable if `H ⊓ K` has finite index in both `H` and `K` -/
def commensurable (H K : subgroup G) : Prop :=
H.relindex K ≠ 0 ∧ K.relindex H ≠ 0

namespace commensurable

open_locale pointwise

@[refl] protected lemma refl (H : subgroup G) : commensurable H H := by
 simp only [commensurable, nat.one_ne_zero, ne.def, not_false_iff, and_self, subgroup.relindex_self]

lemma comm {H K : subgroup G} : commensurable H K ↔ commensurable K H := and.comm

@[symm] lemma symm {H K : subgroup G} : commensurable H K → commensurable K H := and.symm

@[trans] lemma trans {H K L : subgroup G} (hhk : commensurable H K ) (hkl : commensurable K L) :
  commensurable H L :=
⟨subgroup.relindex_ne_zero_trans H K L hhk.1 hkl.1,
  subgroup.relindex_ne_zero_trans L K H hkl.2 hhk.2⟩

lemma equivalence : equivalence (@commensurable G _) :=
⟨commensurable.refl, λ _ _, commensurable.symm, λ _ _ _, commensurable.trans⟩

/--Equivalence of `K/H ⊓ K` with `gKg⁻¹/gHg⁻¹ ⊓ gKg⁻¹`-/
def  quot_conj_equiv (H K : subgroup G) (g : conj_act G) :
  quotient_group.quotient (H.subgroup_of K) ≃
  quotient_group.quotient ((g • H).subgroup_of (g • K)) :=
quotient.congr (K.equiv_smul g).to_equiv (λ a b, by rw [←quotient.eq', ←quotient.eq',
  quotient_group.eq', quotient_group.eq', subgroup.mem_subgroup_of, subgroup.mem_subgroup_of,
  mul_equiv.coe_to_equiv, ←mul_equiv.map_inv, ←mul_equiv.map_mul,
  subgroup.equiv_smul_apply_coe, subgroup.smul_mem_pointwise_smul_iff])

lemma commensurable_conj {H K : subgroup G} (g : conj_act G) :
   commensurable H K ↔ commensurable (g • H) (g • K) :=
and_congr (not_iff_not.mpr (eq.congr_left (cardinal.to_nat_congr (quot_conj_equiv H K g))))
  (not_iff_not.mpr (eq.congr_left (cardinal.to_nat_congr (quot_conj_equiv K H g))))

lemma commensurable_inv (H : subgroup G) (g : conj_act G) :
  commensurable (g • H) H ↔ commensurable H (g⁻¹ • H) :=
 by rw [commensurable_conj, inv_smul_smul]

/--For `H` a subgroup of `G`, this is the subgroup of all elements `g : conj_aut G`
such that `commensurable ( g • H) H`   -/

def commensurator' (H : subgroup G) : subgroup (conj_act G) :=
{ carrier := {g : conj_act G | commensurable (g • H) H},
  one_mem' := by rw [set.mem_set_of_eq, one_smul],
  mul_mem' := λ a b ha hb, by
  { rw [set.mem_set_of_eq, mul_smul],
    exact trans ((commensurable_conj a).mp hb) ha },
  inv_mem' := λ a ha, by rwa [set.mem_set_of_eq, comm, ←commensurable_inv] }

/--For `H` a subgroup of `G`, this is the subgroup of all elements `g : G`
such that `commensurable ( g H g⁻¹) H`   -/

def commensurator (H : subgroup G) : subgroup G :=
  (commensurator' H).map (conj_act.of_conj_act.to_monoid_hom)

@[simp]
lemma commensurator'_mem_iff (H : subgroup G) (g : conj_act G) :
  g ∈ (commensurator' H) ↔ commensurable (g • H) H := iff.rfl

@[simp]
lemma commensurator_mem_iff (H : subgroup G) (g : G) :
  g ∈ (commensurator H) ↔ commensurable (conj_act.to_conj_act g • H) H :=
begin
rw commensurator,
simp only [exists_prop, mul_equiv.coe_to_monoid_hom, commensurator'_mem_iff, subgroup.mem_map],
split,
intro h,
obtain ⟨x, hx⟩ := h,
rw ← hx.2,
simp only [conj_act.to_conj_act_of_conj_act],
apply hx.1,
intro h,
use conj_act.to_conj_act g,
simp only [h, conj_act.of_conj_act_to_conj_act, eq_self_iff_true, and_self],
end

lemma commensurable_subgroups_have_eq_commensurator (H K : subgroup G) :
  commensurable H K → commensurator H = commensurator K :=
begin
  intro hk,
  ext,
  simp only [commensurator_mem_iff],
  have h1 := (commensurable_conj x).1 hk,
  split,
  intro h,
  have h2 := trans h hk,
  apply trans (symm h1) h2,
  intro h,
  apply trans (trans h1 h) (symm hk),
end

end commensurable