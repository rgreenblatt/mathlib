/-
Copyright (c) 2021 Arthur Paulino. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Arthur Paulino, Kyle Miller
-/

import combinatorics.simple_graph.subgraph
import data.nat.lattice
import data.setoid.partition
import order.antichain

/-!
# Graph Coloring

This module defines colorings of simple graphs (also known as proper
colorings in the literature). A graph coloring is the attribution of
"colors" to all of its vertices such that adjacent vertices have
different colors. A coloring can be represented as a homomorphism into
a complete graph, whose vertices represent the colors.

## Main definitions

* `G.coloring α` is the type of `α`-colorings of a simple graph `G`,
  with `α` being the set of available colors. The type is defined to
  be homomorphisms from `G` into the complete graph on `α`.

* `G.colorable n` is the proposition that `G` is `n`-colorable, which
  is whether there exists a coloring with at most *n* colors.

* `G.chromatic_number` is the minimal `n` such that `G` is
  `n`-colorable, or `0` if it cannot be colored with finitely many
  colors.

* A *color class* is a set of vertices that share the same color.

## Todo:

  * Gather material from:
    * https://github.com/leanprover-community/mathlib/blob/simple_graph_matching/src/combinatorics/simple_graph/coloring.lean
    * https://github.com/kmill/lean-graphcoloring/blob/master/src/graph.lean

  * Lowerbound for cliques

  * Trees

  * Planar graphs

  * Chromatic polynomials

  * develop API for partial colorings, likely as colorings of subgraphs (`H.coe.coloring α`)
-/

universes u v

namespace simple_graph
variables {V : Type u} (G : simple_graph V)

/--
An `α`-coloring of a simple graph `G` is a homomorphism of `G` into the complete graph on `α`.
This is also known as a proper coloring.
-/
abbreviation coloring (α : Type v) := G →g (⊤ : simple_graph α)

variables {G} {α : Type v} (C : G.coloring α)

lemma coloring.valid {v w : V} (h : G.adj v w) : C v ≠ C w :=
C.map_rel h

/--
Construct a term of `simple_graph.coloring` using a function that
assigns vertices to colors and a proof that it is as proper coloring.

(Note: this is a definitionally the constructor for `simple_graph.hom`,
but with a syntactically better proper coloring hypothesis.)
-/
@[pattern] def coloring.mk
  (color : V → α)
  (valid : ∀ {v w : V}, G.adj v w → color v ≠ color w) :
  G.coloring α := ⟨color, @valid⟩

/--
The color class of a given color.
-/
def coloring.color_class_of_color (c : α) : set V := {v : V | C v = c}

/-- The color class of a given vertex. -/
def coloring.color_class_of_vertex (v : V) : set V := C.color_class_of_color (C v)

/-- The set containing all color classes. -/
def coloring.color_classes : set (set V) := {(C.color_class_of_vertex v) | v : V}

lemma coloring.vertex_in_its_color_class {v : V} :
  v ∈ {v' : V | C v' = C v} := by exact rfl

lemma coloring.color_classes_is_partition :
  setoid.is_partition C.color_classes :=
begin
  rw setoid.is_partition,
  simp only [exists_unique],
  simp [coloring.color_classes, coloring.color_class_of_vertex,
    coloring.color_class_of_color],
  split,
  { intro v,
    rw [← set.not_nonempty_iff_eq_empty, not_not],
    use v,
    apply coloring.vertex_in_its_color_class, },
  { intro v,
    split,
    { split,
      { use v,
        apply coloring.vertex_in_its_color_class, },
      { intros w hcvw,
        rw hcvw, }, }, },
end

lemma coloring.color_classes_is_independent :
  ∀ (s ∈ C.color_classes), is_antichain G.adj s :=
