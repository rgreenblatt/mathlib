/-
Copyright (c) 2021 Yaël Dillies, Bhavik Mehta. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yaël Dillies, Bhavik Mehta
-/
import .bounds
import .finpartitions
import .prereqs
import .witness

/-!
# Chunk of `increment`
-/

open finpartition_on finset fintype relation
open_locale big_operators classical

variables {α : Type*} [fintype α] {P : finpartition α} (hP : P.is_equipartition)
  (G : simple_graph α) (ε : ℝ) {U : finset α} (hU : U ∈ P.parts) (V : finset α)

local notation `m` := (card α/exp_bound P.size : ℕ)
local notation `a` := (card α/P.size - m * 4^P.size : ℕ)

noncomputable def finpartition.witnesses
  (P : finpartition α) (G : simple_graph α) (ε : ℝ) (U : finset α) :=
(P.parts.filter (λ V, U ≠ V ∧ ¬G.is_uniform ε U V)).image (λ V, (G.witness ε U V).1)

/-- The part of `increment` that partitions `U`. -/
noncomputable def finpartition_on.is_equipartition.chunk_increment :
  finpartition_on U :=
dite (U.card = m * 4^P.size + a)
  (λ hUcard, (atomise U (P.witnesses G ε U)).equitabilise $ card_aux₂ hUcard)
  (λ hUcard, (atomise U (P.witnesses G ε U)).equitabilise $ card_aux₃ hP hU hUcard)
  -- hP and hU are used to get that U has size m * 4^P.size + a or m * 4^P.size + a + 1

noncomputable def finpartition_on.is_equipartition.star (V : finset α) :
  finset (finset α) :=
(hP.chunk_increment G ε hU).parts.filter (λ x, x ⊆ (G.witness ε U V).1)

/-! # star -/

/-- Each thing in star is a subset of the witness -/
lemma subset_witness_of_mem_star : ∀ A ∈ hP.star G ε hU V, A ⊆ (G.witness ε U V).1 :=
λ A hA, (mem_filter.1 hA).2

lemma bUnion_star_subset_witness : (hP.star G ε hU V).bUnion id ⊆ (G.witness ε U V).1 :=
bUnion_subset_iff_forall_subset.2 (subset_witness_of_mem_star hP G ε hU V)

lemma star_subset_chunk_increment : hP.star G ε hU V ⊆ (hP.chunk_increment G ε hU).parts :=
filter_subset _ _

lemma star_pairwise_disjoint : ∀ (x y ∈ hP.star G ε hU V), ∀ i ∈ x, i ∈ y → x = y :=
λ x y hx hy,
  finpartition_on.disjoint _ _ _ (star_subset_chunk_increment hP G ε hU V hx) (star_subset_chunk_increment hP G ε hU V hy)

variables {V}

lemma witness_sdiff_bUnion_star_small (hV : V ∈ P.parts) (h₁ : U ≠ V) (h₂ : ¬G.is_uniform ε U V) :
  ((G.witness ε U V).1 \ (hP.star G ε hU V).bUnion id).card ≤ 2^(P.size - 1) * m :=
