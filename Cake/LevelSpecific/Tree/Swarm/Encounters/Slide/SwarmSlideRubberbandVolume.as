import Cake.LevelSpecific.Tree.Swarm.SwarmActor;

// UCLASS(HideCategories = "Activation Collision Cooking BrushSettings Actor HLOD Mobile Replication LOD AssetUserData")
UCLASS()
class ASwarmSlideRubberbandVolume : AVolume
{
	UPROPERTY()
	USwarmSlideComposeableRubberbandSettings RubberbandSettings = nullptr;

    UPROPERTY(DefaultComponent)
    UBillboardComponent Billboard;
	default Billboard.Sprite = Asset("/Game/Editor/EditorBillboards/WindManager.Windmanager");
	default Billboard.bIsEditorOnly = true;
	default Billboard.bHiddenInGame = true;
#if EDITOR
	default Billboard.bUseInEditorScaling = true;
#endif

	// is filled out, then it will only trigger for those swarms.
	UPROPERTY()
	TArray<ASwarmActor> SpecificSwarms;

    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
		ASwarmActor OverlappedSwarm = Cast<ASwarmActor>(OtherActor);
		if(OverlappedSwarm == nullptr)
			return;

		if(SpecificSwarms.Num() != 0 && !SpecificSwarms.Contains(OverlappedSwarm))
			return;

//		PrintToScreen("Applying settings for: " + OverlappedSwarm.GetName(), Duration = 1.f);
		OverlappedSwarm.ApplySettings(RubberbandSettings, this);
    }

    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
		ASwarmActor OverlappedSwarm = Cast<ASwarmActor>(OtherActor);
		if(OverlappedSwarm == nullptr)
			return;

		if(SpecificSwarms.Num() != 0 && !SpecificSwarms.Contains(OverlappedSwarm))
			return;

//		PrintToScreen("Clearing settings for: " + OverlappedSwarm.GetName(), Duration = 1.f);
		OverlappedSwarm.ClearSettingsByInstigator(this);
    }
}

//UCLASS(Abstract, meta = (ComposeSettingsOnto = "USwarmSlideComposeableRubberbandSettings"))
UCLASS(meta = (ComposeSettingsOnto = "USwarmSlideComposeableRubberbandSettings"))
class USwarmSlideComposeableRubberbandSettings : UHazeComposableSettings
{
	/* ideal distance from the location of the furthermost 
		player on spline, in the splines forward direction. */
	UPROPERTY(Category = "Rubberband settings")
	float IdealDistance = 13000.f;

	// Distance at which the AheadSpeedMultiplier reaches its full potential
	UPROPERTY(Category = "Rubberband settings")
	float AheadDistance = 4000.f;

	// SpeedMultiplier used when being ahead of the ideal location (player.pos + offset) on the spline
	UPROPERTY(Category = "Rubberband settings")
	float AheadSpeedMultiplier = 0.5f;

	// Distance at which the BehindSpeedMultiplier reaches its full potential
	UPROPERTY(Category = "Rubberband settings")
	float BehindDistance = 2000.f;

	// SpeedMultiplier used when being behind the ideal location (player.pos + offset) on the spline
	UPROPERTY(Category = "Rubberband settings")
	float BehindSpeedMultiplier = 3.f;

//  	UPROPERTY(Category = "Rubberband settings")
//	FSwarmSlideRubberbandSetting Settings;
};

// struct FSwarmSlideRubberbandSetting
// {
// };