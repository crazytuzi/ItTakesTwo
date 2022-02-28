event void FOnIceSkatingImpact(AHazePlayerCharacter Player, FHitResult Hit, FVector HitVelocity);

UCLASS(hidecategories="StaticMesh Materials Physics  Collision Lighting Physics Activation Cooking Replication Input Actor HLOD Mobile AssetUserData")
class UIceSkatingImpactResponseComponent : UActorComponent
{
	UPROPERTY(Category = "ImpactResponse")
	FOnIceSkatingImpact OnHardImpact;

	UPROPERTY(Category = "ImpactResponse")
	FOnIceSkatingImpact OnSoftImpact;
}