begin
  simp only [is_antichain, set.pairwise],
  simp [coloring.color_classes, coloring.color_class_of_vertex,
    coloring.color_class_of_color],
  intros v w hcvw z hczv h_neq_wz,
  have hcwz : C w = C z, by exact (rfl.congr (eq.symm hczv)).mp hcvw,
  by_contra,
  have hwz : G.adj w z, by { contrapose h, contradiction, },
  have hvalid := C.valid hwz,
  contradiction,
end

-- TODO make this computable
noncomputable
instance [fintype V] [fintype α] : fintype (coloring G α) :=
begin
  classical,
  change fintype (rel_hom G.adj (⊤ : simple_graph α).adj),
  apply fintype.of_injective _ rel_hom.coe_fn_injective,
  apply_instance,
end

variables (G)

/-- Whether a graph can be colored by at most `n` colors. -/
def colorable (n : ℕ) : Prop := nonempty (G.coloring (fin n))

/-- The coloring of an empty graph. -/
def coloring_of_is_empty [is_empty V] : G.coloring α :=
coloring.mk is_empty_elim (λ v, is_empty_elim)

lemma colorable_of_is_empty [is_empty V] (n : ℕ) : G.colorable n :=
⟨G.coloring_of_is_empty⟩

lemma is_empty_of_colorable_zero (h : G.colorable 0) : is_empty V :=
begin
  split,
  intro v,
  obtain ⟨i, hi⟩ := h.some v,
  exact nat.not_lt_zero _ hi,
end

/-- The "tautological" coloring of a graph, using the vertices of the graph as colors. -/
def self_coloring : G.coloring V :=
coloring.mk id (λ v w, G.ne_of_adj)

/-- The chromatic number of a graph is the minimal number of colors needed to color it.
If `G` isn't colorable with finitely many colors, this will be 0. -/
noncomputable def chromatic_number : ℕ :=
Inf { n : ℕ | G.colorable n }

/-- Given an embedding, there is an induced embedding of colorings. -/
def recolor_of_embedding {α β : Type*} (f : α ↪ β) : G.coloring α ↪ G.coloring β :=
{ to_fun := λ C, (embedding.complete_graph.of_embedding f).to_hom.comp C,
  inj' := begin -- this was strangely painful; seems like missing lemmas about embeddings
    intros C C' h,
    dsimp only at h,
    ext v,
    apply (embedding.complete_graph.of_embedding f).inj',
    change ((embedding.complete_graph.of_embedding f).to_hom.comp C) v = _,
    rw h,
    refl,
  end }

/-- Given an equivalence, there is an induced equivalence between colorings. -/
def recolor_of_equiv {α β : Type*} (f : α ≃ β) : G.coloring α ≃ G.coloring β :=
{ to_fun := G.recolor_of_embedding f.to_embedding,
  inv_fun := G.recolor_of_embedding f.symm.to_embedding,
  left_inv := λ C, by { ext v, apply equiv.symm_apply_apply },
  right_inv := λ C, by { ext v, apply equiv.apply_symm_apply } }

/-- There is a noncomputable embedding of `α`-colorings to `β`-colorings if
`β` has at least as large a cardinality as `α`. -/
noncomputable def recolor_of_card_le {α β : Type*} [fintype α] [fintype β]
  (hn : fintype.card α ≤ fintype.card β) :
  G.coloring α ↪ G.coloring β :=
G.recolor_of_embedding $ (function.embedding.nonempty_of_card_le hn).some

variables {G}

lemma colorable.of_le {n m : ℕ} (hc : G.colorable n) (h : n ≤ m) : G.colorable m :=
⟨G.recolor_of_card_le (by simp [h]) hc.some⟩

lemma coloring.to_colorable [fintype α] (C : G.coloring α) :
  G.colorable (fintype.card α) :=
⟨G.recolor_of_card_le (by simp) C⟩

lemma colorable_of_fintype (G : simple_graph V) [fintype V] :
  G.colorable (fintype.card V) :=
G.self_coloring.to_colorable

