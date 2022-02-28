
enum EPlaneFightHitReactionValidationType
{
	// Normal validation
	Default,

	// Only valid if this is the impact that takes us into the finishhim state
	KillingBlow,
}


class ULocomotionFeaturePlaneFightHitReaction : ULocomotionFeatureMeleeFightHitReaction
{
	default Tag = n"MeleeHitReaction";

	UPROPERTY(Category = "Validation")
	EPlaneFightHitReactionValidationType ValidationType = EPlaneFightHitReactionValidationType::Default;

	UPROPERTY(Category = "Validation")
	FHazeMeleeActionValidation Validation;

	UPROPERTY(Category = "Validation")
	TArray<UHazeMeleeImpactAsset> AnyValidImpactFeature;

	// The amount that the victim will travel upwards with
	UPROPERTY(Category = "Translation")
	float VictimVerticalUpForce = 0;
};