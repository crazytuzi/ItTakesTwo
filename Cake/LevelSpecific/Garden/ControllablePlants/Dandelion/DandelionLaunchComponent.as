
UCLASS(hidecategories = "Activation AssetUserData")
class UDandelionLaunchComponent : UActorComponent
{
	UPROPERTY(Category = "Dandelion", meta = (DisplayName = "Launch Height"))
	protected float _LaunchHeight = 3500.0f;
	
	// Time it takes to reach the designated height (LaunchPower)
	UPROPERTY(Category = "Dandelion", meta = (DisplayName = "Launch Time"))
	protected float _LaunchTime = 1.0f;

	float GetLaunchHeight() const property { return _LaunchHeight; }
	float GetLaunchTime() const property { return _LaunchTime; }
}