/-- Noncomputably get a coloring from colorability. -/
noncomputable def colorable.to_coloring [fintype α] {n : ℕ} (hc : G.colorable n)
  (hn : n ≤ fintype.card α) :
  G.coloring α :=
begin
  rw ←fintype.card_fin n at hn,
  exact G.recolor_of_card_le hn hc.some,
end

lemma colorable_iff_exists_bdd_nat_coloring (n : ℕ) :
  G.colorable n ↔ ∃ (C : G.coloring ℕ), ∀ v, C v < n :=
begin
  split,
  { rintro hc,
    have C : G.coloring (fin n) := hc.to_coloring (by simp),
    let f := embedding.complete_graph.of_embedding (fin.coe_embedding n).to_embedding,
    use f.to_hom.comp C,
    intro v,
    cases C with color valid,
    exact fin.is_lt (color v), },
  { rintro ⟨C, Cf⟩,
    refine ⟨coloring.mk _ _⟩,
    { exact λ v, ⟨C v, Cf v⟩, },
    { rintro v w hvw,
      simp only [complete_graph_eq_top, top_adj, subtype.mk_eq_mk, ne.def],
      exact C.valid hvw, } }
end

lemma colorable_set_nonempty_of_colorable {n : ℕ} (hc : G.colorable n) :
  {n : ℕ | G.colorable n}.nonempty :=
⟨n, hc⟩

lemma chromatic_number_bdd_below : bdd_below {n : ℕ | G.colorable n} :=
⟨0, λ _ _, zero_le _⟩

lemma chromatic_number_le [fintype α] (C : G.coloring α) :
  G.chromatic_number ≤ fintype.card α :=
cInf_le chromatic_number_bdd_below C.to_colorable

lemma colorable_chromatic_number {m : ℕ} (hc : G.colorable m) :
  G.colorable G.chromatic_number :=
begin
  dsimp only [chromatic_number],
  rw nat.Inf_def,
  apply nat.find_spec,
  exact colorable_set_nonempty_of_colorable hc,
end

lemma colorable_chromatic_number_of_fintype (G : simple_graph V) [fintype V] :
  G.colorable G.chromatic_number :=
colorable_chromatic_number G.colorable_of_fintype

lemma chromatic_number_le_one_of_subsingleton (G : simple_graph V) [subsingleton V] :
  G.chromatic_number ≤ 1 :=
begin
  rw chromatic_number,
  apply cInf_le chromatic_number_bdd_below,
  fsplit,
  refine coloring.mk (λ _, 0) _,
  intros v w,
  rw subsingleton.elim v w,
  simp,
end

lemma chromatic_number_eq_zero_of_isempty (G : simple_graph V) [is_empty V] :
  G.chromatic_number = 0 :=
begin
  rw ←nonpos_iff_eq_zero,
  apply cInf_le chromatic_number_bdd_below,
  apply colorable_of_is_empty,
end

lemma is_empty_of_chromatic_number_eq_zero (G : simple_graph V) [fintype V]
  (h : G.chromatic_number = 0) : is_empty V :=
begin
  have h' := G.colorable_chromatic_number_of_fintype,
  rw h at h',
  exact G.is_empty_of_colorable_zero h',
end

lemma zero_lt_chromatic_number [nonempty V] {n : ℕ} (hc : G.colorable n) :
  0 < G.chromatic_number :=
begin
  apply le_cInf (colorable_set_nonempty_of_colorable hc),
  intros m hm,
  by_contra h',
  simp only [not_le, nat.lt_one_iff] at h',
  subst h',
  obtain ⟨i, hi⟩ := hm.some (classical.arbitrary V),
  exact nat.not_lt_zero _ hi,
end

