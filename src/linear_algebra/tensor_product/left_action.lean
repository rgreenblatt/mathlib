/-
Copyright (c) 2021 Jakob von Raumer. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kenny Lau, Mario Carneiro, Jakob von Raumer
-/
import group_theory.congruence
import linear_algebra.bilinear_map
import linear_algebra.tensor_product.def

/-!
# The canonical left action on a tensor product of modules

This file describes left actions of various algebraic structures on the left of the
tensor product of modules, based on the fact that if `M` is an `R'`-`R` bimodule,
`R'` acts on `M ⊗[R] N` by `r • (m ⊗ n) := (r • m ⊗ n)`.

## Tags

group action, tensor product
-/
namespace tensor_product

open_locale tensor_product

section semiring

variables {R : Type*} [semiring R]
variables {R' : Type*} [monoid R']
variables {R'' : Type*} [semiring R'']
variables {M N : Type*}
variables [add_comm_monoid M] [add_comm_monoid N]
variables [module Rᵒᵖ M] [module R N]
variables [distrib_mul_action R' M]
variables [module R'' M]


def rsmul.aux {R' : Type*} [has_scalar R' M] (r : R') :
  free_add_monoid (M × N) →+ M ⊗[R] N :=
free_add_monoid.lift $ λ p : M × N, (r • p.1) ⊗ₜ p.2

theorem rsmul.aux_of {R' : Type*} [has_scalar R' M] (r : R') (m : M) (n : N) :
  rsmul.aux r (free_add_monoid.of (m, n)) = (r • m) ⊗ₜ[R] n :=
rfl

variables [smul_comm_class Rᵒᵖ R' M]
variables [smul_comm_class Rᵒᵖ R'' M]

/-- Given two modules over a semiring `R`, if one of the factors carries a
(distributive) action of a second type of scalars `R'`, which commutes with the action of `R`, then
the tensor product (over `R`) carries an action of `R'`.

This instance defines this `R'` action in the case that it is the left module which has the `R'`
action. Two natural ways in which this situation arises are:
 * Extension of scalars
 * A tensor product of a group representation with a module not carrying an action
-/
instance left_has_scalar : has_scalar R' (M ⊗[R] N) :=
⟨λ r, (add_con_gen (tensor_product.eqv R M N)).lift (rsmul.aux r : _ →+ M ⊗[R] N) $
add_con.add_con_gen_le $ λ x y hxy, match x, y, hxy with
| _, _, (eqv.of_zero_left n)       := (add_con.ker_rel _).2 $
    by rw [add_monoid_hom.map_zero, rsmul.aux_of, smul_zero, zero_tmul]
| _, _, (eqv.of_zero_right m)      := (add_con.ker_rel _).2 $
    by simp_rw [add_monoid_hom.map_zero, rsmul.aux_of, tmul_zero]
| _, _, (eqv.of_add_left m₁ m₂ n)  := (add_con.ker_rel _).2 $
    by simp_rw [add_monoid_hom.map_add, rsmul.aux_of, smul_add, add_tmul]
| _, _, (eqv.of_add_right m n₁ n₂) := (add_con.ker_rel _).2 $
    by simp_rw [add_monoid_hom.map_add, rsmul.aux_of, tmul_add]
| _, _, (eqv.of_smul s m n)        := (add_con.ker_rel _).2 $
    by rw [rsmul.aux_of, rsmul.aux_of, ←smul_comm, rsmul_tmul]
| _, _, (eqv.add_comm x y)         := (add_con.ker_rel _).2 $
    by simp_rw [add_monoid_hom.map_add, add_comm]
end⟩

theorem smul_tmul' (r : R') (m : M) (n : N) :
  r • (m ⊗ₜ[R] n) = (r • m) ⊗ₜ n :=
rfl

protected theorem smul_zero (r : R') : (r • 0 : M ⊗[R] N) = 0 :=
add_monoid_hom.map_zero _

protected theorem smul_add  (r : R') (x y : M ⊗[R] N) :
  r • (x + y) = r • x + r • y :=
add_monoid_hom.map_add _ _ _

protected theorem zero_smul (x : M ⊗[R] N) : (0 : R'') • x = 0 :=
tensor_product.induction_on x
  (by rw tensor_product.smul_zero)
  (λ m n, by rw [smul_tmul', zero_smul, zero_tmul])
  (λ x y ihx ihy, by rw [tensor_product.smul_add, ihx, ihy, add_zero])

protected theorem one_smul (x : M ⊗[R] N) : (1 : R') • x = x :=
tensor_product.induction_on x
  (by rw tensor_product.smul_zero)
  (λ m n, by rw [smul_tmul', one_smul])
  (λ x y ihx ihy, by rw [tensor_product.smul_add, ihx, ihy])

protected theorem add_smul (r s : R'') (x : M ⊗[R] N) : (r + s) • x = r • x + s • x :=
have ∀ (r : R'') (m : M) (n : N), r • (m ⊗ₜ[R] n) = (r • m) ⊗ₜ n := λ _ _ _, rfl,
tensor_product.induction_on x
  (by simp_rw [tensor_product.smul_zero, add_zero])
  (λ m n, by simp_rw [this, add_smul, add_tmul])
  (λ x y ihx ihy, by { simp_rw tensor_product.smul_add, rw [ihx, ihy, add_add_add_comm] })

instance left_distrib_mul_action : distrib_mul_action R' (M ⊗[R] N) :=
{ smul := (•),
  smul_add := λ r x y, tensor_product.smul_add r x y,
  mul_smul := λ r s x, tensor_product.induction_on x
    (by simp_rw tensor_product.smul_zero)
    (λ m n, by simp_rw [smul_tmul', mul_smul])
    (λ x y ihx ihy, by { simp_rw tensor_product.smul_add, rw [ihx, ihy] }),
  one_smul := tensor_product.one_smul,
  smul_zero := tensor_product.smul_zero }

@[simp] lemma tmul_smul [has_scalar R'ᵒᵖ M] [is_symmetric_smul R' M]
  [has_scalar R' N] [compatible_smul R R' M N] (r : R') (x : M) (y : N) :
  x ⊗ₜ (r • y) = r • (x ⊗ₜ[R] y) :=
(smul_tmul _ _ _).symm

instance left_module : module R'' (M ⊗[R] N) :=
{ smul := (•),
  add_smul := tensor_product.add_smul,
  zero_smul := tensor_product.zero_smul,
  ..tensor_product.left_distrib_mul_action }

section
-- Like `R'`, `R'₂` provides a `distrib_mul_action R'₂ (M ⊗[R] N)`
variables {R'₂ : Type*} [monoid R'₂] [distrib_mul_action R'₂ M]
variables [smul_comm_class Rᵒᵖ R'₂ M] [has_scalar R'₂ R']

/-- `is_scalar_tower R'₂ R' M` implies `is_scalar_tower R'₂ R' (M ⊗[R] N)` -/
instance is_scalar_tower_left [is_scalar_tower R'₂ R' M] :
  is_scalar_tower R'₂ R' (M ⊗[R] N) :=
⟨λ s r x, tensor_product.induction_on x
  (by simp)
  (λ m n, by rw [smul_tmul', smul_tmul', smul_tmul', smul_assoc])
  (λ x y ihx ihy, by rw [smul_add, smul_add, smul_add, ihx, ihy])⟩

end

end semiring

section comm_semiring

variables {R : Type*} [comm_semiring R]
variables {R' : Type*} [monoid R']
variables {R'' : Type*} [comm_semiring R''] --?
variables {M N : Type*}
variables [add_comm_monoid M] [add_comm_monoid N]
variables [module R M] [module Rᵒᵖ M] [smul_comm_class Rᵒᵖ R M]
variables [module R N]
variables [distrib_mul_action R' M]
variables {P Q : Type*}
variables [add_comm_monoid P] [module R P]
variables [add_comm_monoid Q] [module R Q]

/-- The instance `tensor_product.left_has_scalar` induces this special case of `R` acting
on the left of the tensor product `M ⊗[R] N`. -/
instance right_has_scalar_comm : has_scalar R (M ⊗[R] N) := infer_instance

instance : distrib_mul_action R (M ⊗[R] N) := tensor_product.left_distrib_mul_action

instance : module R (M ⊗[R] N) := tensor_product.left_module

--set_option trace.class_instances true
/-- A short-cut instance of `is_scalar_tower_left` for the common case, where the requirements
for the `compatible_smul` instances are sufficient. -/
instance is_scalar_tower [smul_comm_class Rᵒᵖ R' M] [has_scalar R' R] [is_scalar_tower R' Rᵒᵖ M] :
  is_scalar_tower R' Rᵒᵖ (M ⊗[R] N) :=
tensor_product.is_scalar_tower_left

variables (R M N)
/-- The canonical bilinear map `M → N → M ⊗[R] N`. -/
def mk [is_symmetric_smul R M] : M →ₗ[R] N →ₗ[R] M ⊗[R] N :=
linear_map.mk₂ R (⊗ₜ) add_tmul (λ c m n, by rw [smul_tmul, tmul_smul]) tmul_add tmul_smul
variables {R M N}

@[simp] lemma mk_apply [is_symmetric_smul R M] [module Rᵒᵖ N] [is_symmetric_smul R N]
  (m : M) (n : N) : mk R M N m n = m ⊗ₜ n :=
rfl

/-- The simple (aka pure) elements span the tensor product. -/
lemma span_tmul_eq_top :
  submodule.span R { t : M ⊗[R] N | ∃ m n, m ⊗ₜ n = t } = ⊤ :=
begin
  ext t, simp only [submodule.mem_top, iff_true],
  apply t.induction_on,
  { exact submodule.zero_mem _, },
  { intros m n, apply submodule.subset_span, use [m, n], },
  { intros t₁ t₂ ht₁ ht₂, exact submodule.add_mem _ ht₁ ht₂, },
end

variables [is_symmetric_smul R M]

instance : is_symmetric_smul R (M ⊗[R] N) :=
⟨λ r x, tensor_product.induction_on x rfl
  (λ m n, by rw [smul_tmul' r, ←is_symmetric_smul.op_smul_eq_smul r m, smul_tmul'])
  (λ x y hx hy, by rw [smul_add, hx, hy, smul_add])⟩

section UMP

variables (f : M →ₗ[R] N →ₗ[R] P)

/-- Auxiliary function to constructing a linear map `M ⊗ N → P` given a bilinear map `M → N → P`
with the property that its composition with the canonical bilinear map `M → N → M ⊗ N` is
the given bilinear map `M → N → P`. -/
def lift_aux : (M ⊗[R] N) →+ P :=
(add_con_gen (tensor_product.eqv R M N)).lift (free_add_monoid.lift $ λ p : M × N, f p.1 p.2) $
add_con.add_con_gen_le $ λ x y hxy, match x, y, hxy with
| _, _, (eqv.of_zero_left n)       := (add_con.ker_rel _).2 $
    by simp_rw [add_monoid_hom.map_zero, free_add_monoid.lift_eval_of, f.map_zero₂]
| _, _, (eqv.of_zero_right m)      := (add_con.ker_rel _).2 $
    by simp_rw [add_monoid_hom.map_zero, free_add_monoid.lift_eval_of, (f m).map_zero]
| _, _, (eqv.of_add_left m₁ m₂ n)  := (add_con.ker_rel _).2 $
    by simp_rw [add_monoid_hom.map_add, free_add_monoid.lift_eval_of, f.map_add₂]
| _, _, (eqv.of_add_right m n₁ n₂) := (add_con.ker_rel _).2 $
    by simp_rw [add_monoid_hom.map_add, free_add_monoid.lift_eval_of, (f m).map_add]
| _, _, (eqv.of_smul r m n)        := (add_con.ker_rel _).2 $
    by rw [free_add_monoid.lift_eval_of, free_add_monoid.lift_eval_of,
           is_symmetric_smul.op_smul_eq_smul, f.map_smul₂, (f m).map_smul]
| _, _, (eqv.add_comm x y)         := (add_con.ker_rel _).2 $
    by simp_rw [add_monoid_hom.map_add, add_comm]
end

lemma lift_aux_tmul (m n) : lift_aux f (m ⊗ₜ n) = f m n :=
zero_add _

variable {f}

@[simp] lemma lift_aux.smul (r : R) (x) : lift_aux f (r • x) = r • lift_aux f x :=
tensor_product.induction_on x (smul_zero _).symm
  (λ p q, by rw [lift_aux_tmul,smul_tmul', lift_aux_tmul, f.map_smul₂] )
  (λ p q ih1 ih2, by rw [smul_add, (lift_aux f).map_add, ih1, ih2, (lift_aux f).map_add, smul_add])

variable (f)
/-- Constructing a linear map `M ⊗ N → P` given a bilinear map `M → N → P` with the property that
its composition with the canonical bilinear map `M → N → M ⊗ N` is
the given bilinear map `M → N → P`. -/
def lift : M ⊗ N →ₗ[R] P :=
{ map_smul' := lift_aux.smul,
  .. lift_aux f }
variable {f}

@[simp] lemma lift.tmul (x y) : lift f (x ⊗ₜ y) = f x y :=
zero_add _

@[simp] lemma lift.tmul' (x y) : (lift f).1 (x ⊗ₜ y) = f x y :=
lift.tmul _ _

theorem ext' {g h : (M ⊗[R] N) →ₗ[R] P}
  (H : ∀ x y, g (x ⊗ₜ y) = h (x ⊗ₜ y)) : g = h :=
linear_map.ext $ λ z, tensor_product.induction_on z (by simp_rw linear_map.map_zero) H $
λ x y ihx ihy, by rw [g.map_add, h.map_add, ihx, ihy]

theorem lift.unique {g : (M ⊗[R] N) →ₗ[R] P} (H : ∀ x y, g (x ⊗ₜ y) = f x y) :
  g = lift f :=
ext' $ λ m n, by rw [H, lift.tmul]

example : has_scalar Rᵒᵖ (M ⊗[R] N) := tensor_product.left_has_scalar

theorem lift_mk : lift (mk R M N) = linear_map.id :=
eq.symm $ lift.unique $ λ x y, rfl

theorem lift_compr₂ (g : P →ₗ[R] Q) : lift (f.compr₂ g) = g.comp (lift f) :=
eq.symm $ lift.unique $ λ x y, by simp

theorem lift_mk_compr₂
  (f : M ⊗ N →ₗ[R] P) : lift ((mk R M N).compr₂ f) = f :=
by { rw [lift_compr₂ f, lift_mk, linear_map.comp_id], repeat { apply_instance } }

/--
This used to be an `@[ext]` lemma, but it fails very slowly when the `ext` tactic tries to apply
it in some cases, notably when one wants to show equality of two linear maps. The `@[ext]`
attribute is now added locally where it is needed. Using this as the `@[ext]` lemma instead of
`tensor_product.ext'` allows `ext` to apply lemmas specific to `M →ₗ _` and `N →ₗ _`.
See note [partially-applied ext lemmas]. -/
theorem ext {g h : M ⊗[R] N →ₗ[R] P}
  (H : (mk R M N).compr₂ g = (mk R M N).compr₂ h) : g = h :=
by rw [← lift_mk_compr₂ g, H, lift_mk_compr₂]

local attribute [ext] ext

example : M → N → (M → N → P) → P :=
λ m, flip $ λ f, f m

variables (R M N P)
/-- Linearly constructing a linear map `M ⊗ N → P` given a bilinear map `M → N → P`
with the property that its composition with the canonical bilinear map `M → N → M ⊗ N` is
the given bilinear map `M → N → P`. -/
def uncurry : (M →ₗ[R] N →ₗ[R] P) →ₗ[R] M ⊗[R] N →ₗ[R] P :=
linear_map.flip $ lift $ (linear_map.lflip _ _ _ _).comp (linear_map.flip linear_map.id)
variables {R M N P}

@[simp] theorem uncurry_apply (f : M →ₗ[R] N →ₗ[R] P) (m : M) (n : N) :
  uncurry R M N P f (m ⊗ₜ n) = f m n :=
by rw [uncurry, linear_map.flip_apply, lift.tmul]; refl

variables (R M N P)
variables [module Rᵒᵖ N] [is_symmetric_smul R N]
/-- A linear equivalence constructing a linear map `M ⊗ N → P` given a bilinear map `M → N → P`
with the property that its composition with the canonical bilinear map `M → N → M ⊗ N` is
the given bilinear map `M → N → P`. -/
def lift.equiv :
  (M →ₗ[R] N →ₗ[R] P) ≃ₗ[R] (M ⊗ N →ₗ[R] P) :=
{ inv_fun := λ f, (mk R M N).compr₂ f,
  left_inv := λ f, linear_map.ext₂ $ λ m n, lift.tmul _ _,
  right_inv := λ f, ext' $ λ m n, lift.tmul _ _,
  .. uncurry R M N P }

@[simp] lemma lift.equiv_apply (f : M →ₗ[R] N →ₗ[R] P) (m : M) (n : N) :
  lift.equiv R M N P f (m ⊗ₜ n) = f m n :=
uncurry_apply f m n

@[simp] lemma lift.equiv_symm_apply (f : M ⊗[R] N →ₗ[R] P) (m : M) (n : N) :
  (lift.equiv R M N P).symm f m n = f (m ⊗ₜ n) :=
rfl

/-- Given a linear map `M ⊗ N → P`, compose it with the canonical bilinear map `M → N → M ⊗ N` to
form a bilinear map `M → N → P`. -/
def lcurry : (M ⊗[R] N →ₗ[R] P) →ₗ[R] M →ₗ[R] N →ₗ[R] P :=
(lift.equiv R M N P).symm
variables {R M N P}

@[simp] theorem lcurry_apply (f : M ⊗[R] N →ₗ[R] P) (m : M) (n : N) :
  lcurry R M N P f m n = f (m ⊗ₜ n) := rfl

/-- Given a linear map `M ⊗ N → P`, compose it with the canonical bilinear map `M → N → M ⊗ N` to
form a bilinear map `M → N → P`. -/
def curry (f : M ⊗ N →ₗ[R] P) : M →ₗ[R] N →ₗ[R] P := lcurry R M N P f

@[simp] theorem curry_apply (f : M ⊗ N →ₗ[R] P) (m : M) (n : N) :
  curry f m n = f (m ⊗ₜ n) := rfl

variables {S : Type*} [add_comm_monoid S] [module R S]

lemma curry_injective : function.injective (curry : (M ⊗[R] N →ₗ[R] P) → (M →ₗ[R] N →ₗ[R] P)) :=
λ g h H, ext H

theorem ext_threefold {g h : (M ⊗[R] N) ⊗[R] P →ₗ[R] Q}
  (H : ∀ x y z, g ((x ⊗ₜ y) ⊗ₜ z) = h ((x ⊗ₜ y) ⊗ₜ z)) : g = h :=
begin
  ext x y z,
  exact H x y z
end

-- We'll need this one for checking the pentagon identity!
theorem ext_fourfold {g h : ((M ⊗[R] N) ⊗[R] P) ⊗[R] Q →ₗ[R] S}
  (H : ∀ w x y z, g (((w ⊗ₜ x) ⊗ₜ y) ⊗ₜ z) = h (((w ⊗ₜ x) ⊗ₜ y) ⊗ₜ z)) : g = h :=
begin
  ext w x y z,
  exact H w x y z,
end

end UMP

variables {M N}
section
variables (R M)

/--
The base ring is a left identity for the tensor product of modules, up to linear equivalence.
-/
protected def lid : R ⊗ M ≃ₗ[R] M :=
linear_equiv.of_linear (lift $ linear_map.lsmul R M) (mk R R M 1)
  (linear_map.ext $ λ _, by simp)
  (ext' $ λ r m, by simp; rw [← tmul_smul, ← smul_tmul, smul_eq_mul, mul_one])
end

@[simp] theorem lid_tmul (m : M) (r : R) :
  ((tensor_product.lid R M) : (R ⊗ M → M)) (r ⊗ₜ m) = r • m :=
begin
  dsimp [tensor_product.lid],
  simp,
end

@[simp] lemma lid_symm_apply (m : M) :
  (tensor_product.lid R M).symm m = 1 ⊗ₜ m := rfl

section comm
variables (R M N)
variables [module Rᵒᵖ N] [is_symmetric_smul R N]

/--
The tensor product of modules is commutative, up to linear equivalence.
-/
protected def comm : M ⊗ N ≃ₗ[R] N ⊗ M :=
linear_equiv.of_linear (lift (mk R N M).flip) (lift (mk R M N).flip)
  (ext' $ λ m n, rfl)
  (ext' $ λ m n, rfl)

@[simp] theorem comm_tmul (m : M) (n : N) :
  (tensor_product.comm R M N) (m ⊗ₜ n) = n ⊗ₜ m := rfl

@[simp] theorem comm_symm_tmul (m : M) (n : N) :
  (tensor_product.comm R M N).symm (n ⊗ₜ m) = m ⊗ₜ n := rfl

end comm

section rid
variables (R M)

/--
The base ring is a right identity for the tensor product of modules, up to linear equivalence.
-/
protected def rid : M ⊗[R] R ≃ₗ[R] M :=
linear_equiv.trans (tensor_product.comm R M R) (tensor_product.lid R M)
end rid

@[simp] theorem rid_tmul (m : M) (r : R) :
  (tensor_product.rid R M) (m ⊗ₜ r) = r • m :=
begin
  dsimp [tensor_product.rid, tensor_product.comm, tensor_product.lid],
  simp,
end

@[simp] lemma rid_symm_apply (m : M) :
  (tensor_product.rid R M).symm m = m ⊗ₜ 1 := rfl

open linear_map

section assoc
variables [module Rᵒᵖ N] [is_symmetric_smul R N]
variables [module Rᵒᵖ P] [is_symmetric_smul R P]

variables (R M N P)
/-- The associator for tensor product of R-modules, as a linear equivalence. -/
protected def assoc : (M ⊗[R] N) ⊗[R] P ≃ₗ[R] M ⊗[R] (N ⊗[R] P) :=
begin
  refine linear_equiv.of_linear
    (lift $ lift $ comp (lcurry R _ _ _) $ mk _ _ _)
    (lift $ comp (uncurry R _ _ _) $ curry $ mk _ _ _)
    (ext $ linear_map.ext $ λ m, ext' $ λ n p, _)
    (ext $ flip_inj $ linear_map.ext $ λ p, ext' $ λ m n, _);
  repeat { rw lift.tmul <|> rw compr₂_apply <|> rw comp_apply <|>
    rw mk_apply <|> rw flip_apply <|> rw lcurry_apply <|>
    rw uncurry_apply <|> rw curry_apply <|> rw id_apply }
end
variables {R M N P}

@[simp] theorem assoc_tmul (m : M) (n : N) (p : P) :
  (tensor_product.assoc R M N P) ((m ⊗ₜ n) ⊗ₜ p) = m ⊗ₜ (n ⊗ₜ p) := rfl

@[simp] theorem assoc_symm_tmul (m : M) (n : N) (p : P) :
  (tensor_product.assoc R M N P).symm (m ⊗ₜ (n ⊗ₜ p)) = (m ⊗ₜ n) ⊗ₜ p := rfl

end assoc

section map

variables [module Rᵒᵖ P] [is_symmetric_smul R P]

/-- The tensor product of a pair of linear maps between modules. -/
def map (f : M →ₗ[R] P) (g : N →ₗ[R] Q) : M ⊗ N →ₗ[R] P ⊗ Q :=
lift $ comp (compl₂ (mk _ _ _) g) f

@[simp] theorem map_tmul (f : M →ₗ[R] P) (g : N →ₗ[R] Q) (m : M) (n : N) :
  map f g (m ⊗ₜ n) = f m ⊗ₜ g n :=
rfl

lemma map_range_eq_span_tmul (f : M →ₗ[R] P) (g : N →ₗ[R] Q) :
  (map f g).range = submodule.span R { t | ∃ m n, (f m) ⊗ₜ (g n) = t } :=
begin
  simp only [← submodule.map_top, ← span_tmul_eq_top, submodule.map_span, set.mem_image,
    set.mem_set_of_eq],
  congr, ext t,
  split,
  { rintros ⟨_, ⟨⟨m, n, rfl⟩, rfl⟩⟩, use [m, n], simp only [map_tmul], },
  { rintros ⟨m, n, rfl⟩, use [m ⊗ₜ n, m, n], simp only [map_tmul], },
end

/-- Given submodules `p ⊆ P` and `q ⊆ Q`, this is the natural map: `p ⊗ q → P ⊗ Q`. -/
@[simp] def map_incl (p : submodule R P) [module Rᵒᵖ p] [is_symmetric_smul R p]
  (q : submodule R Q) : p ⊗[R] q →ₗ[R] P ⊗[R] Q :=
map p.subtype q.subtype

section map_comp
variables {P' Q' : Type*}
variables [add_comm_monoid P'] [module R P'] [module Rᵒᵖ P'] [is_symmetric_smul R P']
variables [add_comm_monoid Q'] [module R Q']

lemma map_comp (f₂ : P →ₗ[R] P') (f₁ : M →ₗ[R] P) (g₂ : Q →ₗ[R] Q') (g₁ : N →ₗ[R] Q) :
  map (f₂.comp f₁) (g₂.comp g₁) = (map f₂ g₂).comp (map f₁ g₁) :=
ext' $ λ _ _, by simp only [linear_map.comp_apply, map_tmul]

lemma lift_comp_map (i : P →ₗ[R] Q →ₗ[R] Q') (f : M →ₗ[R] P) (g : N →ₗ[R] Q) :
  (lift i).comp (map f g) = lift ((i.comp f).compl₂ g) :=
ext' $ λ _ _, by simp only [lift.tmul, map_tmul, linear_map.compl₂_apply, linear_map.comp_apply]

local attribute [ext] ext

@[simp] lemma map_id : map (id : M →ₗ[R] M) (id : N →ₗ[R] N) = id :=
by { ext, simp only [mk_apply, id_coe, compr₂_apply, id.def, map_tmul], refl }

@[simp] lemma map_one : map (1 : M →ₗ[R] M) (1 : N →ₗ[R] N) = 1 := map_id

lemma map_mul (f₁ f₂ : M →ₗ[R] M) (g₁ g₂ : N →ₗ[R] N) :
  map (f₁ * f₂) (g₁ * g₂) = (map f₁ g₁) * (map f₂ g₂) :=
map_comp f₁ f₂ g₁ g₂

@[simp] lemma map_pow (f : M →ₗ[R] M) (g : N →ₗ[R] N) (n : ℕ) :
  (map f g)^n = map (f^n) (g^n) :=
begin
  induction n with n ih,
  { simp only [pow_zero, map_one], },
  { simp only [pow_succ', ih, map_mul], },
end

end map_comp

end map

section congr

variables [module Rᵒᵖ P] [is_symmetric_smul R P]
/-- If `M` and `P` are linearly equivalent and `N` and `Q` are linearly equivalent
then `M ⊗ N` and `P ⊗ Q` are linearly equivalent. -/
def congr (f : M ≃ₗ[R] P) (g : N ≃ₗ[R] Q) : M ⊗ N ≃ₗ[R] P ⊗ Q :=
linear_equiv.of_linear (map f g) (map f.symm g.symm)
  (ext' $ λ m n, by simp; simp only [linear_equiv.apply_symm_apply])
  (ext' $ λ m n, by simp; simp only [linear_equiv.symm_apply_apply])

@[simp] theorem congr_tmul (f : M ≃ₗ[R] P) (g : N ≃ₗ[R] Q) (m : M) (n : N) :
  congr f g (m ⊗ₜ n) = f m ⊗ₜ g n :=
rfl

@[simp] theorem congr_symm_tmul (f : M ≃ₗ[R] P) (g : N ≃ₗ[R] Q) (p : P) (q : Q) :
  (congr f g).symm (p ⊗ₜ q) = f.symm p ⊗ₜ g.symm q :=
rfl

end congr

variables (R M N P Q)
variables [module Rᵒᵖ N] [is_symmetric_smul R N]
variables [module Rᵒᵖ P] [is_symmetric_smul R P]

/-- A tensor product analogue of `mul_left_comm`. -/
def left_comm : M ⊗[R] (N ⊗[R] P) ≃ₗ[R] N ⊗[R] (M ⊗[R] P) :=
let e₁ := (tensor_product.assoc R M N P).symm,
    e₂ := congr (tensor_product.comm R M N) (1 : P ≃ₗ[R] P),
    e₃ := (tensor_product.assoc R N M P) in
e₁ ≪≫ₗ (e₂ ≪≫ₗ e₃)

variables {M N P Q}

@[simp] lemma left_comm_tmul (m : M) (n : N) (p : P) :
  left_comm R M N P (m ⊗ₜ (n ⊗ₜ p)) = n ⊗ₜ (m ⊗ₜ p) :=
rfl

@[simp] lemma left_comm_symm_tmul (m : M) (n : N) (p : P) :
  (left_comm R M N P).symm (n ⊗ₜ (m ⊗ₜ p)) = m ⊗ₜ (n ⊗ₜ p) :=
rfl

variables (M N P Q)
variables [module Rᵒᵖ Q] [is_symmetric_smul R Q]

/-- This special case is worth defining explicitly since it is useful for defining multiplication
on tensor products of modules carrying multiplications (e.g., associative rings, Lie rings, ...).
E.g., suppose `M = P` and `N = Q` and that `M` and `N` carry bilinear multiplications:
`M ⊗ M → M` and `N ⊗ N → N`. Using `map`, we can define `(M ⊗ M) ⊗ (N ⊗ N) → M ⊗ N` which, when
combined with this definition, yields a bilinear multiplication on `M ⊗ N`:
`(M ⊗ N) ⊗ (M ⊗ N) → M ⊗ N`. In particular we could use this to define the multiplication in
the `tensor_product.semiring` instance (currently defined "by hand" using `tensor_product.mul`).
See also `mul_mul_mul_comm`. -/
def tensor_tensor_tensor_comm : (M ⊗[R] N) ⊗[R] (P ⊗[R] Q) ≃ₗ[R] (M ⊗[R] P) ⊗[R] (N ⊗[R] Q) :=
let e₁ := tensor_product.assoc R M N (P ⊗[R] Q),
    e₂ := congr (1 : M ≃ₗ[R] M) (left_comm R N P Q),
    e₃ := (tensor_product.assoc R M P (N ⊗[R] Q)).symm in
e₁ ≪≫ₗ (e₂ ≪≫ₗ e₃)

variables {M N P Q}

@[simp] lemma tensor_tensor_tensor_comm_tmul (m : M) (n : N) (p : P) (q : Q) :
  tensor_tensor_tensor_comm R M N P Q ((m ⊗ₜ n) ⊗ₜ (p ⊗ₜ q)) = (m ⊗ₜ p) ⊗ₜ (n ⊗ₜ q) :=
rfl

@[simp] lemma tensor_tensor_tensor_comm_symm_tmul (m : M) (n : N) (p : P) (q : Q) :
  (tensor_tensor_tensor_comm R M N P Q).symm ((m ⊗ₜ p) ⊗ₜ (n ⊗ₜ q)) = (m ⊗ₜ n) ⊗ₜ (p ⊗ₜ q) :=
rfl

end comm_semiring

end tensor_product

open_locale tensor_product

namespace linear_map

variables {R : Type*} [comm_semiring R]
variables {R' : Type*} [monoid R']
variables {R'' : Type*} [comm_semiring R''] --?
variables (M : Type*) [add_comm_monoid M] [module R M] [module Rᵒᵖ M] [is_symmetric_smul R M]
variables {N : Type*} [add_comm_monoid N] [module R N] [module Rᵒᵖ N] [is_symmetric_smul R N]
variables [distrib_mul_action R' M]
variables {P : Type*} [add_comm_monoid P] [module R P] [module Rᵒᵖ P] [is_symmetric_smul R P]
variables {Q : Type*} [add_comm_monoid Q] [module R Q] [module Rᵒᵖ Q] [is_symmetric_smul R Q]
variables {S : Type*} [add_comm_monoid S] [module R S] [module Rᵒᵖ S] [is_symmetric_smul R S]


variables (M)
/-- `ltensor M f : M ⊗ N →ₗ M ⊗ P` is the natural linear map induced by `f : N →ₗ P`. -/
def ltensor (f : N →ₗ[R] P) : M ⊗ N →ₗ[R] M ⊗ P :=
tensor_product.map id f

/-- `rtensor f M : N₁ ⊗ M →ₗ N₂ ⊗ M` is the natural linear map induced by `f : N₁ →ₗ N₂`. -/
def rtensor [is_symmetric_smul R N] (f : N →ₗ[R] P) : N ⊗ M →ₗ[R] P ⊗ M :=
tensor_product.map f id

variables (g : P →ₗ[R] Q) (f : N →ₗ[R] P)

@[simp] lemma ltensor_tmul (m : M) (n : N) : f.ltensor M (m ⊗ₜ n) = m ⊗ₜ (f n) := rfl

@[simp] lemma rtensor_tmul (m : M) (n : N) : f.rtensor M (n ⊗ₜ m) = (f n) ⊗ₜ m := rfl

open tensor_product

local attribute [ext] tensor_product.ext

/-- `ltensor_hom M` is the natural linear map that sends a linear map `f : N →ₗ P` to `M ⊗ f`. -/
def ltensor_hom : (N →ₗ[R] P) →ₗ[R] (M ⊗[R] N →ₗ[R] M ⊗[R] P) :=
{ to_fun := ltensor M,
  map_add' := λ f g, by {
    ext x y, simp only [compr₂_apply, mk_apply, add_apply, ltensor_tmul, tmul_add] },
  map_smul' := λ r f, by {
    dsimp, ext x y, simp only [compr₂_apply, mk_apply, tmul_smul, smul_apply, ltensor_tmul] } }

/-- `rtensor_hom M` is the natural linear map that sends a linear map `f : N →ₗ P` to `M ⊗ f`. -/
def rtensor_hom : (N →ₗ[R] P) →ₗ[R] (N ⊗[R] M →ₗ[R] P ⊗[R] M) :=
{ to_fun := λ f, f.rtensor M,
  map_add' := λ f g, by {
    ext x y, simp only [compr₂_apply, mk_apply, add_apply, rtensor_tmul, add_tmul] },
  map_smul' := λ r f, by {
    dsimp, ext x y, simp only [compr₂_apply, mk_apply, smul_tmul, tmul_smul, smul_apply,
    rtensor_tmul] } }

@[simp] lemma coe_ltensor_hom :
  (ltensor_hom M : (N →ₗ[R] P) → (M ⊗[R] N →ₗ[R] M ⊗[R] P)) = ltensor M := rfl

@[simp] lemma coe_rtensor_hom :
  (rtensor_hom M : (N →ₗ[R] P) → (N ⊗[R] M →ₗ[R] P ⊗[R] M)) = rtensor M := rfl

@[simp] lemma ltensor_add (f g : N →ₗ[R] P) : (f + g).ltensor M = f.ltensor M + g.ltensor M :=
(ltensor_hom M).map_add f g

@[simp] lemma rtensor_add (f g : N →ₗ[R] P) : (f + g).rtensor M = f.rtensor M + g.rtensor M :=
(rtensor_hom M).map_add f g

@[simp] lemma ltensor_zero : ltensor M (0 : N →ₗ[R] P) = 0 :=
(ltensor_hom M).map_zero

@[simp] lemma rtensor_zero : rtensor M (0 : N →ₗ[R] P) = 0 :=
(rtensor_hom M).map_zero

@[simp] lemma ltensor_smul (r : R) (f : N →ₗ[R] P) : (r • f).ltensor M = r • (f.ltensor M) :=
(ltensor_hom M).map_smul r f

@[simp] lemma rtensor_smul (r : R) (f : N →ₗ[R] P) : (r • f).rtensor M = r • (f.rtensor M) :=
(rtensor_hom M).map_smul r f

lemma ltensor_comp : (g.comp f).ltensor M = (g.ltensor M).comp (f.ltensor M) :=
by { ext m n, simp only [compr₂_apply, mk_apply, comp_apply, ltensor_tmul] }

lemma rtensor_comp : (g.comp f).rtensor M = (g.rtensor M).comp (f.rtensor M) :=
by { ext m n, simp only [compr₂_apply, mk_apply, comp_apply, rtensor_tmul] }

lemma ltensor_mul (f g : module.End R N) : (f * g).ltensor M = (f.ltensor M) * (g.ltensor M) :=
ltensor_comp M f g

lemma rtensor_mul (f g : module.End R N) : (f * g).rtensor M = (f.rtensor M) * (g.rtensor M) :=
rtensor_comp M f g

variables (N)

@[simp] lemma ltensor_id : (id : N →ₗ[R] N).ltensor M = id := map_id

@[simp] lemma rtensor_id : (id : N →ₗ[R] N).rtensor M = id := map_id

variables {N}

@[simp] lemma ltensor_comp_rtensor (f : M →ₗ[R] P) (g : N →ₗ[R] Q) :
  (g.ltensor P).comp (f.rtensor N) = map f g :=
by simp only [ltensor, rtensor, ← map_comp, id_comp, comp_id]

@[simp] lemma rtensor_comp_ltensor (f : M →ₗ[R] P) (g : N →ₗ[R] Q) :
  (f.rtensor Q).comp (g.ltensor M) = map f g :=
by simp only [ltensor, rtensor, ← map_comp, id_comp, comp_id]

@[simp] lemma map_comp_rtensor (f : M →ₗ[R] P) (g : N →ₗ[R] Q) (f' : S →ₗ[R] M) :
  (map f g).comp (f'.rtensor _) = map (f.comp f') g :=
by simp only [ltensor, rtensor, ← map_comp, id_comp, comp_id]

@[simp] lemma map_comp_ltensor (f : M →ₗ[R] P) (g : N →ₗ[R] Q) (g' : S →ₗ[R] N) :
  (map f g).comp (g'.ltensor _) = map f (g.comp g') :=
by simp only [ltensor, rtensor, ← map_comp, id_comp, comp_id]

@[simp] lemma rtensor_comp_map (f' : P →ₗ[R] S) (f : M →ₗ[R] P) (g : N →ₗ[R] Q) :
  (f'.rtensor _).comp (map f g) = map (f'.comp f) g :=
by simp only [ltensor, rtensor, ← map_comp, id_comp, comp_id]

@[simp] lemma ltensor_comp_map (g' : Q →ₗ[R] S) (f : M →ₗ[R] P) (g : N →ₗ[R] Q) :
  (g'.ltensor _).comp (map f g) = map f (g'.comp g) :=
by simp only [ltensor, rtensor, ← map_comp, id_comp, comp_id]

variables {M}

@[simp] lemma rtensor_pow (f : M →ₗ[R] M) (n : ℕ) : (f.rtensor N)^n = (f^n).rtensor N :=
by { have h := map_pow f (id : N →ₗ[R] N) n, rwa id_pow at h, }

@[simp] lemma ltensor_pow (f : N →ₗ[R] N) (n : ℕ) : (f.ltensor M)^n = (f^n).ltensor M :=
by { have h := map_pow (id : M →ₗ[R] M) f n, rwa id_pow at h, }

end linear_map

section add_comm_group

variables {R : Type*} [semiring R]
variables {M : Type*} {N : Type*} {P : Type*} {Q : Type*} {S : Type*}

variables [add_comm_group M] [add_comm_group N] [add_comm_group P] [add_comm_group Q]
  [add_comm_group S]
variables [module R M] [module Rᵒᵖ M] [is_symmetric_smul R M]
variables [module R N] [module R P] [module R Q] [module R S]

namespace tensor_product

open_locale tensor_product
open linear_map

variables (R)

/-- Auxiliary function to defining negation multiplication on tensor product. -/
def neg.aux : free_add_monoid (M × N) →+ M ⊗[R] N :=
free_add_monoid.lift $ λ p : M × N, (-p.1) ⊗ₜ p.2

variables {R}

theorem neg.aux_of (m : M) (n : N) :
  neg.aux R (free_add_monoid.of (m, n)) = (-m) ⊗ₜ[R] n :=
rfl

instance : has_neg (M ⊗[R] N) :=
{ neg := (add_con_gen (tensor_product.eqv R M N)).lift (neg.aux R) $ add_con.add_con_gen_le $
    λ x y hxy, match x, y, hxy with
    | _, _, (eqv.of_zero_left n)       := (add_con.ker_rel _).2 $
        by simp_rw [add_monoid_hom.map_zero, neg.aux_of, neg_zero, zero_tmul]
    | _, _, (eqv.of_zero_right m)      := (add_con.ker_rel _).2 $
        by simp_rw [add_monoid_hom.map_zero, neg.aux_of, tmul_zero]
    | _, _, (eqv.of_add_left m₁ m₂ n)  := (add_con.ker_rel _).2 $
        by simp_rw [add_monoid_hom.map_add, neg.aux_of, neg_add, add_tmul]
    | _, _, (eqv.of_add_right m n₁ n₂) := (add_con.ker_rel _).2 $
        by simp_rw [add_monoid_hom.map_add, neg.aux_of, tmul_add]
    | _, _, (eqv.of_smul s m n)        := (add_con.ker_rel _).2 $
        by rw [neg.aux_of, neg.aux_of, ←smul_neg, rsmul_tmul]
    | _, _, (eqv.add_comm x y)         := (add_con.ker_rel _).2 $
        by simp_rw [add_monoid_hom.map_add, add_comm]
    end }

protected theorem add_left_neg (x : M ⊗[R] N) : -x + x = 0 :=
tensor_product.induction_on x
  (by { rw [add_zero], apply (@neg.aux R _ M N _ _ _ _ _ _).map_zero })
  (λ x y, by { convert (add_tmul (-x) x y).symm, rw [add_left_neg, zero_tmul], })
  (λ x y hx hy, by {
    unfold has_neg.neg sub_neg_monoid.neg,
    rw add_monoid_hom.map_add,
    ac_change (-x + x) + (-y + y) = 0,
    rw [hx, hy, add_zero], })

instance : add_comm_group (M ⊗[R] N) :=
{ neg := has_neg.neg,
  sub := _,
  sub_eq_add_neg := λ _ _, rfl,
  add_left_neg := λ x, by exact tensor_product.add_left_neg x,
  zsmul := λ n v, n • v,
  zsmul_zero' := by simp [tensor_product.zero_smul],
  zsmul_succ' := by simp [nat.succ_eq_one_add, tensor_product.one_smul, tensor_product.add_smul],
  zsmul_neg' := λ n x, begin
    change (- n.succ : ℤ) • x = - (((n : ℤ) + 1) • x),
    rw [← zero_add (-↑(n.succ) • x), ← tensor_product.add_left_neg (↑(n.succ) • x), add_assoc,
      ← add_smul, ← sub_eq_add_neg, sub_self, zero_smul, add_zero],
    refl,
  end,
  .. tensor_product.add_comm_monoid }

lemma neg_tmul (m : M) (n : N) : (-m) ⊗ₜ n = -(m ⊗ₜ[R] n) := rfl

lemma tmul_neg (m : M) (n : N) : m ⊗ₜ (-n) = -(m ⊗ₜ[R] n) :=
by { apply eq_neg_of_add_eq_zero, rw [←tmul_add], simp }

lemma tmul_sub (m : M) (n₁ n₂ : N) : m ⊗ₜ (n₁ - n₂) = (m ⊗ₜ[R] n₁) - (m ⊗ₜ[R] n₂) :=
by { apply eq_sub_of_add_eq, rw [←tmul_add], simp }

lemma sub_tmul (m₁ m₂ : M) (n : N) : (m₁ - m₂) ⊗ₜ n = (m₁ ⊗ₜ[R] n) - (m₂ ⊗ₜ[R] n) :=
by { apply eq_sub_of_add_eq, rw [←add_tmul], simp }

open opposite
/--
While the tensor product will automatically inherit a ℤ-module structure from
`add_comm_group.int_module`, that structure won't be compatible with lemmas like `tmul_smul` unless
we use a `ℤ-module` instance provided by `tensor_product.left_module`.
When `R` is a `ring` we get the required `tensor_product.compatible_smul` instance through
`is_scalar_tower`, but when it is only a `semiring` we need to build it from scratch.
The instance diamond in `compatible_smul` doesn't matter because it's in `Prop`.
-/
instance compatible_smul.int [module ℤ M] [module ℤᵒᵖ M] [is_symmetric_smul ℤ M]
  [module ℤ N] [module ℤᵒᵖ N] [is_symmetric_smul ℤ N]:
  compatible_smul R ℤ M N :=
⟨λ r m n, int.induction_on r
  (by simp)
  (λ r ih, by rw [op_add, add_smul, add_tmul, ih, op_one, one_smul, ←tmul_add, add_self_zsmul])
  (λ r ih, by rw [op_sub, sub_smul, sub_tmul, op_one, one_smul, ih, ←tmul_sub,
                  sub_zsmul, one_zsmul, sub_eq_add_neg])⟩


--TODO: decide how to deal with `has_scalar (units S)ᵒᵖ M`
/-instance compatible_smul.unit {S} [monoid S] [distrib_mul_action Sᵒᵖ M] [distrib_mul_action S N]
  [compatible_smul R S M N] :
  compatible_smul R (units S) M N :=
⟨λ s m n, (compatible_smul.smul_tmul (s : S) m n : _)⟩-/

end tensor_product

namespace linear_map

variables {R' : Type*} [comm_semiring R']
variables [module R' M] [module R'ᵒᵖ M] [is_symmetric_smul R' M]
variables [module R' N] [module R' P] [module R' Q] [module R' S]
variables [module R'ᵒᵖ N] [is_symmetric_smul R' N]
variables [module R'ᵒᵖ P] [is_symmetric_smul R' P]
variables [module R'ᵒᵖ Q] [is_symmetric_smul R' Q]
variables [module R'ᵒᵖ S] [is_symmetric_smul R' S]

@[simp] lemma ltensor_sub (f g : N →ₗ[R'] P) : (f - g).ltensor M = f.ltensor M - g.ltensor M :=
by simp only [← coe_ltensor_hom, map_sub]

@[simp] lemma rtensor_sub (f g : N →ₗ[R'] P) : (f - g).rtensor M = f.rtensor M - g.rtensor M :=
by simp only [← coe_rtensor_hom, map_sub]

@[simp] lemma ltensor_neg (f : N →ₗ[R'] P) : (-f).ltensor M = -(f.ltensor M) :=
by simp only [← coe_ltensor_hom, map_neg]

@[simp] lemma rtensor_neg (f : N →ₗ[R'] P) : (-f).rtensor M = -(f.rtensor M) :=
by simp only [← coe_rtensor_hom, map_neg]

end linear_map

end add_comm_group
