class AMovingPillow : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent PillowMesh;

	UPROPERTY(DefaultComponent, Attach = PillowMesh)
	USceneComponent AttachComponent;

    UPROPERTY()
    FHazeTimeLike MovePillowTimeline;

    UPROPERTY(meta = (MakeEditWidget))
    FVector StartingLocation;

    UPROPERTY()
    bool bShowStartLocation;

    UPROPERTY()
    TArray<UMaterialInstance> MaterialArray;

    UPROPERTY()
    bool bMaterialOverride;

    UPROPERTY()
    UMaterialInstance OtherMaterial;

	UPROPERTY()
	AActor ActorToAttach;

	UPROPERTY()
	bool bPlayRumbleAndCamShake = true;

	UPROPERTY()
	UForceFeedbackEffect MoveFinishedForceFeedback;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> MoveFinishedCameraShake;

	bool bPlayedRumbleAndCamShake = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		if (ActorToAttach != nullptr)
			ActorToAttach.AttachToComponent(AttachComponent, n"", EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
        
		
		MovePillowTimeline.BindUpdate(this, n"MovePillowTimelineUpdate");
        MovePillowTimeline.BindFinished(this, n"MovePillowTimelineFinished");

        PillowMesh.SetRelativeLocation(StartingLocation);

    }

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        if (!bMaterialOverride)
            PillowMesh.SetMaterial(0, MaterialArray[FMath::RandRange(0, MaterialArray.Num() - 1)]);
        else   
         PillowMesh.SetMaterial(0, OtherMaterial); 

        if (bShowStartLocation)
            PillowMesh.SetRelativeLocation(StartingLocation);

        else
            PillowMesh.SetRelativeLocation(FVector::ZeroVector);
    }

    UFUNCTION()
    void TeleportPillow()
    {
        PillowMesh.SetRelativeLocation(FVector::ZeroVector);
    }

    UFUNCTION()
    void MovePillow(float TimelineDuration)
    {
        MovePillowTimeline.SetPlayRate(1 / TimelineDuration);
        MovePillowTimeline.PlayFromStart();
    }

    UFUNCTION()
    void MovePillowTimelineUpdate(float CurrentValue)
    {
        PillowMesh.SetRelativeLocation(FVector(FMath::VLerp(StartingLocation, FVector::ZeroVector, FVector(CurrentValue, CurrentValue, CurrentValue))));

		if (CurrentValue >= 0.95f && bPlayRumbleAndCamShake)
			PlayRumbleAndCamShake();
    }

    UFUNCTION()
    void MovePillowTimelineFinished(float CurrentValue)
    {

    }

	void PlayRumbleAndCamShake()
	{
		if (bPlayedRumbleAndCamShake)
			return;

		bPlayedRumbleAndCamShake = true;
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.PlayCameraShake(MoveFinishedCameraShake, 1.f);
			Player.PlayForceFeedback(MoveFinishedForceFeedback, false, true, n"KaleidoscopePlatform");
		}
	}
}