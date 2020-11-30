/-
Copyright (c) 2020 Kevin Buzzard. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kevin Buzzard
-/

import topology.category.CompHaus

/-!
# The category of Profinite Types
We construct the category of profinite topological spaces,
often called profinite sets -- perhaps they could be called
profinite types in Lean.

The type of profinite topological spaces is called `Profinite`. It has a category
instance and is a fully faithful subcategory of `Top`. The fully faithful functor
is called `Profinite_to_Top`.

-- TODO
1) existence of products, limits(?), finite coproducts
2) `Profinite_to_Top` creates limits?
-/

open category_theory

/-- The type of profinite topological spaces. -/
structure Profinite :=
(to_Top : Top)
[is_compact : compact_space to_Top]
[is_t2 : t2_space to_Top]
[is_td : totally_disconnected_space to_Top]

namespace Profinite

instance : inhabited Profinite := ⟨{to_Top := { α := pempty }}⟩

instance : has_coe_to_sort Profinite := ⟨Type*, λ X, X.to_Top⟩
instance {X : Profinite} : compact_space X := X.is_compact
instance {X : Profinite} : t2_space X := X.is_t2
instance {X : Profinite} : totally_disconnected_space X := X.is_td

instance category : category Profinite := induced_category.category to_Top

end Profinite

/-- The fully faithful embedding of `Profinite` in `Top`. -/
@[simps {rhs_md := semireducible}, derive [full, faithful]]
def Profinite_to_Top : Profinite ⥤ Top := induced_functor _

/-- The fully faithful embedding of `Profinite` in `Top`. -/
@[simps] def Profinite_to_CompHaus : Profinite ⥤ CompHaus :=
{ obj := λ X, { to_Top := X.to_Top,
  is_compact := X.is_compact,
  is_hausdorff := X.is_t2 },
  map := λ _ _ f, f }

instance : full Profinite_to_CompHaus := { preimage := λ _ _ f, f }
instance : faithful Profinite_to_CompHaus := {}

@[simp] lemma Profinite_to_CompHaus_to_Top :
  Profinite_to_CompHaus ⋙ CompHaus_to_Top = Profinite_to_Top :=
rfl

#check limits.is_limit.of_faithful

namespace Profinite

open category_theory.limits

--def limit_aux
#check Top.limit_cone

noncomputable def limit_aux (J : Type*)
  (𝒥 : small_category J)
  (F : J ⥤ Profinite) :
  Profinite :=
{ to_Top := limit (F ⋙ Profinite_to_Top),
  is_compact := _,
  is_t2 := _,
  is_td := _ }

instance : has_limits Profinite :=
⟨λ J 𝒥, by exactI ⟨λ F, ⟨⟨⟨⟨by extract_goal, _⟩, _⟩⟩⟩⟩⟩
#exit
begin
  let ZZZ := limits.is_limit.of_faithful,
  sorry
end

end Profinite