begin
  have hX : (G.witness ε U V).1 ∈ P.witnesses G ε U := mem_image_of_mem _ (by simp [h₁, hV, h₂]),
  have q : (G.witness ε U V).1 \ (hP.star G ε hU V).bUnion id ⊆
    ((atomise U (P.witnesses G ε U)).parts.filter (λ B, B ⊆ (G.witness ε U V).1 ∧ B.nonempty)).bUnion
      (λ B, B \ ((hP.chunk_increment G ε hU).parts.filter (λ x, x ⊆ B)).bUnion id),
  { intros x hx,
    rw [←union_of_atoms' (G.witness ε U V).1 hX G.left_witness_subset,
      finpartition_on.is_equipartition.star, mem_sdiff, mem_bUnion] at hx,
    simp only [not_exists, mem_bUnion, and_imp, filter_congr_decidable, exists_prop, mem_filter,
      not_and, mem_sdiff, id.def] at hx,
    simp only [not_exists, mem_bUnion, and_imp, exists_prop, mem_filter, not_and, mem_sdiff, id.def],
    rcases hx with ⟨⟨B, hB₁, hB₂⟩, hx⟩,
    refine ⟨B, hB₁, hB₂, _⟩,
    intros A hA AB,
    apply hx A hA,
    apply AB.trans hB₁.2.1 },
  apply (card_le_of_subset q).trans,
  apply card_bUnion_le.trans,
  have :
    ∑ i in filter (λ (B : finset α), B ⊆ (G.witness ε U V).fst ∧ B.nonempty) (atomise U (P.witnesses G ε U)).parts,
      (card α / exp_bound (finpartition_on.size P))
    ≤ 2 ^ (finpartition_on.size P - 1) * (card α / exp_bound (finpartition_on.size P)),
  { rw sum_const_nat,
    apply mul_le_mul_of_nonneg_right,
    have t := partial_atomise (G.witness ε U V).1 hX G.left_witness_subset,
    rw filter_congr_decidable at t,
    apply t.trans,
    refine pow_le_pow (by norm_num) _,
    apply nat.sub_le_sub_right,
    rw finpartition.witnesses,
    apply card_image_le.trans,
    apply card_le_of_subset,
    apply filter_subset,
    apply zero_le,
    intros,
    refl },
  apply le_trans _ this,
  have : ∀ B ∈ (atomise U (P.witnesses G ε U)).parts,
  (B \ ((hP.chunk_increment G ε hU).parts.filter (λ x, x ⊆ B)).bUnion id).card ≤
    card α / exp_bound (finpartition_on.size P),
  { intros B hB,
    rw [finpartition_on.is_equipartition.chunk_increment],
    split_ifs with h₁,
    { have := almost_in_atoms_of_mem_parts_equitabilise (card_aux₂ h₁) hB,
      rw filter_congr_decidable at this,
      apply this },
    have := almost_in_atoms_of_mem_parts_equitabilise (card_aux₃ hP hU h₁) hB,
    rw filter_congr_decidable at this,
    apply this },
  apply sum_le_sum,
  intros B hB,
  apply this B (filter_subset _ _ hB),
end

lemma one_sub_eps_mul_card_witness_le_card_star (hV : V ∈ P.parts)
  (h₁ : U ≠ V) (h : ¬G.is_uniform ε U V)
  (hPε : 100 ≤ 4^P.size * ε^5) (hε₁ : ε ≤ 1) :
  (1 - ε/10) * (G.witness ε U V).1.card ≤ ((hP.star G ε hU V).bUnion id).card :=
