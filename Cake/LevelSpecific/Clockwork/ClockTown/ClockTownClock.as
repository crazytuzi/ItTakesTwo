class AClockTownClock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent ClockMesh;
	default ClockMesh.SetCollisionProfileName(n"BlockAll");

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent HourHand;
	default HourHand.SetCollisionProfileName(n"BlockOnlyPlayerCharacter");

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MinuteHand;
	default MinuteHand.SetCollisionProfileName(n"BlockOnlyPlayerCharacter");

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;
	
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ClockTickingAudioEvent;

	float HourHandRotationRate = 0.f;
	float MinuteHandRotationRate = 0.f;
	float MinRotationRate = 25.f;
	float MaxRotationRate = 80.f;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		ClockMesh.SetCullDistance(Editor::GetDefaultCullingDistance(ClockMesh) * CullDistanceMultiplier);
		HourHand.SetCullDistance(Editor::GetDefaultCullingDistance(HourHand) * CullDistanceMultiplier);
		MinuteHand.SetCullDistance(Editor::GetDefaultCullingDistance(MinuteHand) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickInterval(FMath::RandRange(0.f, 0.1f));

		HourHandRotationRate = FMath::RandRange(MinRotationRate, MaxRotationRate);
		bool bHourHandRotationDir = FMath::RandBool();
		HourHandRotationRate = bHourHandRotationDir ? HourHandRotationRate : HourHandRotationRate * -1.f;

		MinuteHandRotationRate = FMath::RandRange(MinRotationRate, MaxRotationRate);
		bool bMinuteHandRotationDir = FMath::RandBool();
		MinuteHandRotationRate = bMinuteHandRotationDir ? MinuteHandRotationRate : MinuteHandRotationRate * -1.f;

		HazeAkComp.HazePostEvent(ClockTickingAudioEvent);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(ClockMesh.WasRecentlyRendered())
		{
			SetActorTickInterval(0.f);
			HourHand.AddLocalRotation(FRotator(0.f, 0.f, HourHandRotationRate * DeltaTime));
			MinuteHand.AddLocalRotation(FRotator(0.f, 0.f, MinuteHandRotationRate * DeltaTime));	
		}
		else
		{
			SetActorTickInterval(0.1f);
		}
	}
}