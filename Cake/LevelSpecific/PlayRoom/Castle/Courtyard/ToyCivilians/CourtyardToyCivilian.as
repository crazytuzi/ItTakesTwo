class ACourtyardToyCivilian : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent ToyCivilianAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent IdleAudioEvent;

	UPROPERTY(DefaultComponent, Attach = Root, ShowOnActor)
	UHazeSkeletalMeshComponentBase SkeletalMesh;
	default SkeletalMesh.bComponentUseFixedSkelBounds = true;
	default SkeletalMesh.bEnableUpdateRateOptimizations = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent Capsule;
	default Capsule.CollisionProfileName = n"BlockOnlyPlayerCharacter";
	default Capsule.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 6000.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ToyCivilianAkComp.HazePostEvent(IdleAudioEvent);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Capsule.SetRelativeLocation(FVector(0.f, 0.f, Capsule.CapsuleHalfHeight));
	}
}