begin
  have hε' : 0 < ε := sorry,
  have : (2^P.size : ℝ) * m/(U.card * ε) ≤ ε/10,
  { rw [←div_div_eq_div_mul, div_le_iff' hε'],
    refine le_of_mul_le_mul_left _ (pow_pos zero_lt_two P.size),
    calc
      2^P.size * ((2^P.size * m : ℝ)/U.card)
      = (2 * 2)^P.size/U.card : sorry
      ... = 4^P.size/U.card : by norm_num
      ... ≤ 1 : sorry
      ... ≤ 2^P.size * ε^2 / 10 : begin
        refine (one_le_sq_iff (div_nonneg (mul_nonneg (pow_nonneg (@zero_le_two ℝ _) _) $ sq_nonneg _) $ by norm_num)).1 _,
        rw [div_pow, mul_pow, pow_right_comm, ←pow_mul ε,
          one_le_div (sq_pos_of_ne_zero (10 : ℝ) $ by norm_num)],
        calc
          (10 ^ 2 : ℝ)
          = 100 : by norm_num
          ... ≤ 4^P.size * ε^5 : hPε
          ... ≤ 4^P.size * ε^4
              : mul_le_mul_of_nonneg_left (pow_le_pow_of_le_one hε'.le hε₁ (nat.le_succ _))
                  (pow_nonneg zero_lt_four.le _)
          ... = (2^2)^P.size * ε ^ (2 * 2) : by norm_num,
      end
      ... = 2^P.size * (ε * (ε / 10)) : by rw [mul_div_assoc, sq, mul_div_assoc] },
  calc
    (1 - ε/10) * (G.witness ε U V).1.card
        ≤ (1 - 2^P.size * m/(U.card * ε)) * (G.witness ε U V).1.card
        : mul_le_mul_of_nonneg_right (sub_le_sub_left this _) (nat.cast_nonneg _)
    ... = (1 - 2^P.size * m/(U.card * ε)) * (G.witness ε U V).1.card: sorry
    ... ≤ (G.witness ε U V).1.card - 2^(P.size - 1) * m : sorry
    ... ≤ ((hP.star G ε hU V).bUnion id).card
        : begin
          norm_cast,
          rw [sub_le, ←nat.cast_sub (finset.card_le_of_subset $ bUnion_star_subset_witness
            hP G ε hU V), ←card_sdiff (bUnion_star_subset_witness hP G ε hU V), nat.cast_le],
          exact witness_sdiff_bUnion_star_small hP G ε hU hV h₁ h,
        end
end.

variables {hP G ε U hU V}

/-! # chunk_increment -/

lemma chunk_increment.size (m_pos : 0 < m) : (hP.chunk_increment G ε hU).size = 4^P.size :=
begin
  rw finpartition_on.is_equipartition.chunk_increment,
  split_ifs,
  { rw [finpartition_on.equitabilise.size m_pos, nat.sub_add_cancel],
    exact le_of_lt a_add_one_le_four_pow_size },
  { rw [finpartition_on.equitabilise.size m_pos, nat.sub_add_cancel],
    exact a_add_one_le_four_pow_size }
end

lemma card_eq_of_mem_parts_chunk_increment {A : finset α}
  (hA : A ∈ (hP.chunk_increment G ε hU).parts) :
  A.card = m ∨ A.card = m + 1 :=
begin
  simp [finpartition_on.is_equipartition.chunk_increment] at hA,
  by_cases hUcard : U.card = m * 4^P.size + a,
  { rw dif_pos hUcard at hA,
    exact finpartition_on.card_eq_of_mem_parts_equitabilise _ hA },
  rw dif_neg hUcard at hA,
  exact finpartition_on.card_eq_of_mem_parts_equitabilise _ hA,
end

lemma m_le_card_of_mem_chunk_increment_parts {A : finset α}
  (hA : A ∈ (hP.chunk_increment G ε hU).parts) :
  (m : ℝ) ≤ A.card :=
begin
  obtain h | h := card_eq_of_mem_parts_chunk_increment hA; rw h,
  exact nat.cast_le.2 (nat.le_succ _),
end

lemma card_le_m_add_one_of_mem_chunk_increment_parts {A : finset α}
  (hA : A ∈ (hP.chunk_increment G ε hU).parts) :
  (A.card : ℝ) ≤ m + 1 :=
begin
  obtain h | h := card_eq_of_mem_parts_chunk_increment hA; rw h,
  { exact nat.cast_le.2 (nat.le_succ _) },
  { rw nat.cast_add_one }
end

lemma le_sum_card_subset_chunk_increment_parts (m_pos : 0 < m) {A : finset (finset α)}
  (hA : A ⊆ (hP.chunk_increment G ε hU).parts) {u : finset α} (hu : u ∈ A) :
  (A.card : ℝ) * u.card ≤ (∑ V in A, V.card)/(m/(m + 1)) :=
begin
  rw le_div_iff, swap,
  { exact div_pos (nat.cast_pos.2 m_pos) (nat.cast_add_one_pos _) },
  calc
    (A.card : ℝ) * u.card * (m/(m + 1))
        = A.card * m * (u.card/(m + 1))
        : by rw [←mul_div_assoc, mul_right_comm, mul_div_assoc]
    ... ≤ A.card * m
        : mul_le_of_le_one_right
          (mul_nonneg (nat.cast_nonneg _) (nat.cast_nonneg _)) ((div_le_one $ by exact
          nat.cast_add_one_pos _).2 $ card_le_m_add_one_of_mem_chunk_increment_parts $ hA hu)
    ... = ∑ V in A, (m : ℝ)
        : by rw [sum_const, nsmul_eq_mul]
    ... ≤ ∑ V in A, V.card
        : sum_le_sum (λ V hV, m_le_card_of_mem_chunk_increment_parts $ hA hV)
end

lemma sum_card_subset_chunk_increment_parts_le (m_pos : 0 < m) {A : finset (finset α)}
  (hA : A ⊆ (hP.chunk_increment G ε hU).parts) {u : finset α} (hu : u ∈ A) :
  (∑ V in A, (V.card : ℝ))/((m + 1)/m) ≤ A.card * u.card :=
begin
  rw div_le_iff, swap,
  { exact div_pos (nat.cast_add_one_pos _) (nat.cast_pos.2 m_pos) },
  calc
    ∑ V in A, (V.card : ℝ)
        ≤ ∑ V in A, (m + 1)
        : sum_le_sum (λ V hV, card_le_m_add_one_of_mem_chunk_increment_parts $ hA hV)
    ... = A.card * (m + 1) : by rw [sum_const, nsmul_eq_mul]
    ... ≤ A.card * (m + 1) * (u.card/m) : le_mul_of_one_le_right (mul_nonneg (nat.cast_nonneg _)
          (nat.cast_add_one_pos _).le) ((one_le_div (by exact nat.cast_pos.2 m_pos)).2
          (m_le_card_of_mem_chunk_increment_parts $ hA hu))
    ... = A.card * u.card * ((m + 1)/m)
        : by rw [←mul_div_assoc, mul_right_comm, mul_div_assoc]
end

lemma one_sub_le_m_div_m_add_one_sq [nonempty α] (hPα : P.size * 16^P.size ≤ card α)
  (hPε : 100 ≤ 4^P.size * ε^5) :
  1 - ε^5/50 ≤ (m/(m + 1))^2 :=
begin
  have hε : 0 < ε^5 := pos_of_mul_pos_left (lt_of_lt_of_le (by norm_num) hPε)
    (pow_nonneg (by norm_num) _),
  calc
    1 - ε^5/50
        = 1 - 2/(100/ε^5) : begin
          rw [div_div_eq_mul_div, mul_comm, mul_div_assoc, div_eq_mul_one_div],
          norm_num,
         end
    ... ≤ 1 - 2/m : sub_le_sub_left (div_le_div_of_le_left zero_le_two
          (div_pos (by norm_num) hε) (hundred_div_ε_pow_five_le_m hPα hPε)) _
    ... ≤ 1 - 2/(m + 1) : sub_le_sub_left (div_le_div_of_le_left zero_le_two
          (nat.cast_pos.2 (m_pos hPα)) ((le_add_iff_nonneg_right _).2 zero_le_one)) _
    ... ≤ 1 - 2/(m + 1) + 1/(m + 1)^2
        : le_add_of_nonneg_right (div_nonneg zero_le_one (sq_nonneg _))
    ... = ((m + 1 - 1)/(m + 1))^2 : by rw [sub_div, div_self (nat.cast_add_one_ne_zero m :
            (m : ℝ) + 1 ≠ 0), sub_sq, div_pow, one_pow, mul_one, mul_one_div]
    ... = (m/(m + 1))^2 : by rw add_sub_cancel,
end

lemma m_add_one_div_m_le_one_add [nonempty α] (hPα : P.size * 16^P.size ≤ card α)
  (hPε : 100 ≤ 4^P.size * ε^5) (hm : 25 ≤ m) :
  ((m + 1 : ℝ)/m)^2 ≤ 1 + ε^5/49 :=
begin
  have m_pos : (0 : ℝ) < m,
  { rw ←nat.cast_zero,
    exact lt_of_lt_of_le (by norm_num) (nat.cast_le.2 hm) },
  rw [←sub_le_iff_le_add', add_comm],
  calc
    ((1 + m : ℝ)/m)^2 - 1
        = 1/m/m + 2/m : by rw [add_div, div_self m_pos.ne', add_sq, div_pow, one_pow, mul_one,
          mul_one_div, sq, ←div_div_eq_div_mul, add_sub_cancel]
    ... ≤ 1/25/m + 2/m : begin
      refine add_le_add_right (div_le_div_of_le_of_nonneg (div_le_div_of_le_left zero_le_one
        (by norm_num) _) (nat.cast_nonneg _)) _,
      rw (by norm_num : (25 : ℝ) = (25 : ℕ)),
      exact nat.cast_le.2 hm,
    end
    ... = (1/25 + 2)/m : (add_div _ _ _).symm
    ... ≤ 100/49/m : div_le_div_of_le_of_nonneg (by norm_num) (nat.cast_nonneg _)
    ... ≤ ε^5/49 : begin
      rw div_right_comm,
      refine div_le_div_of_le_of_nonneg _ (by norm_num),
      rw [div_le_iff m_pos, mul_comm, ←div_le_iff
        (pos_of_mul_pos_left (lt_of_lt_of_le (by norm_num) hPε) (pow_nonneg (by norm_num) _))],
      exact hundred_div_ε_pow_five_le_m hPα hPε,
    end
end

lemma density_sub_eps_le_sum_density_div_card [nonempty α] (hPα : P.size * 16^P.size ≤ card α)
  (hPε : 100 ≤ 4^P.size * ε^5) (m_pos : 0 < m)
  {U V : finset α} {hU : U ∈ P.parts} {hV : V ∈ P.parts} {A B : finset (finset α)}
  (hA : A ⊆ (hP.chunk_increment G ε hU).parts) (hB : B ⊆ (hP.chunk_increment G ε hV).parts) :
  G.edge_density (A.bUnion id) (B.bUnion id) - ε^5/50 ≤
  (∑ ab in A.product B, G.edge_density ab.1 ab.2)/(A.card * B.card) :=
begin
  have hε : 0 < ε^5 := pos_of_mul_pos_left ((by norm_num : (0 : ℝ) < 100).trans_le hPε)
    (pow_nonneg (by norm_num) _),
  calc
    G.edge_density (A.bUnion id) (B.bUnion id) - ε^5/50
        ≤ (1 - ε^5/50) * G.edge_density (A.bUnion id) (B.bUnion id)
        : begin
            rw [sub_mul, one_mul],
            exact sub_le_sub_left (mul_le_of_le_one_right (div_nonneg hε.le (by norm_num))
              (G.edge_density_le_one _ _)) _,
          end
    ... ≤ (m/(m + 1))^2 * G.edge_density (A.bUnion id) (B.bUnion id)
        : mul_le_mul_of_nonneg_right (one_sub_le_m_div_m_add_one_sq hPα hPε)
          (G.edge_density_nonneg _ _)
    ... = pairs_count G.adj (A.bUnion id) (B.bUnion id) /
          ((A.bUnion id).card/(m/(m + 1)) * ((B.bUnion id).card/(m/(m + 1))))
        : begin
            unfold simple_graph.edge_density pairs_density,
            simp_rw [←div_div_eq_div_mul],
            rw [div_div_eq_mul_div, div_div_eq_mul_div],
            ring,
          end
    ... = ∑ ab in A.product B, pairs_count G.adj ab.1 ab.2/((∑ aa in A, (aa.card : ℝ))/(m/(m + 1))
          * ((∑ b in B, (b.card : ℝ))/(m/(m + 1))))
        : begin
            rw [relation.pairs_count_finpartition hA.finpartition_on hB.finpartition_on,
              ←hA.finpartition_on.sum_card_parts, ←hB.finpartition_on.sum_card_parts],
            simp only [nat.cast_sum],
            rw [sum_div, hA.finpartition_on_parts, hB.finpartition_on_parts],
          end
    ... ≤ ∑ ab in A.product B, pairs_count G.adj ab.1 ab.2/(A.card * ab.1.card *
          (B.card * ab.2.card))
          : begin
            refine sum_le_sum (λ x hx, div_le_div_of_le_left (nat.cast_nonneg _) _ _);
            rw mem_product at hx,
            { norm_cast,
              refine mul_pos (mul_pos _ _) (mul_pos _ _); rw card_pos,
              exacts [⟨x.1, hx.1⟩, nonempty_of_mem_parts _ (hA hx.1), ⟨x.2, hx.2⟩,
                nonempty_of_mem_parts _ (hB hx.2)] },
            refine mul_le_mul (le_sum_card_subset_chunk_increment_parts m_pos hA hx.1)
              (le_sum_card_subset_chunk_increment_parts m_pos hB hx.2) _
              (div_nonneg _ (div_nonneg _ _));
            norm_cast; exact nat.zero_le _,
          end
    ... = (∑ ab in A.product B, G.edge_density ab.1 ab.2)/(A.card * B.card)
        : begin
            unfold simple_graph.edge_density pairs_density,
            rw sum_div,
            simp_rw div_div_eq_div_mul,
            refine finset.sum_congr rfl (λ x _, _),
            rw [mul_comm (B.card : ℝ), ←mul_assoc, ←mul_assoc, mul_comm _ (A.card : ℝ), ←mul_assoc],
          end
end

lemma sum_density_div_card_le_density_add_eps [nonempty α] (hPα : P.size * 16^P.size ≤ card α)
  (hPε : 100 ≤ 4^P.size * ε^5) (hm : 25 ≤ m)
  {U V : finset α} {hU : U ∈ P.parts} {hV : V ∈ P.parts} {A B : finset (finset α)}
  (hA : A ⊆ (hP.chunk_increment G ε hU).parts) (hB : B ⊆ (hP.chunk_increment G ε hV).parts) :
  (∑ ab in A.product B, G.edge_density ab.1 ab.2)/(A.card * B.card) ≤
  G.edge_density (A.bUnion id) (B.bUnion id) + ε^5/49 :=
begin
  have hε : 0 < ε^5 := pos_of_mul_pos_left ((by norm_num : (0 : ℝ) < 100).trans_le hPε)
    (pow_nonneg (by norm_num) _),
  have m_pos : 0 < m := (by norm_num : 0 < 25).trans_le hm,
  have m_add_one_div_m_pos : (0 : ℝ) < (m + 1)/m :=
    div_pos (nat.cast_add_one_pos _) (nat.cast_pos.2 m_pos),
  calc
    (∑ ab in A.product B, G.edge_density ab.1 ab.2)/(A.card * B.card)
        = ∑ ab in A.product B, pairs_count G.adj ab.1 ab.2/(A.card * ab.1.card *
          (B.card * ab.2.card))
        : begin
            unfold simple_graph.edge_density pairs_density,
            rw sum_div,
            simp_rw div_div_eq_div_mul,
            refine finset.sum_congr rfl (λ x _, _),
            rw [mul_comm (B.card : ℝ), ←mul_assoc, ←mul_assoc, mul_comm _ (A.card : ℝ), ←mul_assoc],
          end
    ... ≤ ∑ ab in A.product B, pairs_count G.adj ab.1 ab.2/((∑ aa in A, (aa.card : ℝ))/((m + 1)/m)
          * ((∑ b in B, (b.card : ℝ))/((m + 1)/m)))
        : begin
            refine sum_le_sum (λ x hx, div_le_div_of_le_left (nat.cast_nonneg _) _ _);
            rw mem_product at hx,
            { refine mul_pos (div_pos _ m_add_one_div_m_pos)
                (div_pos _ m_add_one_div_m_pos); norm_cast,
              { exact (card_pos.2 $ finpartition_on.nonempty_of_mem_parts _ $
                hA hx.1).trans_le (single_le_sum (λ _ _, nat.zero_le _) hx.1) },
              { refine (card_pos.2 $ finpartition_on.nonempty_of_mem_parts _ $
                hB hx.2).trans_le (single_le_sum (λ _ _, nat.zero_le _) hx.2) } },
            refine mul_le_mul (sum_card_subset_chunk_increment_parts_le m_pos hA hx.1)
              (sum_card_subset_chunk_increment_parts_le m_pos hB hx.2)
              (div_nonneg _ (div_nonneg _ _)) _; norm_cast; exact nat.zero_le _,
          end
    ... = pairs_count G.adj (A.bUnion id) (B.bUnion id) /
          ((A.bUnion id).card/((m + 1)/m) * ((B.bUnion id).card/((m + 1)/m)))
        : begin
            rw [relation.pairs_count_finpartition hA.finpartition_on hB.finpartition_on,
              ←hA.finpartition_on.sum_card_parts, ←hB.finpartition_on.sum_card_parts],
            simp only [nat.cast_sum],
            rw [eq_comm, sum_div, hA.finpartition_on_parts, hB.finpartition_on_parts],
          end
    ... = ((m + 1)/m)^2 * G.edge_density (A.bUnion id) (B.bUnion id)
        : begin
            unfold simple_graph.edge_density pairs_density,
            simp only [←div_div_eq_div_mul],
            rw [div_div_eq_mul_div, div_div_eq_mul_div],
            ring,
          end
    ... ≤ (1 + ε^5/49) * G.edge_density (A.bUnion id) (B.bUnion id)
        : mul_le_mul_of_nonneg_right (m_add_one_div_m_le_one_add hPα hPε hm)
          (G.edge_density_nonneg _ _)
    ... ≤ G.edge_density (A.bUnion id) (B.bUnion id) + ε^5/49
        : begin
            rw [add_mul, one_mul],
            exact add_le_add_left (mul_le_of_le_one_right (div_nonneg hε.le (by norm_num))
              (G.edge_density_le_one _ _)) _,
          end,
end.

lemma sq_density_sub_eps_le_sum_sq_density_div_card [nonempty α] (hPα : P.size * 16^P.size ≤ card α)
  (hPε : 100 ≤ 4^P.size * ε^5) (m_pos : 0 < m) (hε₁ : ε ≤ 1)
  {U V : finset α} {hU : U ∈ P.parts} {hV : V ∈ P.parts} :
  G.edge_density U V^2 - ε^5/25 ≤
  (∑ ab in (hP.chunk_increment G ε hU).parts.product (hP.chunk_increment G ε hV).parts,
    G.edge_density ab.1 ab.2^2)/16^P.size :=
begin
  have hε : 0 < ε^5 := pos_of_mul_pos_left ((by norm_num : (0 : ℝ) < 100).trans_le hPε)
    (pow_nonneg (by norm_num) _),
  have hε₀ : 0 < ε := sorry,
  obtain hGε | hGε := le_total (G.edge_density U V) (ε^5/50),
  { calc
      G.edge_density U V^2 - ε^5/25
          ≤ G.edge_density U V - ε^5/25
          : sub_le_sub_right (sq_le (G.edge_density_nonneg _ _) (G.edge_density_le_one _ _)) _
      ... ≤ ε^5/50 - ε^5/25
          : sub_le_sub_right hGε _
      ... ≤ 0
          : sub_nonpos_of_le (div_le_div_of_le_left hε.le (by norm_num) (by norm_num))
      ... ≤ (∑ ab in (hP.chunk_increment G ε hU).parts.product (hP.chunk_increment G ε hV).parts,
              G.edge_density ab.1 ab.2^2)/16^P.size
          : div_nonneg (sum_nonneg $ λ i _, sq_nonneg _) (pow_nonneg (by norm_num) _) },
  rw ←sub_nonneg at hGε,
  calc
    G.edge_density U V^2 - ε^5/25
        ≤ G.edge_density U V^2 - ε^5/25 * G.edge_density U V
        : sub_le_sub_left (mul_le_of_le_one_right (div_nonneg hε.le (by norm_num))
            (G.edge_density_le_one _ _)) _
    ... ≤ G.edge_density U V^2 - ε^5/25 * G.edge_density U V + (ε^5/50)^2
        : le_add_of_nonneg_right (sq_nonneg _)
    ... = (G.edge_density U V - ε^5/50)^2
        : by { rw [sub_sq, mul_right_comm, mul_div_comm, div_eq_mul_inv], norm_num }
    ... = (G.edge_density ((hP.chunk_increment G ε hU).parts.bUnion id)
            ((hP.chunk_increment G ε hV).parts.bUnion id) - ε^5/50)^2
        : by rw [finpartition_on.bUnion_parts_eq, finpartition_on.bUnion_parts_eq]
    ... ≤ ((∑ ab in (hP.chunk_increment G ε hU).parts.product (hP.chunk_increment G ε hV).parts,
            G.edge_density ab.1 ab.2)/((hP.chunk_increment G ε hU).size
            * (hP.chunk_increment G ε hV).size))^2
        : pow_le_pow_of_le_left
            (by rwa [finpartition_on.bUnion_parts_eq, finpartition_on.bUnion_parts_eq])
            (density_sub_eps_le_sum_density_div_card hPα hPε m_pos set.subset.rfl set.subset.rfl) 2
    ... ≤ (∑ ab in (hP.chunk_increment G ε hU).parts.product (hP.chunk_increment G ε hV).parts,
            G.edge_density ab.1 ab.2^2)/((hP.chunk_increment G ε hU).size
            * (hP.chunk_increment G ε hV).size)
        : by convert chebyshev _ _;
            rw [card_product, nat.cast_mul, finpartition_on.size, finpartition_on.size]
    ... = (∑ ab in (hP.chunk_increment G ε hU).parts.product (hP.chunk_increment G ε hV).parts,
            G.edge_density ab.1 ab.2^2)/16^P.size
        : begin
          rw [chunk_increment.size m_pos, chunk_increment.size m_pos, ←nat.cast_mul, ←mul_pow],
          norm_cast,
        end
end

lemma abs_density_star_sub_density_le_eps [nonempty α]
  (hPα : P.size * 16^P.size ≤ card α) (hPε : 100 ≤ 4^P.size * ε^5) (m_pos : 0 < m) (hε₁ : ε ≤ 1)
  {U V : finset α} {hU : U ∈ P.parts} {hV : V ∈ P.parts}
    (hUV' : U ≠ V) (hUV : ¬ G.is_uniform ε U V) :
  |G.edge_density ((hP.star G ε hU V).bUnion id) ((hP.star G ε hV U).bUnion id) -
    G.edge_density (G.witness ε U V).fst (G.witness ε V U).fst| ≤ ε/5 :=
begin
  have hε' : 0 < ε := sorry,
  convert lemma_A G.adj
    (bUnion_star_subset_witness hP G ε hU V)
    (bUnion_star_subset_witness hP G ε hV U)
    (div_nonneg hε'.le $ by norm_num)
    (one_sub_eps_mul_card_witness_le_card_star hP G ε hU hV hUV' hUV hPε hε₁)
    (one_sub_eps_mul_card_witness_le_card_star hP G ε hV hU hUV'.symm (λ hVU, hUV hVU.symm) hPε hε₁),
  rw [mul_div_comm, div_eq_mul_one_div],
  norm_num,
end

lemma stuff [nonempty α]
  (hPα : P.size * 16^P.size ≤ card α) (hPε : 100 ≤ 4^P.size * ε^5) (m_pos : 0 < m) (hε₁ : ε ≤ 1)
  {U V : finset α} {hU : U ∈ P.parts} {hV : V ∈ P.parts} (hUV : ¬ G.is_uniform ε U V) :
  3/4 * ε ≤
    ((∑ ab in (hP.star G ε hU V).product (hP.star G ε hV U), G.edge_density ab.1 ab.2)
      / ((hP.star G ε hU V).card * (hP.star G ε hV U).card) -
        (∑ ab in (hP.chunk_increment G ε hU).parts.product (hP.chunk_increment G ε hV).parts,
          G.edge_density ab.1 ab.2^2)/16^P.size) :=
begin
  sorry
end

-- double dagger inequality
lemma sq_density_sub_eps_le_sum_sq_density_div_card_of_nonuniform [nonempty α]
  (hPα : P.size * 16^P.size ≤ card α) (hPε : 100 ≤ 4^P.size * ε^5) (m_pos : 0 < m) (hε₁ : ε ≤ 1)
  {U V : finset α} {hU : U ∈ P.parts} {hV : V ∈ P.parts} (hUV : ¬ G.is_uniform ε U V) :
  G.edge_density U V^2 - ε^5/25 + ε^4/3 ≤
  (∑ ab in (hP.chunk_increment G ε hU).parts.product (hP.chunk_increment G ε hV).parts,
    G.edge_density ab.1 ab.2^2)/16^P.size :=
begin
  calc
    G.edge_density U V^2 - ε^5/25 + ε^4/3
        ≤  G.edge_density U V^2 - ε^5/25 + (hP.star G ε hU V).card * (hP.star G ε hV U).card/16^P.size * (9/16) * ε^4
        : sorry
    ... ≤ (∑ ab in (hP.chunk_increment G ε hU).parts.product (hP.chunk_increment G ε hV).parts,
            G.edge_density ab.1 ab.2^2)/16^P.size
        : sorry
end