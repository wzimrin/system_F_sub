Require Import SfLib.
Require Import util.
Require Import Permutation.
Require Import STLC_types.
Require Import STLC_terms.
Require Import STLC_has_type.
Require Import STLC_step.

Theorem progress : forall t T, 
     has_type empty t T ->
     value t \/ exists t', t ==> t'.
Proof with eauto.
  intros t T Ht.
  remember empty as gamma.
  has_type_cases (induction Ht) Case; subst... 
  Case "T_Var". inversion H.
  Case "T_App". right. destruct IHHt1...
    SCase "t1 is a value". destruct IHHt2...
      SSCase "t2 is a value".
        apply canonical_forms_lambda with (A := T11) (R := T12) in Ht1...
        inversion Ht1. inversion H1. inversion H2. subst.
        exists ([x := t2] x1). constructor...
      SSCase "t2 steps". inversion H0. exists (TApp t1 x). constructor...
    SCase "t1 steps". inversion H. exists (TApp x t2). constructor...
  Case "T_If". right. destruct IHHt1...
    SCase "t1 is a value". apply canonical_forms_bool in Ht1...
      destruct Ht1; subst.
      SSCase "if true". exists t2. constructor.
      SSCase "if false". exists t3. constructor.
    inversion H. exists (TIf x t2 t3). constructor...
  Case "T_Plus". right. destruct IHHt1... destruct IHHt2...
    apply canonical_forms_nat in Ht1...
    apply canonical_forms_nat in Ht2...
    inversion Ht1... inversion Ht2... subst.
    exists (TNum (x+x0))...
    inversion H0. exists (TPlus l x)...
    inversion H. exists (TPlus x r)...
  Case "T_EqNat". right. destruct IHHt1... destruct IHHt2...
    apply canonical_forms_nat in Ht1...
    apply canonical_forms_nat in Ht2...
    inversion Ht1... inversion Ht2... subst.
    remember (beq_nat x x0). destruct b. exists TTrue...
    exists TFalse...
    inversion H0. exists (TEqNat l x)...
    inversion H. exists (TEqNat x r)...
  Case "T_Literal". generalize dependent li.
    induction H2; intros; subst...
    SCase "Inductive".
      destruct H...
      SSCase "value x".
        destruct li; simpl in *; try solve by inversion.
        inversion H3; subst.
        inversion H0. inversion H1. inversion H4.
        destruct (IHForall2 H10 li H6 H7 H12)...
        SSSCase "value TLiteral".
          left. (* (TLiteral ((i0, t) :: l)) is a value *)
          apply v_literal; simpl.
          apply Forall_cons...
          inversion H13...
        SSSCase "exists t' : TLiteral ==> t'".
          right. inversion H13; subst. inversion H14; subst.
          exists (TLiteral (i :: li0 ++ i0 :: ri) (x :: lv ++ v' :: rv)).
          assert (Uniq (i :: li0)).
            SSSSCase "Proof of assertion".
              destruct (@uniq_app id (i :: li0) (i0 :: ri))...
          apply ST_Literal with (li := (i :: li0)) (lv := x :: lv)...
            (* first prove that (TLiteral ((i0, t) :: l0)) is a value *)
              apply v_literal. constructor...
              inversion H15... simpl. rewrite H16...
      SSCase "exists t' : x ==> t'".
        right. inversion H. destruct li; simpl in *; try solve by inversion.
        exists (TLiteral (i :: li) (x0 :: l)).
        apply ST_Literal with (lv := nil) (li := nil) (v := x) (v' := x0)...
  Case "T_Access".
    destruct IHHt...
    SCase "TLiteral is a value". right. eapply record_type_info in Ht...
      inversion Ht. apply in_lookup in H...
    SCase "TLiteral setps". right. inversion H1. exists (TAccess x i)...
Qed.

Inductive appears_free_in : id -> term -> Prop :=
| AFI_Var : forall x,
              appears_free_in x (TVar x)
| AFI_App1 : forall x t1 t2,
               appears_free_in x t1 -> appears_free_in x (TApp t1 t2)
| AFI_App2 : forall x t1 t2,
               appears_free_in x t2 -> appears_free_in x (TApp t1 t2)
| AFI_Lambda : forall x y T11 t12,
                 y <> x ->
                 appears_free_in x t12 ->
                 appears_free_in x (TLambda y T11 t12)
| AFI_If1 : forall x t1 t2 t3,
              appears_free_in x t1 ->
              appears_free_in x (TIf t1 t2 t3)
| AFI_If2 : forall x t1 t2 t3,
              appears_free_in x t2 ->
              appears_free_in x (TIf t1 t2 t3)
| AFI_If3 : forall x t1 t2 t3,
              appears_free_in x t3 ->
              appears_free_in x (TIf t1 t2 t3)
| AFI_Plus1 : forall x l r,
                appears_free_in x l ->
                appears_free_in x (TPlus l r)
| AFI_Plus2 : forall x l r,
                appears_free_in x r ->
                appears_free_in x (TPlus l r)
| AFI_EqNat1 : forall x l r,
                appears_free_in x l ->
                appears_free_in x (TEqNat l r)
| AFI_EqNat2 : forall x l r,
                appears_free_in x r ->
                appears_free_in x (TEqNat l r)
| AFI_Record : forall x id t leftI rightI leftT rightT,
                 appears_free_in x t ->
                 appears_free_in x (TLiteral (leftI ++ id :: rightI) (leftT ++ t :: rightT))
| AFI_Access : forall x t id,
                 appears_free_in x t ->
                 appears_free_in x (TAccess t id).

Tactic Notation "afi_cases" tactic(first) ident(c) :=
  first;
  [ Case_aux c "AFI_Var"    | Case_aux c "AFI_App1"
  | Case_aux c "AFI_App2"   | Case_aux c "AFI_Lambda"
  | Case_aux c "AFI_If1"    | Case_aux c "AFI_If2"
  | Case_aux c "AFI_If3"    | Case_aux c "AFI_Plus1"
  | Case_aux c "AFI_Plus2"  | Case_aux c "AFI_EqNat1"
  | Case_aux c "AFI_EqNat2" | Case_aux c "AFI_Record"
  | Case_aux c "AFI_Access" ].

Hint Constructors appears_free_in.

Definition closed (t:term) := forall x, ~ appears_free_in x t.

Lemma free_in_context : forall x t T gamma,
                          appears_free_in x t ->
                          has_type gamma t T ->
                          exists T', gamma x = Some T'.
Proof with eauto.
  intros x t T gamma H H0. generalize dependent gamma.
  generalize dependent T.
  afi_cases (induction H) Case; intros.
  (* try (try remember (TVar x); try remember (TApp t1 t2);
   try remember (TLambda y T11 t12); try remember (TIf t1 t2 t3);
   try remember (TPlus l r); induction H0; inversion Heqt; subst; eauto).*)
    Case "AFI_Var".
      remember (TVar x).
      has_type_cases (induction H0) SCase; inversion Heqt; subst...
    Case "AFI_App1". remember (TApp t1 t2).
      has_type_cases (induction H0) SCase; inversion Heqt; subst...
    Case "AFI_App2". remember (TApp t1 t2).  induction H0; inversion Heqt; subst...
    Case "AFI_Lambda".
      remember (TLambda y T11 t12).
      has_type_cases (induction H1) SCase; inversion Heqt; subst...
      SCase "T_Lambda". apply IHappears_free_in in H1.
        apply not_eq_beq_id_false in H. rewrite extend_neq in H1; assumption.
    Case "AFI_If1".
      remember (TIf t1 t2 t3); induction H0; inversion Heqt; subst...
    Case "AFI_If2".
      remember (TIf t1 t2 t3); induction H0; inversion Heqt; subst...
    Case "AFI_If3".
      remember (TIf t1 t2 t3); induction H0; inversion Heqt; subst...
    Case "AFI_Plus1".
      remember (TPlus l r); induction H0; inversion Heqt; subst...
    Case "AFI_Plus2".
      remember (TPlus l r); induction H0; inversion Heqt; subst...
    Case "AFI_EqNat1".
      remember (TEqNat l r); induction H0; inversion Heqt; subst...
    Case "AFI_EqNat2".
      remember (TEqNat l r); induction H0; inversion Heqt; subst...
    Case "AFI_Record".
      remember (TLiteral (leftI ++ id :: rightI) (leftT ++ t :: rightT)).
      induction H0; inversion Heqt0; subst...
      apply Forall2_app_inv_l in H4. inversion H4.
      inversion H5. inversion H6. inversion H8. inversion H9. subst.
      apply IHappears_free_in with (T := y). assumption.
    Case "AFI_Access".
      remember (TAccess t id).
      induction H0; inversion Heqt0; subst...
Qed.

Lemma context_invariance : forall gamma gamma' t T,
                             has_type gamma t T ->
                             (forall x, appears_free_in x t -> gamma x = gamma' x) ->
                             has_type gamma' t T.
Proof with eauto.
  intros.
  generalize dependent gamma'.
  has_type_cases (induction H) Case; intros; try solve [auto].
  Case "T_Var". apply T_Var. rewrite <- H0...
  Case "T_Lambda". apply T_Lambda. apply IHhas_type. intros x0 Hafi.
    unfold SfLib.extend. remember (beq_id x x0). destruct b...
  Case "T_App".
    eapply T_App...
  Case "T_Literal".
    eapply T_Literal... generalize dependent li. induction H2; intros...
    SCase "Inductive". destruct li; try solve by inversion.
      constructor... apply H. intros. apply H5.
      apply AFI_Record with (leftI := nil) (leftT := nil)...
      inversion H3; subst. eapply IHForall2... intros.
      inversion H4. apply H10. intros. apply H5.
      inversion H6.
      apply AFI_Record with (leftI := i :: leftI)
                              (leftT := x :: leftT)
                              (rightI := rightI)
                              (rightT := rightT)...
  Case "T_Access". eapply T_Access...
  Case "T_Subtype". apply IHhas_type in H0. apply T_Subtype with (T := T)...
Qed.

Lemma combine_map {A} {B} {C} : forall (f : B -> C) (l1 : list A) (l2 : list B),
                                  combine l1 (map f l2) = map (fun p =>
                                                                 (fst p, f (snd p)))
                                                              (combine l1 l2).
Proof with auto.
  intros f l1. induction l1; intros; simpl...
  Case "Inductive". destruct l2... simpl. rewrite IHl1...
Qed.

Lemma substitution_preserves_typing : forall gamma x U t t' T,
                                        has_type (extend gamma x U) t T ->
                                        has_type empty t' U ->
                                        has_type gamma ([x:=t']t) T.
Proof with eauto.
  intros gamma x U t t' T Ht Ht'.
  generalize dependent gamma. generalize dependent T.
  term_cases (induction t) Case; intros T gamma H'; remember (extend gamma x U).
  (* ; inversion H'; subst; simpl...*)
  Case "TVar". rename i into y.
  remember (TVar y).
  induction H'; inversion Heqt; subst; simpl...
  remember (beq_id x y) as e. destruct e.
    SCase "x=y". apply beq_id_eq in Heqe. subst. rewrite extend_eq in H.
      inversion H. subst. eapply context_invariance... intros x Hcontra.
      destruct (free_in_context _ _ T empty Hcontra)... inversion H0.
    SCase "x<>y". constructor. rewrite extend_neq in H...
  Case "TApp".
    remember (TApp t1 t2); induction H'; inversion Heqt; subst; simpl...
  Case "TLambda". rename i into y.
    remember (TLambda y t t0). induction H'; inversion Heqt1; subst; simpl...
    apply T_Lambda. remember (beq_id x y) as e. destruct e.
    SCase "x=y". eapply context_invariance... apply beq_id_eq in Heqe. subst.
      intros x Hafi. unfold SfLib.extend. remember (beq_id y x) as e. destruct e...
    SCase "x<>y".
      apply IHt. eapply context_invariance... intros z Hafi. unfold extend.
      remember (beq_id y z) as e0. destruct e0...
      apply beq_id_eq in Heqe0. subst.
      rewrite <- Heqe...
  Case "TLiteral". constructor... generalize dependent li. generalize dependent lt.
    induction H; intros.
    SCase "base". inversion H2. constructor.
    SCase "inductive". destruct lt; try solve by inversion. constructor.
      inversion H2. apply H...
      inversion H2. destruct li; try solve by inversion. inversion H3.
      apply IHForall with (li := li)...
      rewrite map_length...
  Case "TAccess".
    eapply T_Access with (v := subst x t' v)... inversion H1. subst.
    rewrite combine_map. apply in_map_iff. exists (i,v)...
Qed.

Lemma combine_3 {A B C} : forall (x : A) (y : B) (z : C) xs ys zs,
                    In (x,y) (combine xs ys) ->
                    In (x,z) (combine xs zs) ->
                    Uniq xs ->
                    In (y,z) (combine ys zs).
Proof with auto.
  induction xs.
  Case "base". simpl in *. intros. inversion H.
  Case "inductive". intros. destruct ys; try solve by inversion.
    destruct zs; try solve by inversion. simpl in *.
    inversion H; inversion H0; try solve by inversion.
    inversion H2; inversion H3; subst.
    left...
    inversion H2; subst. inversion H1. subst.
    contradict H6. apply (in_combine_l xs zs x z)...
    inversion H3; subst. inversion H1. subst.
    contradict H6. apply (in_combine_l xs ys x y)...
    right. inversion H1. apply IHxs...
Qed.

Lemma Forall2_combine_in {A B} : forall P (x : A) (y : B) xs ys,
                                   In (x,y) (combine xs ys) ->
                                   Forall2 P xs ys ->
                                   P x y.
Proof with auto.
  intros. induction H0; try solve by inversion.
  Case "Inductive". simpl in H.  inversion H...
  inversion H2; subst...
Qed.

Lemma combine_app {A B} : forall l1 l2 l3 l4 (x : A) (y : B),
                      length l1 = length l2 ->
                      (combine l1 l2) ++ (@combine A B l3 l4) = combine (l1 ++ l3) (l2 ++ l4).
Proof with auto.
  intros. inversion H.
  generalize dependent l2.
  induction l1; intros; destruct l2; try solve by inversion...
  Case "Inductive". simpl. rewrite IHl1...
Qed.  

Theorem preservation : forall t t' T,
                         has_type empty t T ->
                         t ==> t' ->
                         has_type empty t' T.
Proof with eauto.
  remember empty as gamma.
  intros t t' T HT. generalize dependent t'.
  has_type_cases (induction HT) Case;
    intros t' HE; subst;  
       try solve [inversion HE; subst; auto].
  Case "T_App".
    inversion HE; subst...
    (* Most of the cases are immediate by induction, 
       and eauto takes care of them *)
    SCase "ST_AppAbs".
      apply substitution_preserves_typing with T11...
      inversion HT1...
  Case "T_Literal". inversion HE; subst. constructor...
    SCase "types match up". generalize dependent lt. generalize dependent li0.
      induction lv0; intros.
      SSCase "Base". simpl in *.
        destruct lt; try solve by inversion...
        constructor...
        inversion H2. subst. apply H10...
        inversion H3...
      SSCase "Inductive". destruct li0; try solve by inversion.
        destruct lt; try solve by inversion. constructor...
        inversion H3... inversion H6. inversion H5. eapply IHlv0...
        inversion H1...
        inversion H2...
        inversion H3...
        rewrite app_length in *. rewrite app_length in * ... 
  Case "T_Access". inversion HE; subst... inversion HT; subst.
    SCase "literal is value".
      apply lookup_in_pair in H6... 
      apply Forall2_combine_in with (xs := lv) (ys := lt)...
      apply combine_3 with (xs := li) (x := i)...
    SCase "literal steps". inversion H4; subst. apply IHHT in H4...
      inversion H4. subst.
      remember (beq_id i i0); destruct b...
      SSCase "i=i0". apply beq_id_eq in Heqb; subst.
        apply T_Access with (v := v') (lt := lt)...
        rewrite <- combine_app... apply in_or_app. right. simpl...
      SSCase "i!=i0". apply T_Access with (v := v) (lt := lt)...
        rewrite <- combine_app... rewrite <- combine_app in H...
        apply in_or_app... apply in_app_or in H. inversion H...
        right. simpl in *. right. inversion H1... inversion H2. subst.
        rewrite <- beq_id_refl in Heqb. inversion Heqb.
Qed.

Definition normal_form {X:Type} (R:relation X) (t:X) : Prop :=
  ~ exists t', R t t'.
  

Definition stuck (t : term) : Prop :=
  (normal_form step) t /\ ~ value t.

Corollary soundness : forall t t' T,
  has_type empty t T -> 
  t ==>* t' ->
  ~(stuck t').
Proof with auto.
  intros t t' T Hhas_type Hmulti. unfold stuck.
  intros [Hnf Hnot_val]. unfold normal_form in Hnf.
  multi_cases (induction Hmulti) Case.
  Case "multi_refl".
    apply progress in Hhas_type. inversion Hhas_type...
  Case "multi_step".
    apply preservation with (t' := y) in Hhas_type...