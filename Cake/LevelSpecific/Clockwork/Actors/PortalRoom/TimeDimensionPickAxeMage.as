import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;

event void FTimeDimensionPickAxeMageSignature();

class ATimeDimensionPickAxeMage : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = RightHand)
	UStaticMeshComponent PickAxeMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UTimeControlActorComponent TimeComp;

	UPROPERTY()
	FTimeDimensionPickAxeMageSignature FastScrubEvent;

	UPROPERTY()
	float CurrentPointInTime = 1.f;

	float FastScrubTimer = 99.f;
	float FastScrubTimerMax = 0.5f;

	bool bHasFiredEvent = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TimeComp.TimeIsChangingEvent.AddUFunction(this, n"TimeIsChanging");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (CurrentPointInTime < 0.1f)
		{
			FastScrubTimer = 0.f;
			bHasFiredEvent = false;
		} else 
		{
			FastScrubTimer += DeltaTime;

			if (FastScrubTimer <= FastScrubTimerMax && CurrentPointInTime == 1.f && !bHasFiredEvent)
			{
				bHasFiredEvent = true;
				FastScrubEvent.Broadcast();
			}
		}
	}

	UFUNCTION()
	void TimeIsChanging(float NewPointInTime)
	{
		CurrentPointInTime = NewPointInTime;
	}
}