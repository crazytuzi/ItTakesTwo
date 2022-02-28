UCLASS(hidecategories="StaticMesh Materials Physics  Collision Lighting Physics Activation Cooking Replication Input Actor HLOD Mobile AssetUserData")
class UIceSkatingForceImpactComponent : UActorComponent
{
	UPROPERTY(Category = "ImpactType")
	bool bIsHardImpact = false;
}