class UGrindingEffectsData : UDataAsset
{
	/* Grapple */
	// Effect that spawns on the grind rail at the grapple location
	UPROPERTY(Category = "Enter")
	UNiagaraSystem GrappleEffectAtGrapplePoint;

	/* Grinding */
	// Constant effect at the feet of the player while grinding
	UPROPERTY(Category = "Grind")
	UNiagaraSystem GrindEffect;
}