import Cake.Environment.FogOverrideVolume;

AFogOverrideVolume2 AddSkyFogOverrideVolume(AHazePlayerCharacter Player, AFogOverrideVolume2 Volume)
{
	AGameSky sky = GetSky();
	sky.FogOverrideVolumes.Add(Volume);
	return UpdateSkyFogOverrideBasedOnVolume();
}

AFogOverrideVolume2 RemoveSkyFogOverrideVolume(AHazePlayerCharacter Player, AFogOverrideVolume2 Volume)
{
	AGameSky sky = GetSky();
	if (sky == nullptr)
		return nullptr;
	sky.FogOverrideVolumes.Remove(Volume);
	return UpdateSkyFogOverrideBasedOnVolume();
}

AFogOverrideVolume2 UpdateSkyFogOverrideBasedOnVolume()
{
	AGameSky sky = GetSky();
	// Get volume with highest priority
	UDataAssetFog NewFog = nullptr;
	AFogOverrideVolume2 NewVolume = nullptr;
	int HighestPriority = MIN_int32;
	for(int i = 0; i < sky.FogOverrideVolumes.Num(); i++)
	{
		int CurrentPriority = sky.FogOverrideVolumes[i].Priority;
		if(CurrentPriority > HighestPriority)
		{
			HighestPriority = CurrentPriority;
			NewFog = sky.FogOverrideVolumes[i].NewFogValue;
			NewVolume = sky.FogOverrideVolumes[i];
		}
	}
	sky.SetFog(NewFog, 1.0f);
	return NewVolume;
}

AGameSky GetSky()
{
	TArray<AActor> Skies;
	Gameplay::GetAllActorsOfClass(AGameSky::StaticClass(), Skies);
	if(Skies.Num() <= 0)
		return nullptr;
	return Cast<AGameSky>(Skies[0]);
}

// Parent of BP_Sky
class AGameSky : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
    default Root.Mobility = EComponentMobility::Static;
    
	TArray<AFogOverrideVolume2> FogOverrideVolumes;

    // Implemented in blueprint.
    UFUNCTION(BlueprintEvent)
	void SetFog(UDataAssetFog FogPreset, float BlendTime = 1.0f)
    {

    }
    
    UFUNCTION()
    FLinearColor LerpColor(FLinearColor A, FLinearColor B, float Alpha)
    {
        FLinearColor Result;
        Result.R = FMath::Lerp(A.R, B.R, Alpha);
        Result.G = FMath::Lerp(A.G, B.G, Alpha);
        Result.B = FMath::Lerp(A.B, B.B, Alpha);
        Result.A = FMath::Lerp(A.A, B.A, Alpha);
        return Result;
    }

    UFUNCTION()
    FogData LerpFogData(FogData A, FogData B, float Alpha)
    {
        FogData Result;
        Result.FogDensity                               = FMath::Lerp(A.FogDensity,                                 B.FogDensity,                           Alpha);
        Result.FogDirectionalInscatteringColor          = LerpColor(A.FogDirectionalInscatteringColor,              B.FogDirectionalInscatteringColor,      Alpha);
        Result.FogDirectionalInscatteringExponent       = FMath::Lerp(A.FogDirectionalInscatteringExponent,         B.FogDirectionalInscatteringExponent,   Alpha);
        Result.FogDirectionalInscatteringStartDistance  = FMath::Lerp(A.FogDirectionalInscatteringStartDistance,    B.FogDirectionalInscatteringStartDistance,                           Alpha);
        Result.FogHeightFalloff                         = FMath::Lerp(A.FogHeightFalloff,                           B.FogHeightFalloff,                     Alpha);
        Result.FogHeightOffset                          = FMath::Lerp(A.FogHeightOffset,                            B.FogHeightOffset,                      Alpha);
        Result.FogInscatteringColor                     = LerpColor(A.FogInscatteringColor,                         B.FogInscatteringColor,                 Alpha);
        Result.FogMaxOpacity                            = FMath::Lerp(A.FogMaxOpacity,                              B.FogMaxOpacity,                        Alpha);
        Result.FogStartDistance                         = FMath::Lerp(A.FogStartDistance,                           B.FogStartDistance,                     Alpha);
        return Result;
    }

    UFUNCTION()
	void Call_SetFog(UDataAssetFog FogPreset, float BlendTime = 1.0f)
    {
        SetFog(FogPreset, BlendTime);
    }

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		if (Editor::IsCooking())
			USkyLightComponent::Get(this).SetVisibility(false);
    }
    
    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		// The skylight is hidden until the level we're in is activated
		//   This would normally be dealt with by the rendering code, but we're working around not having to change the engine right now
		Level.OnLevelActivated.AddUFunction(this, n"OnLevelActivated");
		Level.OnLevelDeactivated.AddUFunction(this, n"OnLevelDeactivated");

		if (Progress::HasActivatedAnyProgressPoint()
#if EDITOR
			|| Progress::GetActiveLevels().Num() != 0
#endif
		)
		{
			USkyLightComponent::Get(this).SetVisibility(false);
		}
    }

	UFUNCTION()
	private void OnLevelActivated()
	{
		USkyLightComponent::Get(this).SetVisibility(true);
	}

	UFUNCTION()
	private void OnLevelDeactivated()
	{
		USkyLightComponent::Get(this).SetVisibility(false);
	}

    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {

    }
}