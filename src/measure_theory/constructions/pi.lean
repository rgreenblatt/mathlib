/-
Copyright (c) 2020 Floris van Doorn. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Floris van Doorn
-/
import measure_theory.constructions.prod

/-!
# Product measures

In this file we define and prove properties about finite products of measures
(and at some point, countable products of measures).

## Main definition

* `measure_theory.measure.pi`: The product of finitely many σ-finite measures.
  Given `μ : Π i : ι, measure (α i)` for `[fintype ι]` it has type `measure (Π i : ι, α i)`.

To apply Fubini along some subset of the variables, use
`measure_theory.measure.map_pi_equiv_pi_subtype_prod` to reduce to the situation of a product
of two measures: this lemma states that the bijection `equiv.pi_equiv_pi_subtype_prod p α`
between `(Π i : ι, α i)` and `(Π i : {i // p i}, α i) × (Π i : {i // ¬ p i}, α i)` maps a product
measure to a direct product of product measures, to which one can apply the usual Fubini for
direct product of measures.

## Implementation Notes

We define `measure_theory.outer_measure.pi`, the product of finitely many outer measures, as the
maximal outer measure `n` with the property that `n (pi univ s) ≤ ∏ i, m i (s i)`,
where `pi univ s` is the product of the sets `{s i | i : ι}`.

We then show that this induces a product of measures, called `measure_theory.measure.pi`.
For a collection of σ-finite measures `μ` and a collection of measurable sets `s` we show that
`measure.pi μ (pi univ s) = ∏ i, m i (s i)`. To do this, we follow the following steps:
* We know that there is some ordering on `ι`, given by an element of `[encodable ι]`.
* Using this, we have an equivalence `measurable_equiv.pi_measurable_equiv_tprod` between
  `Π ι, α i` and an iterated product of `α i`, called `list.tprod α l` for some list `l`.
* On this iterated product we can easily define a product measure `measure_theory.measure.tprod`
  by iterating `measure_theory.measure.prod`
* Using the previous two steps we construct `measure_theory.measure.pi'` on `Π ι, α i` for encodable
  `ι`.
* We know that `measure_theory.measure.pi'` sends products of sets to products of measures, and
  since `measure_theory.measure.pi` is the maximal such measure (or at least, it comes from an outer
  measure which is the maximal such outer measure), we get the same rule for
  `measure_theory.measure.pi`.

## Tags

finitary product measure

-/

noncomputable theory
open function set measure_theory.outer_measure filter measurable_space encodable
open_locale classical big_operators topological_space ennreal

