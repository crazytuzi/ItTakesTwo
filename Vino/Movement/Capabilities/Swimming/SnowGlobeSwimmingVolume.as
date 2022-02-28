import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;

event void FOnSwimmingVolumeEntered(AHazePlayerCharacter Player);
event void FOnSwimmingVolumeExited(AHazePlayerCharacter Player);

class ASnowGlobeSwimmingVolume : APostProcessVolume
{		
	UPROPERTY()
	TSubclassOf<USnowGlobeSwimmingComponent> SwimmingComponent = Asset("/Game/Blueprints/LevelSpecific/SnowGlobe/Swimming/CBP_SnowGlobeSwimming.CBP_SnowGlobeSwimming_C");

	UPROPERTY()
	UHazeCapabilitySheet PlayerSheet = Asset("/Game/Blueprints/LevelSpecific/SnowGlobe/Swimming/SwimmingSheet.SwimmingSheet");

	UPROPERTY()
	FOnSwimmingVolumeEntered OnSwimmingVolumeEntered;
	UPROPERTY()
	FOnSwimmingVolumeExited OnSwimmingVolumeExited;

	// Post Process Volume Settings
	default Priority = 2.f;
	default BlendRadius = 0.f;

	// DoF
	// Depth of field method is no longer a thing (LUCAS)
	//default Settings.SetbOverride_DepthOfFieldMethod(true);
	///default Settings.DepthOfFieldMethod = EDepthOfFieldMethod::DOFM_Gaussian;
	default Settings.SetbOverride_DepthOfFieldNearTransitionRegion(true);
	default Settings.DepthOfFieldNearTransitionRegion = 15000.f;
	default Settings.SetbOverride_DepthOfFieldFarTransitionRegion(true);
	default Settings.DepthOfFieldFarTransitionRegion = 300000.f;

	// Exposure
	default Settings.SetbOverride_AutoExposureMinBrightness(true);
	default Settings.AutoExposureMinBrightness = 0.3f;
	default Settings.SetbOverride_AutoExposureMaxBrightness(true);
	default Settings.AutoExposureMaxBrightness = 0.8f;

	// White Balance
	default Settings.SetbOverride_WhiteTemp(true);
	default Settings.WhiteTemp = 9500.f;

	// Misc
	default Settings.SetbOverride_SceneColorTint(true);
	default Settings.SceneColorTint = FLinearColor(0.086459f, 0.673229f, 1.f);		

	default BrushComponent.SetCollisionProfileName(n"Trigger");

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		BrushComponent.OnComponentBeginOverlap.AddUFunction(this, n"BrushBeginOverlap");
		BrushComponent.OnComponentEndOverlap.AddUFunction(this, n"BrushEndOverlap");

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			auto SwimmingComp = Cast<USnowGlobeSwimmingComponent>(Player.GetOrCreateComponent(SwimmingComponent.Get()));
			Reset::RegisterPersistentComponent(SwimmingComp);

			Capability::AddPlayerCapabilitySheetRequest(PlayerSheet, Players = EHazeSelectPlayer(Player.Player));
		}

		// When spawning, a player won't trigger any overlap notifies (e.g. if a level containing this volume is streamed in and an activator is standing inside it) 
		// Trigger begin overlap events on any actors we currently overlap
		TArray<UPrimitiveComponent> OverlappingComps;
		GetOverlappingComponents(OverlappingComps);
		for (UPrimitiveComponent Overlap : OverlappingComps)
		{
			if ((Overlap != nullptr) && (Overlap.GetOwner() != nullptr))
				BrushBeginOverlap(BrushComponent, Overlap.GetOwner(), Overlap, -1, false, FHitResult());
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			auto SwimmingComp = Cast<USnowGlobeSwimmingComponent>(Player.GetComponent(SwimmingComponent.Get()));
			if (SwimmingComp != nullptr)
				Reset::UnregisterPersistentComponent(SwimmingComp);

			Capability::RemovePlayerCapabilitySheetRequest(PlayerSheet, Players = EHazeSelectPlayer(Player.Player));
		}
	}

	UFUNCTION()
	void BrushBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		USnowGlobeSwimmingComponent SwimComp = USnowGlobeSwimmingComponent::Get(Player);
		if (SwimComp == nullptr)
			return;

		SwimComp.EnteredSwimmingVolume();
		OnSwimmingVolumeEntered.Broadcast(Player);
	}

	UFUNCTION()
    void BrushEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		USnowGlobeSwimmingComponent SwimComp = USnowGlobeSwimmingComponent::Get(Player);
		if (SwimComp == nullptr)
			return;

		SwimComp.LeftSwimmingVolume();
		OnSwimmingVolumeExited.Broadcast(Player);
	}
}