lemma colorable_lower_bound {G' : simple_graph V} (h : G ≤ G') (n : ℕ) (hc : G'.colorable n) :
  G.colorable n :=
⟨hc.some.comp (hom.map_spanning_subgraphs h)⟩

lemma chromatic_number_le_of_forall_imp {G' : simple_graph V}
  {m : ℕ} (hc : G'.colorable m)
  (h : ∀ n, G'.colorable n → G.colorable n) :
  G.chromatic_number ≤ G'.chromatic_number :=
begin
  apply cInf_le chromatic_number_bdd_below,
  apply h,
  apply colorable_chromatic_number hc,
end

lemma chromatic_number_lower_bound (G' : simple_graph V)
  {m : ℕ} (hc : G'.colorable m) (h : G ≤ G') :
  G.chromatic_number ≤ G'.chromatic_number :=
begin
  apply chromatic_number_le_of_forall_imp hc,
  exact colorable_lower_bound h,
end

lemma chromatic_number_le_n_of_colorable {n : ℕ} (hc : G.colorable n) :
  G.chromatic_number ≤ n :=
begin
  rw chromatic_number,
  apply cInf_le chromatic_number_bdd_below,
  fsplit,
  exact classical.choice hc,
end

lemma chromatic_number_minimal [fintype α] (C : G.coloring α)
  (h : ∀ (C' : G.coloring α), function.surjective C') :
  G.chromatic_number = fintype.card α :=
begin
  apply le_antisymm,
  { apply chromatic_number_le C, },
  { by_contra hc,
    rw not_le at hc,
    obtain ⟨n, cn, hc⟩ := exists_lt_of_cInf_lt
      (colorable_set_nonempty_of_colorable C.to_colorable) hc,
    have C' := cn.some,
    rw ←fintype.card_fin n at hc,
    have f := (function.embedding.nonempty_of_card_le (le_of_lt hc)).some,
    specialize h (G.recolor_of_embedding f C'),
    change function.surjective (f ∘ C') at h,
    have h1 : function.surjective f := function.surjective.of_comp h,
    have h2 := fintype.card_le_of_surjective _ h1,
    exact nat.lt_le_antisymm hc h2, },
end

lemma chromatic_number_bot [nonempty V] :
  (⊥ : simple_graph V).chromatic_number = 1 :=
begin
  let C : (⊥ : simple_graph V).coloring (fin 1) :=
    coloring.mk (λ _, 0) (λ v w h, false.elim h),
  apply le_antisymm,
  { exact chromatic_number_le C, },
  { exact zero_lt_chromatic_number C.to_colorable, },
end

lemma chromatic_number_complete_graph [fintype V] :
  (⊤ : simple_graph V).chromatic_number = fintype.card V :=
begin
  apply chromatic_number_minimal (self_coloring _),
  intro C,
  rw ←fintype.injective_iff_surjective,
  intros v w,
  contrapose,
  intro h,
  exact C.valid h,
end

/-- The bicoloring of a complete bipartite graph using whether a vertex
is on the left or on the right. -/
def complete_bipartite_graph.bicoloring (V W : Type*) :
  (complete_bipartite_graph V W).coloring bool :=
coloring.mk (λ v, v.is_right) begin
  intros v w,
  cases v; cases w; simp,
end

lemma complete_bipartite_graph.chromatic_number {V W : Type*} [nonempty V] [nonempty W] :
  (complete_bipartite_graph V W).chromatic_number = 2 :=
begin
  apply chromatic_number_minimal (complete_bipartite_graph.bicoloring V W),
  intros C b,
  have v := classical.arbitrary V,
  have w := classical.arbitrary W,
  have h : (complete_bipartite_graph V W).adj (sum.inl v) (sum.inr w) := by simp,
  have hn := C.valid h,
  by_cases he : C (sum.inl v) = b,
  { exact ⟨_, he⟩ },
  { by_cases he' : C (sum.inr w) = b,
    { exact ⟨_, he'⟩ },
    { exfalso,
      cases b;
      simp only [eq_tt_eq_not_eq_ff, eq_ff_eq_not_eq_tt] at he he';
      rw [he, he'] at hn;
      contradiction }, },
end

end simple_graph
