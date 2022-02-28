
// Data specific for the hammer encounter

UCLASS(HideCategories = "Cooking ComponentReplication Tags Sockets Clothing ClothingSimulation AssetUserData Mobile MeshOffset Collision Activation")
class USwarmHammerComponent : UActorComponent
{
	UPROPERTY(BlueprintReadWrite, Category = "Ultimate")
	AActor HammerUltimateTargetPoint;
}