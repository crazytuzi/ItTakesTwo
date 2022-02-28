import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetIceSkatingMagnetComponent;

class AIceSkatingMagnet : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UMagnetIceSkatingMagnetComponent IceSkatingMagnetComponentCody;

	UPROPERTY(DefaultComponent, Attach = Root)
	UMagnetIceSkatingMagnetComponent IceSkatingMagnetComponentMay;

	UPROPERTY()
	TSubclassOf<UHazeCapability> RequiredCapability;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		//Capability::AddPlayerCapabilityRequest(RequiredCapability.Get());
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		//Capability::RemovePlayerCapabilityRequest(RequiredCapability.Get());
	}
}