variables {ι ι' : Type*} {α : ι → Type*}

/-! We start with some measurability properties -/

/-- Boxes formed by π-systems form a π-system. -/
lemma is_pi_system.pi {C : Π i, set (set (α i))} (hC : ∀ i, is_pi_system (C i)) :
  is_pi_system (pi univ '' pi univ C) :=
begin
  rintro _ _ ⟨s₁, hs₁, rfl⟩ ⟨s₂, hs₂, rfl⟩ hst,
  rw [← pi_inter_distrib] at hst ⊢, rw [univ_pi_nonempty_iff] at hst,
  exact mem_image_of_mem _ (λ i _, hC i _ _ (hs₁ i (mem_univ i)) (hs₂ i (mem_univ i)) (hst i))
end

/-- Boxes form a π-system. -/
lemma is_pi_system_pi [Π i, measurable_space (α i)] :
  is_pi_system (pi univ '' pi univ (λ i, {s : set (α i) | measurable_set s})) :=
is_pi_system.pi (λ i, is_pi_system_measurable_set)

variables [fintype ι] [fintype ι']

/-- Boxes of countably spanning sets are countably spanning. -/
lemma is_countably_spanning.pi {C : Π i, set (set (α i))}
  (hC : ∀ i, is_countably_spanning (C i)) :
  is_countably_spanning (pi univ '' pi univ C) :=
begin
  choose s h1s h2s using hC,
  haveI := fintype.encodable ι,
  let e : ℕ → (ι → ℕ) := λ n, (decode (ι → ℕ) n).iget,
  refine ⟨λ n, pi univ (λ i, s i (e n i)), λ n, mem_image_of_mem _ (λ i _, h1s i _), _⟩,
  simp_rw [(surjective_decode_iget (ι → ℕ)).Union_comp (λ x, pi univ (λ i, s i (x i))),
      Union_univ_pi s, h2s, pi_univ]
end

/-- The product of generated σ-algebras is the one generated by boxes, if both generating sets
  are countably spanning. -/
lemma generate_from_pi_eq {C : Π i, set (set (α i))}
  (hC : ∀ i, is_countably_spanning (C i)) :
  @measurable_space.pi _ _ (λ i, generate_from (C i)) = generate_from (pi univ '' pi univ C) :=
begin
  haveI := fintype.encodable ι,
  apply le_antisymm,
  { refine supr_le _, intro i, rw [comap_generate_from],
    apply generate_from_le, rintro _ ⟨s, hs, rfl⟩, dsimp,
    choose t h1t h2t using hC,
    simp_rw [eval_preimage, ← h2t],
    rw [← @Union_const _ ℕ _ s],
    have : (pi univ (update (λ (i' : ι), Union (t i')) i (⋃ (i' : ℕ), s))) =
      (pi univ (λ k, ⋃ j : ℕ, @update ι (λ i', set (α i')) _ (λ i', t i' j) i s k)),
    { ext, simp_rw [mem_univ_pi], apply forall_congr, intro i',
      by_cases (i' = i), { subst h, simp }, { rw [← ne.def] at h, simp [h] }},
    rw [this, ← Union_univ_pi],
    apply measurable_set.Union,
    intro n, apply measurable_set_generate_from,
    apply mem_image_of_mem, intros j _, dsimp only,
    by_cases h: j = i, subst h, rwa [update_same], rw [update_noteq h], apply h1t },
  { apply generate_from_le, rintro _ ⟨s, hs, rfl⟩,
    rw [univ_pi_eq_Inter], apply measurable_set.Inter, intro i, apply measurable_pi_apply,
    exact measurable_set_generate_from (hs i (mem_univ i)) }
end

/-- If `C` and `D` generate the σ-algebras on `α` resp. `β`, then rectangles formed by `C` and `D`
  generate the σ-algebra on `α × β`. -/
lemma generate_from_eq_pi [h : Π i, measurable_space (α i)]
  {C : Π i, set (set (α i))} (hC : ∀ i, generate_from (C i) = h i)
  (h2C : ∀ i, is_countably_spanning (C i)) :
  generate_from (pi univ '' pi univ C) = measurable_space.pi :=
by rw [← funext hC, generate_from_pi_eq h2C]

/-- The product σ-algebra is generated from boxes, i.e. `s.prod t` for sets `s : set α` and
  `t : set β`. -/
lemma generate_from_pi [Π i, measurable_space (α i)] :
  generate_from (pi univ '' pi univ (λ i, { s : set (α i) | measurable_set s})) =
  measurable_space.pi :=
generate_from_eq_pi (λ i, generate_from_measurable_set) (λ i, is_countably_spanning_measurable_set)

namespace measure_theory

variables {m : Π i, outer_measure (α i)}

/-- An upper bound for the measure in a finite product space.
  It is defined to by taking the image of the set under all projections, and taking the product
  of the measures of these images.
  For measurable boxes it is equal to the correct measure. -/
@[simp] def pi_premeasure (m : Π i, outer_measure (α i)) (s : set (Π i, α i)) : ℝ≥0∞ :=
∏ i, m i (eval i '' s)

lemma pi_premeasure_pi {s : Π i, set (α i)} (hs : (pi univ s).nonempty) :
  pi_premeasure m (pi univ s) = ∏ i, m i (s i) :=
by simp [hs]

lemma pi_premeasure_pi' [nonempty ι] {s : Π i, set (α i)} :
  pi_premeasure m (pi univ s) = ∏ i, m i (s i) :=
begin
  cases (pi univ s).eq_empty_or_nonempty with h h,
  { rcases univ_pi_eq_empty_iff.mp h with ⟨i, hi⟩,
    have : ∃ i, m i (s i) = 0 := ⟨i, by simp [hi]⟩,
    simpa [h, finset.card_univ, zero_pow (fintype.card_pos_iff.mpr ‹_›),
      @eq_comm _ (0 : ℝ≥0∞), finset.prod_eq_zero_iff] },
  { simp [h] }
end

lemma pi_premeasure_pi_mono {s t : set (Π i, α i)} (h : s ⊆ t) :
  pi_premeasure m s ≤ pi_premeasure m t :=
finset.prod_le_prod' (λ i _, (m i).mono' (image_subset _ h))

lemma pi_premeasure_pi_eval [nonempty ι] {s : set (Π i, α i)} :
  pi_premeasure m (pi univ (λ i, eval i '' s)) = pi_premeasure m s :=
by simp [pi_premeasure_pi']

namespace outer_measure

/-- `outer_measure.pi m` is the finite product of the outer measures `{m i | i : ι}`.
  It is defined to be the maximal outer measure `n` with the property that
  `n (pi univ s) ≤ ∏ i, m i (s i)`, where `pi univ s` is the product of the sets
  `{s i | i : ι}`. -/
protected def pi (m : Π i, outer_measure (α i)) : outer_measure (Π i, α i) :=
bounded_by (pi_premeasure m)

lemma pi_pi_le (m : Π i, outer_measure (α i)) (s : Π i, set (α i)) :
  outer_measure.pi m (pi univ s) ≤ ∏ i, m i (s i) :=
by { cases (pi univ s).eq_empty_or_nonempty with h h, simp [h],
     exact (bounded_by_le _).trans_eq (pi_premeasure_pi h) }

lemma le_pi {m : Π i, outer_measure (α i)} {n : outer_measure (Π i, α i)} :
  n ≤ outer_measure.pi m ↔ ∀ (s : Π i, set (α i)), (pi univ s).nonempty →
    n (pi univ s) ≤ ∏ i, m i (s i) :=
begin
  rw [outer_measure.pi, le_bounded_by'], split,
  { intros h s hs, refine (h _ hs).trans_eq (pi_premeasure_pi hs) },
  { intros h s hs, refine le_trans (n.mono $ subset_pi_eval_image univ s) (h _ _),
    simp [univ_pi_nonempty_iff, hs] }
end

end outer_measure


namespace measure

variables [Π i, measurable_space (α i)] (μ : Π i, measure (α i))

section tprod

open list
variables {δ : Type*} {π : δ → Type*} [∀ x, measurable_space (π x)]

/-- A product of measures in `tprod α l`. -/
-- for some reason the equation compiler doesn't like this definition
protected def tprod (l : list δ) (μ : Π i, measure (π i)) : measure (tprod π l) :=
by { induction l with i l ih, exact dirac punit.star, exact (μ i).prod ih }

@[simp] lemma tprod_nil (μ : Π i, measure (π i)) : measure.tprod [] μ = dirac punit.star := rfl

@[simp] lemma tprod_cons (i : δ) (l : list δ) (μ : Π i, measure (π i)) :
  measure.tprod (i :: l) μ = (μ i).prod (measure.tprod l μ) := rfl

instance sigma_finite_tprod (l : list δ) (μ : Π i, measure (π i)) [∀ i, sigma_finite (μ i)] :
  sigma_finite (measure.tprod l μ) :=
begin
  induction l with i l ih,
  { rw [tprod_nil], apply_instance },
  { rw [tprod_cons], resetI, apply_instance }
end

lemma tprod_tprod (l : list δ) (μ : Π i, measure (π i)) [∀ i, sigma_finite (μ i)]
  (s : Π i, set (π i)) :
  measure.tprod l μ (set.tprod l s) = (l.map (λ i, (μ i) (s i))).prod :=
begin
  induction l with i l ih, { simp },
  rw [tprod_cons, set.tprod, prod_prod, map_cons, prod_cons, ih]
end

end tprod

section encodable

open list measurable_equiv
variables [encodable ι]

/-- The product measure on an encodable finite type, defined by mapping `measure.tprod` along the
  equivalence `measurable_equiv.pi_measurable_equiv_tprod`.
  The definition `measure_theory.measure.pi` should be used instead of this one. -/
def pi' : measure (Π i, α i) :=
measure.map (tprod.elim' mem_sorted_univ) (measure.tprod (sorted_univ ι) μ)

lemma pi'_pi [∀ i, sigma_finite (μ i)] (s : Π i, set (α i)) : pi' μ (pi univ s) = ∏ i, μ i (s i) :=
by rw [pi', ← measurable_equiv.pi_measurable_equiv_tprod_symm_apply, measurable_equiv.map_apply,
  measurable_equiv.pi_measurable_equiv_tprod_symm_apply, elim_preimage_pi, tprod_tprod _ μ,
  ← list.prod_to_finset, sorted_univ_to_finset]; exact sorted_univ_nodup ι

end encodable

lemma pi_caratheodory :
  measurable_space.pi ≤ (outer_measure.pi (λ i, (μ i).to_outer_measure)).caratheodory :=
begin
  refine supr_le _,
  intros i s hs,
  rw [measurable_space.comap] at hs,
  rcases hs with ⟨s, hs, rfl⟩,
  apply bounded_by_caratheodory,
  intro t,
  simp_rw [pi_premeasure],
  refine finset.prod_add_prod_le' (finset.mem_univ i) _ _ _,
  { simp [image_inter_preimage, image_diff_preimage, measure_inter_add_diff _ hs, le_refl] },
  { rintro j - hj, apply mono', apply image_subset, apply inter_subset_left },
  { rintro j - hj, apply mono', apply image_subset, apply diff_subset }
end

/-- `measure.pi μ` is the finite product of the measures `{μ i | i : ι}`.
  It is defined to be measure corresponding to `measure_theory.outer_measure.pi`. -/
@[irreducible] protected def pi : measure (Π i, α i) :=
to_measure (outer_measure.pi (λ i, (μ i).to_outer_measure)) (pi_caratheodory μ)

lemma pi_pi_aux [∀ i, sigma_finite (μ i)] (s : Π i, set (α i)) (hs : ∀ i, measurable_set (s i)) :
  measure.pi μ (pi univ s) = ∏ i, μ i (s i) :=
begin
  refine le_antisymm _ _,
  { rw [measure.pi, to_measure_apply _ _ (measurable_set.pi_fintype (λ i _, hs i))],
    apply outer_measure.pi_pi_le },
  { haveI : encodable ι := fintype.encodable ι,
    rw [← pi'_pi μ s],
    simp_rw [← pi'_pi μ s, measure.pi,
      to_measure_apply _ _ (measurable_set.pi_fintype (λ i _, hs i)), ← to_outer_measure_apply],
    suffices : (pi' μ).to_outer_measure ≤ outer_measure.pi (λ i, (μ i).to_outer_measure),
    { exact this _ },
    clear hs s,
    rw [outer_measure.le_pi],
    intros s hs,
    simp_rw [to_outer_measure_apply],
    exact (pi'_pi μ s).le }
end

variable {μ}

/-- `measure.pi μ` has finite spanning sets in rectangles of finite spanning sets. -/
def finite_spanning_sets_in.pi {C : Π i, set (set (α i))}
  (hμ : ∀ i, (μ i).finite_spanning_sets_in (C i)) :
  (measure.pi μ).finite_spanning_sets_in (pi univ '' pi univ C) :=
begin
  haveI := λ i, (hμ i).sigma_finite,
  haveI := fintype.encodable ι,
  let e : ℕ → (ι → ℕ) := λ n, (decode (ι → ℕ) n).iget,
  refine ⟨λ n, pi univ (λ i, (hμ i).set (e n i)), λ n, _, λ n, _, _⟩,
  { refine mem_image_of_mem _ (λ i _, (hμ i).set_mem _) },
  { calc measure.pi μ (pi univ (λ i, (hμ i).set (e n i)))
        ≤ measure.pi μ (pi univ (λ i, to_measurable (μ i) ((hμ i).set (e n i)))) :
      measure_mono (pi_mono $ λ i hi, subset_to_measurable _ _)
    ... = ∏ i, μ i (to_measurable (μ i) ((hμ i).set (e n i))) :
      pi_pi_aux μ _ (λ i, measurable_set_to_measurable _ _)
    ... = ∏ i, μ i ((hμ i).set (e n i)) :
      by simp only [measure_to_measurable]
    ... < ∞ : ennreal.prod_lt_top (λ i hi, ((hμ i).finite _).ne) },
  { simp_rw [(surjective_decode_iget (ι → ℕ)).Union_comp (λ x, pi univ (λ i, (hμ i).set (x i))),
      Union_univ_pi (λ i, (hμ i).set), (hμ _).spanning, set.pi_univ] }
end

/-- A measure on a finite product space equals the product measure if they are equal on rectangles
  with as sides sets that generate the corresponding σ-algebras. -/
lemma pi_eq_generate_from {C : Π i, set (set (α i))}
  (hC : ∀ i, generate_from (C i) = _inst_3 i)
  (h2C : ∀ i, is_pi_system (C i))
  (h3C : ∀ i, (μ i).finite_spanning_sets_in (C i))
  {μν : measure (Π i, α i)}
  (h₁ : ∀ s : Π i, set (α i), (∀ i, s i ∈ C i) → μν (pi univ s) = ∏ i, μ i (s i)) :
    measure.pi μ = μν :=
begin
  have h4C : ∀ i (s : set (α i)), s ∈ C i → measurable_set s,
  { intros i s hs, rw [← hC], exact measurable_set_generate_from hs },
  refine (finite_spanning_sets_in.pi h3C).ext
    (generate_from_eq_pi hC (λ i, (h3C i).is_countably_spanning)).symm
    (is_pi_system.pi h2C) _,
  rintro _ ⟨s, hs, rfl⟩,
  rw [mem_univ_pi] at hs,
  haveI := λ i, (h3C i).sigma_finite,
  simp_rw [h₁ s hs, pi_pi_aux μ s (λ i, h4C i _ (hs i))]
end

variables [∀ i, sigma_finite (μ i)]

/-- A measure on a finite product space equals the product measure if they are equal on
  rectangles. -/
lemma pi_eq {μ' : measure (Π i, α i)}
  (h : ∀ s : Π i, set (α i), (∀ i, measurable_set (s i)) → μ' (pi univ s) = ∏ i, μ i (s i)) :
  measure.pi μ = μ' :=
pi_eq_generate_from (λ i, generate_from_measurable_set)
  (λ i, is_pi_system_measurable_set)
  (λ i, (μ i).to_finite_spanning_sets_in) h

variables (μ)

lemma pi'_eq_pi [encodable ι] : pi' μ = measure.pi μ :=
eq.symm $ pi_eq $ λ s hs, pi'_pi μ s

@[simp] lemma pi_pi (s : Π i, set (α i)) : measure.pi μ (pi univ s) = ∏ i, μ i (s i) :=
begin
  haveI : encodable ι := fintype.encodable ι,
  rw [← pi'_eq_pi, pi'_pi]
end

lemma pi_univ : measure.pi μ univ = ∏ i, μ i univ := by rw [← pi_univ, pi_pi μ]

lemma pi_ball [∀ i, metric_space (α i)] (x : Π i, α i) {r : ℝ}
  (hr : 0 < r) :
  measure.pi μ (metric.ball x r) = ∏ i, μ i (metric.ball (x i) r) :=
by rw [ball_pi _ hr, pi_pi]

lemma pi_closed_ball [∀ i, metric_space (α i)] (x : Π i, α i) {r : ℝ}
  (hr : 0 ≤ r) :
  measure.pi μ (metric.closed_ball x r) = ∏ i, μ i (metric.closed_ball (x i) r) :=
by rw [closed_ball_pi _ hr, pi_pi]

lemma pi_unique_eq_map {β : Type*} {m : measurable_space β} (μ : measure β) (α : Type*) [unique α] :
  measure.pi (λ a : α, μ) = map (measurable_equiv.fun_unique α β).symm μ :=
begin
  set e := measurable_equiv.fun_unique α β,
  have : pi_premeasure (λ _ : α, μ.to_outer_measure) = map e.symm μ,
  { ext1 s,
    rw [pi_premeasure, fintype.prod_unique, to_outer_measure_apply, e.symm.map_apply],
    congr' 1, exact e.to_equiv.image_eq_preimage s },
  simp only [measure.pi, outer_measure.pi, this, bounded_by_measure, to_outer_measure_to_measure],
end

lemma map_fun_unique {α β : Type*} [unique α] {m : measurable_space β} (μ : measure β) :
  map (measurable_equiv.fun_unique α β) (measure.pi $ λ _, μ) = μ :=
(measurable_equiv.fun_unique α β).map_apply_eq_iff_map_symm_apply_eq.2 (pi_unique_eq_map μ _).symm

instance pi.sigma_finite : sigma_finite (measure.pi μ) :=
(finite_spanning_sets_in.pi (λ i, (μ i).to_finite_spanning_sets_in)).sigma_finite

lemma pi_of_empty {α : Type*} [is_empty α] {β : α → Type*} {m : Π a, measurable_space (β a)}
  (μ : Π a : α, measure (β a)) (x : Π a, β a := is_empty_elim) :
  measure.pi μ = dirac x :=
begin
  haveI : ∀ a, sigma_finite (μ a) := is_empty_elim,
  refine pi_eq (λ s hs, _),
  rw [fintype.prod_empty, dirac_apply_of_mem],
  exact is_empty_elim
end

lemma {u} pi_fin_two_eq_map {α : fin 2 → Type u} {m : Π i, measurable_space (α i)}
  (μ : Π i, measure (α i)) [∀ i, sigma_finite (μ i)] :
  measure.pi μ = map (measurable_equiv.pi_fin_two α).symm ((μ 0).prod (μ 1)) :=
begin
  refine pi_eq (λ s hs, _),
  rw [measurable_equiv.map_apply, fin.prod_univ_succ, fin.prod_univ_succ, fin.prod_univ_zero,
    mul_one, ← measure.prod_prod],
  congr' 1,
  ext ⟨a, b⟩,
  simp [fin.forall_fin_succ, is_empty.forall_iff]
end

lemma {u} map_pi_fin_two {α : fin 2 → Type u} {m : Π i, measurable_space (α i)}
  (μ : Π i, measure (α i)) [∀ i, sigma_finite (μ i)] :
  map (measurable_equiv.pi_fin_two α) (measure.pi μ) = ((μ 0).prod (μ 1)) :=
(measurable_equiv.pi_fin_two α).map_apply_eq_iff_map_symm_apply_eq.2 (pi_fin_two_eq_map μ).symm

lemma prod_eq_map_fin_two_arrow {α : Type*} {m : measurable_space α} (μ ν : measure α)
  [sigma_finite μ] [sigma_finite ν] :
  μ.prod ν = map measurable_equiv.fin_two_arrow (measure.pi ![μ, ν]) :=
begin
  haveI : ∀ i, sigma_finite (![μ, ν] i) := fin.forall_fin_two.2 ⟨‹_›, ‹_›⟩,
  exact (map_pi_fin_two ![μ, ν]).symm
end

lemma prod_eq_map_fin_two_arrow_same {α : Type*} {m : measurable_space α} (μ : measure α)
  [sigma_finite μ] :
  μ.prod μ = map measurable_equiv.fin_two_arrow (measure.pi $ λ _, μ) :=
by rw [prod_eq_map_fin_two_arrow, matrix.vec_single_eq_const, matrix.vec_cons_const]

lemma pi_eval_preimage_null {i : ι} {s : set (α i)} (hs : μ i s = 0) :
  measure.pi μ (eval i ⁻¹' s) = 0 :=
begin
  /- WLOG, `s` is measurable -/
  rcases exists_measurable_superset_of_null hs with ⟨t, hst, htm, hμt⟩,
  suffices : measure.pi μ (eval i ⁻¹' t) = 0,
    from measure_mono_null (preimage_mono hst) this,
  clear_dependent s,
  /- Now rewrite it as `set.pi`, and apply `pi_pi` -/
  rw [← univ_pi_update_univ, pi_pi],
  apply finset.prod_eq_zero (finset.mem_univ i),
  simp [hμt]
end

lemma pi_hyperplane (i : ι) [has_no_atoms (μ i)] (x : α i) :
  measure.pi μ {f : Π i, α i | f i = x} = 0 :=
show measure.pi μ (eval i ⁻¹' {x}) = 0,
from pi_eval_preimage_null _ (measure_singleton x)

lemma ae_eval_ne (i : ι) [has_no_atoms (μ i)] (x : α i) :
  ∀ᵐ y : Π i, α i ∂measure.pi μ, y i ≠ x :=
compl_mem_ae_iff.2 (pi_hyperplane μ i x)

variable {μ}

lemma tendsto_eval_ae_ae {i : ι} : tendsto (eval i) (measure.pi μ).ae (μ i).ae :=
λ s hs, pi_eval_preimage_null μ hs

-- TODO: should we introduce `filter.pi` and prove some basic facts about it?
-- The same combinator appears here and in `nhds_pi`
lemma ae_pi_le_infi_comap : (measure.pi μ).ae ≤ ⨅ i, filter.comap (eval i) (μ i).ae :=
le_infi $ λ i, tendsto_eval_ae_ae.le_comap

lemma ae_eq_pi {β : ι → Type*} {f f' : Π i, α i → β i} (h : ∀ i, f i =ᵐ[μ i] f' i) :
  (λ (x : Π i, α i) i, f i (x i)) =ᵐ[measure.pi μ] (λ x i, f' i (x i)) :=
(eventually_all.2 (λ i, tendsto_eval_ae_ae.eventually (h i))).mono $ λ x hx, funext hx

lemma ae_le_pi {β : ι → Type*} [Π i, preorder (β i)] {f f' : Π i, α i → β i}
  (h : ∀ i, f i ≤ᵐ[μ i] f' i) :
  (λ (x : Π i, α i) i, f i (x i)) ≤ᵐ[measure.pi μ] (λ x i, f' i (x i)) :=
(eventually_all.2 (λ i, tendsto_eval_ae_ae.eventually (h i))).mono $ λ x hx, hx

lemma ae_le_set_pi {I : set ι} {s t : Π i, set (α i)} (h : ∀ i ∈ I, s i ≤ᵐ[μ i] t i) :
  (set.pi I s) ≤ᵐ[measure.pi μ] (set.pi I t) :=
((eventually_all_finite (finite.of_fintype I)).2
  (λ i hi, tendsto_eval_ae_ae.eventually (h i hi))).mono $
    λ x hst hx i hi, hst i hi $ hx i hi

lemma ae_eq_set_pi {I : set ι} {s t : Π i, set (α i)} (h : ∀ i ∈ I, s i =ᵐ[μ i] t i) :
  (set.pi I s) =ᵐ[measure.pi μ] (set.pi I t) :=
(ae_le_set_pi (λ i hi, (h i hi).le)).antisymm (ae_le_set_pi (λ i hi, (h i hi).symm.le))

section intervals

variables {μ} [Π i, partial_order (α i)] [∀ i, has_no_atoms (μ i)]

lemma pi_Iio_ae_eq_pi_Iic {s : set ι} {f : Π i, α i} :
  pi s (λ i, Iio (f i)) =ᵐ[measure.pi μ] pi s (λ i, Iic (f i)) :=
ae_eq_set_pi $ λ i hi, Iio_ae_eq_Iic

lemma pi_Ioi_ae_eq_pi_Ici {s : set ι} {f : Π i, α i} :
  pi s (λ i, Ioi (f i)) =ᵐ[measure.pi μ] pi s (λ i, Ici (f i)) :=
ae_eq_set_pi $ λ i hi, Ioi_ae_eq_Ici

lemma univ_pi_Iio_ae_eq_Iic {f : Π i, α i} :
  pi univ (λ i, Iio (f i)) =ᵐ[measure.pi μ] Iic f :=
by { rw ← pi_univ_Iic, exact pi_Iio_ae_eq_pi_Iic }

lemma univ_pi_Ioi_ae_eq_Ici {f : Π i, α i} :
  pi univ (λ i, Ioi (f i)) =ᵐ[measure.pi μ] Ici f :=
by { rw ← pi_univ_Ici, exact pi_Ioi_ae_eq_pi_Ici }

lemma pi_Ioo_ae_eq_pi_Icc {s : set ι} {f g : Π i, α i} :
  pi s (λ i, Ioo (f i) (g i)) =ᵐ[measure.pi μ] pi s (λ i, Icc (f i) (g i)) :=
ae_eq_set_pi $ λ i hi, Ioo_ae_eq_Icc

lemma univ_pi_Ioo_ae_eq_Icc {f g : Π i, α i} :
  pi univ (λ i, Ioo (f i) (g i)) =ᵐ[measure.pi μ] Icc f g :=
by { rw ← pi_univ_Icc, exact pi_Ioo_ae_eq_pi_Icc }

lemma pi_Ioc_ae_eq_pi_Icc {s : set ι} {f g : Π i, α i} :
  pi s (λ i, Ioc (f i) (g i)) =ᵐ[measure.pi μ] pi s (λ i, Icc (f i) (g i)) :=
ae_eq_set_pi $ λ i hi, Ioc_ae_eq_Icc

lemma univ_pi_Ioc_ae_eq_Icc {f g : Π i, α i} :
  pi univ (λ i, Ioc (f i) (g i)) =ᵐ[measure.pi μ] Icc f g :=
by { rw ← pi_univ_Icc, exact pi_Ioc_ae_eq_pi_Icc }

lemma pi_Ico_ae_eq_pi_Icc {s : set ι} {f g : Π i, α i} :
  pi s (λ i, Ico (f i) (g i)) =ᵐ[measure.pi μ] pi s (λ i, Icc (f i) (g i)) :=
ae_eq_set_pi $ λ i hi, Ico_ae_eq_Icc

lemma univ_pi_Ico_ae_eq_Icc {f g : Π i, α i} :
  pi univ (λ i, Ico (f i) (g i)) =ᵐ[measure.pi μ] Icc f g :=
by { rw ← pi_univ_Icc, exact pi_Ico_ae_eq_pi_Icc }

end intervals

/-- If one of the measures `μ i` has no atoms, them `measure.pi µ`
has no atoms. The instance below assumes that all `μ i` have no atoms. -/
lemma pi_has_no_atoms (i : ι) [has_no_atoms (μ i)] :
  has_no_atoms (measure.pi μ) :=
⟨λ x, flip measure_mono_null (pi_hyperplane μ i (x i)) (singleton_subset_iff.2 rfl)⟩

instance [h : nonempty ι] [∀ i, has_no_atoms (μ i)] : has_no_atoms (measure.pi μ) :=
h.elim $ λ i, pi_has_no_atoms i

instance [Π i, topological_space (α i)] [∀ i, is_locally_finite_measure (μ i)] :
  is_locally_finite_measure (measure.pi μ) :=
begin
  refine ⟨λ x, _⟩,
  choose s hxs ho hμ using λ i, (μ i).exists_is_open_measure_lt_top (x i),
  refine ⟨pi univ s, set_pi_mem_nhds finite_univ (λ i hi, is_open.mem_nhds (ho i) (hxs i)), _⟩,
  rw [pi_pi],
  exact ennreal.prod_lt_top (λ i _, (hμ i).ne)
end

variable (μ)

/-- Separating the indices into those that satisfy a predicate `p` and those that don't maps
a product measure to a product of product measures. This is useful to apply Fubini to some subset
of the variables. The converse is `measure_theory.measure.map_pi_equiv_pi_subtype_prod`. -/
lemma map_pi_equiv_pi_subtype_prod_symm (p : ι → Prop) [decidable_pred p] :
  map (equiv.pi_equiv_pi_subtype_prod p α).symm
    (measure.prod (measure.pi (λ i, μ i)) (measure.pi (λ i, μ i))) = measure.pi μ :=
begin
  refine (measure.pi_eq (λ s hs, _)).symm,
  have A : (equiv.pi_equiv_pi_subtype_prod p α).symm ⁻¹' (set.pi set.univ (λ (i : ι), s i)) =
    set.prod (set.pi set.univ (λ i, s i)) (set.pi set.univ (λ i, s i)),
  { ext x,
    simp only [equiv.pi_equiv_pi_subtype_prod_symm_apply, mem_prod, mem_univ_pi, mem_preimage,
      subtype.forall],
    split,
    { exact λ h, ⟨λ i hi, by simpa [dif_pos hi] using h i,
                  λ i hi, by simpa [dif_neg hi] using h i⟩ },
    { assume h i,
      by_cases hi : p i,
      { simpa only [dif_pos hi] using h.1 i hi },
      {simpa only [dif_neg hi] using h.2 i hi } } },
  rw [measure.map_apply (measurable_pi_equiv_pi_subtype_prod_symm _ p)
        (measurable_set.univ_pi_fintype hs), A,
      measure.prod_prod, pi_pi, pi_pi, ← fintype.prod_subtype_mul_prod_subtype p (λ i, μ i (s i))],
end

lemma map_pi_equiv_pi_subtype_prod (p : ι → Prop) [decidable_pred p] :
  map (equiv.pi_equiv_pi_subtype_prod p α) (measure.pi μ) =
    measure.prod (measure.pi (λ i, μ i)) (measure.pi (λ i, μ i)) :=
begin
  rw [← map_pi_equiv_pi_subtype_prod_symm μ p, measure.map_map
      (measurable_pi_equiv_pi_subtype_prod _ p) (measurable_pi_equiv_pi_subtype_prod_symm _ p)],
  simp only [equiv.self_comp_symm, map_id]
end

end measure

instance measure_space.pi [Π i, measure_space (α i)] : measure_space (Π i, α i) :=
⟨measure.pi (λ i, volume)⟩

lemma volume_pi [Π i, measure_space (α i)] :
  (volume : measure (Π i, α i)) = measure.pi (λ i, volume) :=
rfl

lemma volume_pi_pi [Π i, measure_space (α i)] [∀ i, sigma_finite (volume : measure (α i))]
  (s : Π i, set (α i)) :
  volume (pi univ s) = ∏ i, volume (s i) :=
measure.pi_pi (λ i, volume) s

lemma volume_pi_ball [Π i, measure_space (α i)] [∀ i, sigma_finite (volume : measure (α i))]
  [∀ i, metric_space (α i)] (x : Π i, α i) {r : ℝ} (hr : 0 < r) :
  volume (metric.ball x r) = ∏ i, volume (metric.ball (x i) r) :=
measure.pi_ball _ _ hr

lemma volume_pi_closed_ball [Π i, measure_space (α i)] [∀ i, sigma_finite (volume : measure (α i))]
  [∀ i, metric_space (α i)] (x : Π i, α i) {r : ℝ} (hr : 0 ≤ r) :
  volume (metric.closed_ball x r) = ∏ i, volume (metric.closed_ball (x i) r) :=
measure.pi_closed_ball _ _ hr

section fun_unique
/-!
### Integral over `ι → α` with `[unique ι]`

In this section we prove some lemmas that relate integrals over `ι → β`, where `ι` is a type with
unique element (e.g., `unit` or `fin 1`) and integrals over `β`.
-/

variables {β E : Type*} [normed_group E] [normed_space ℝ E] [measurable_space E]
  [topological_space.second_countable_topology E] [borel_space E] [complete_space E]

lemma integral_fun_unique_pi (ι) [unique ι] {m : measurable_space β} (μ : measure β)
  (f : (ι → β) → E) :
  ∫ y, f y ∂(measure.pi (λ _, μ)) = ∫ x, f (λ _, x) ∂μ :=
by rw [measure.pi_unique_eq_map μ ι, integral_map_equiv]; refl

lemma integral_fun_unique_pi' (ι : Type*) [unique ι] {m : measurable_space β} (μ : measure β)
  (f : β → E) :
  ∫ y : ι → β, f (y (default ι)) ∂(measure.pi (λ _, μ)) = ∫ x, f x ∂μ :=
integral_fun_unique_pi ι μ _

lemma integral_fun_unique (ι : Type*) [unique ι] [measure_space β] (f : (ι → β) → E) :
  ∫ y, f y = ∫ x, f (λ _, x) :=
integral_fun_unique_pi ι volume f

lemma integral_fun_unique' (ι : Type*) [unique ι] [measure_space β] (f : β → E) :
  ∫ y : ι → β, f (y (default ι)) = ∫ x, f x :=
integral_fun_unique_pi' ι volume f

lemma set_integral_fun_unique_pi (ι : Type*) [unique ι] {m : measurable_space β} (μ : measure β)
  (f : (ι → β) → E) (s : set (ι → β)) :
  ∫ y in s, f y ∂(measure.pi (λ _, μ)) = ∫ x in const ι ⁻¹' s, f (λ _, x) ∂μ :=
by rw [measure.pi_unique_eq_map μ ι, set_integral_map_equiv]; refl

lemma set_integral_fun_unique_pi' (ι : Type*) [unique ι] {m : measurable_space β} (μ : measure β)
  (f : β → E) (s : set β) :
  ∫ y : ι → β in function.eval (default ι) ⁻¹' s, f (y (default ι)) ∂(measure.pi (λ _, μ)) =
    ∫ x in s, f x ∂μ :=
by erw [set_integral_fun_unique_pi, (equiv.fun_unique ι β).symm_preimage_preimage]

lemma set_integral_fun_unique (ι : Type*) [unique ι] [measure_space β] (f : (ι → β) → E)
  (s : set (ι → β)) :
  ∫ y in s, f y = ∫ x in const ι ⁻¹' s, f (λ _, x) :=
by convert set_integral_fun_unique_pi ι volume f s

lemma set_integral_fun_unique' (ι : Type*) [unique ι] [measure_space β] (f : β → E) (s : set β) :
  ∫ y : ι → β in @function.eval ι (λ _, β) (default ι) ⁻¹' s, f (y (default ι)) = ∫ x in s, f x :=
by convert set_integral_fun_unique_pi' ι volume f s

end fun_unique

section fin_two_arrow

variables {β E : Type*} [normed_group E] [normed_space ℝ E] [measurable_space E]
  [topological_space.second_countable_topology E] [borel_space E] [complete_space E]

lemma integral_fin_two_arrow_pi {m : measurable_space β} (μ ν : measure β)
  [sigma_finite μ] [sigma_finite ν] (f : (fin 2 → β) → E) :
  ∫ y, f y ∂(measure.pi ![μ, ν]) = ∫ x, f ![x.1, x.2] ∂(μ.prod ν) :=
begin
  haveI : ∀ i, sigma_finite (![μ, ν] i) := fin.forall_fin_two.2 ⟨‹_›, ‹_›⟩,
  rw [measure.pi_fin_two_eq_map, integral_map_equiv], refl
end

lemma integral_fin_two_arrow_pi' {m : measurable_space β} (μ ν : measure β) [sigma_finite μ]
  [sigma_finite ν] (f : β × β → E) :
  ∫ y : fin 2 → β, f (y 0, y 1) ∂(measure.pi ![μ, ν]) = ∫ x, f x ∂(μ.prod ν) :=
by { rw [measure.prod_eq_map_fin_two_arrow, integral_map_equiv], refl }

lemma integral_fin_two_arrow [measure_space β] [sigma_finite (volume : measure β)]
  (f : (fin 2 → β) → E) :
  ∫ y, f y = ∫ x : β × β, f ![x.1, x.2] :=
by rw [volume_pi, measure.volume_eq_prod, ← integral_fin_two_arrow_pi, matrix.vec_single_eq_const,
  matrix.vec_cons_const]

lemma integral_fin_two_arrow' [measure_space β] [sigma_finite (volume : measure β)]
  (f : β × β → E) :
  ∫ y : fin 2 → β, f (y 0, y 1) = ∫ x, f x :=
by rw [volume_pi, measure.volume_eq_prod, ← integral_fin_two_arrow_pi', matrix.vec_single_eq_const,
  matrix.vec_cons_const]

lemma set_integral_fin_two_arrow_pi {m : measurable_space β} (μ ν : measure β)
  [sigma_finite μ] [sigma_finite ν] (f : (fin 2 → β) → E) (s : set (fin 2 → β)) :
  ∫ y in s, f y ∂(measure.pi ![μ, ν]) =
    ∫ x : β × β in (fin_two_arrow_equiv β).symm ⁻¹' s, f ![x.1, x.2] ∂(μ.prod ν) :=
begin
  haveI : ∀ i, sigma_finite (![μ, ν] i) := fin.forall_fin_two.2 ⟨‹_›, ‹_›⟩,
  rw [measure.pi_fin_two_eq_map, set_integral_map_equiv], refl
end

lemma set_integral_fin_two_arrow_pi' {m : measurable_space β} (μ ν : measure β)
  [sigma_finite μ] [sigma_finite ν] (f : β × β → E) (s : set (β × β)) :
  ∫ y : fin 2 → β in fin_two_arrow_equiv β ⁻¹' s, f (y 0, y 1) ∂(measure.pi ![μ, ν]) =
    ∫ x in s, f x ∂(μ.prod ν) :=
by { rw [set_integral_fin_two_arrow_pi, equiv.symm_preimage_preimage], simp }

lemma set_integral_fin_two_arrow [measure_space β] [sigma_finite (volume : measure β)]
  (f : (fin 2 → β) → E) (s : set (fin 2 → β)) :
  ∫ y in s, f y = ∫ x in (fin_two_arrow_equiv β).symm ⁻¹' s, f ![x.1, x.2] :=
by rw [measure.volume_eq_prod, ← set_integral_fin_two_arrow_pi, volume_pi,
  matrix.vec_single_eq_const, matrix.vec_cons_const]

lemma set_integral_fin_two_arrow' [measure_space β] [sigma_finite (volume : measure β)]
  (f : β × β → E) (s : set (β × β)) :
  ∫ y : fin 2 → β in fin_two_arrow_equiv β ⁻¹' s, f (y 0, y 1) = ∫ x in s, f x :=
by rw [measure.volume_eq_prod, ← set_integral_fin_two_arrow_pi', volume_pi,
  matrix.vec_single_eq_const, matrix.vec_cons_const]

end fin_two_arrow

end measure_theory
