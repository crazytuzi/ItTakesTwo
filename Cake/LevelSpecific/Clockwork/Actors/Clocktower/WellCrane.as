import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;
import Cake.LevelSpecific.Clockwork.Actors.Clocktower.LeakingWaterbucket;
import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.Clockwork.Actors.Clocktower.ClockworkFire;

event void FWellCraneSignature();
class AWellCrane : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent CraneMesh01;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent CraneMesh02;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent CraneMesh03;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HookRoot;

	UPROPERTY(DefaultComponent, Attach = HookRoot)
	UStaticMeshComponent Hook;

	UPROPERTY(DefaultComponent, Attach = HookRoot)
	UStaticMeshComponent HiddenBucketMesh;
	default HiddenBucketMesh.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent GearRoot;

	UPROPERTY(DefaultComponent, Attach = GearRoot)
	UStaticMeshComponent GearMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCableComponent CableComp;

	UPROPERTY(DefaultComponent, Attach = GearRoot)
	UTimeControlActorComponent TimeControlActorComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereCollision;

	UPROPERTY(DefaultComponent, Attach = HookRoot)
	UInteractionComponent InteractComp;

	UPROPERTY()
	FWellCraneSignature FireQuestCompletedEvent;

	UPROPERTY()
	AClockworkFire Fire;

	float FireCheckTimer;

	FVector HookInitialLocation;
	FVector HookTargetLocation;

	ALeakingWaterBucket BucketAttached = nullptr;
	bool bWaterWasFilled = false;

	bool bQuestCompleted = false;

	UPROPERTY()
	TSubclassOf<ALeakingWaterBucket> BucketClassToSpawn;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Network::SetActorControlSide(this, Game::GetCody());
		
		TimeControlActorComp.TimeIsChangingEvent.AddUFunction(this, n"TimeIsChangingEvent");
		TimeControlActorComp.TimeFullyReversedEvent.AddUFunction(this, n"TimeIsFullyReversed");
		SphereCollision.OnComponentBeginOverlap.AddUFunction(this, n"SphereOnBeginOverlap");
		InteractComp.OnActivated.AddUFunction(this, n"InteractionCompActivated");

		HookInitialLocation = HookRoot.RelativeLocation;
		HookTargetLocation = FVector(HookInitialLocation - FVector(0.f, 0.f, 350.f));

		InteractComp.Disable(n"Water");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bQuestCompleted)
			return;
		
		FireCheckTimer += DeltaTime;

		if (FireCheckTimer >= 1.f)
		{
			if (Fire.bFirePutOut)
			{
				//Temp thing
				FireQuestCompletedEvent.Broadcast();

				//Print("CallingCompleteQuest", 2.0f);
				bQuestCompleted = true;
			}

			FireCheckTimer = 0.f;
		}
	}

	UFUNCTION()
	void TimeIsChangingEvent(float NewPointInTime)
	{
		const float PointInTime = TimeControlActorComp.GetPointInTime();
		HookRoot.SetRelativeLocation(FMath::VLerp(HookInitialLocation, HookTargetLocation, FVector(PointInTime, PointInTime, PointInTime)));
		if (HasControl() && BucketAttached != nullptr && PointInTime > 0.85f && !bWaterWasFilled)
			NetFillWater();
	}

	UFUNCTION(NetFunction)
	void NetFillWater()
	{
		bWaterWasFilled = true;
	}

	UFUNCTION()
	void TimeIsFullyReversed()
	{
		if (bWaterWasFilled)
			InteractComp.Enable(n"Water");
	}

	UFUNCTION()
	void InteractionCompActivated(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		InteractComp.Disable(n"Water");
		ShowHiddenBucketMesh(false);
	
		BucketAttached.EnableActor(this);
		BucketAttached.ForcePlayerToPickupBucket(Player);
		BucketAttached.StartLeakingWater();
		BucketAttached = nullptr;
		bWaterWasFilled = false;	
	}

	UFUNCTION()
    void SphereOnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
    {
		if (BucketAttached != nullptr)
			return;

		if (TimeControlActorComp.PointInTime > 0.4f)
			return;

		ALeakingWaterBucket Bucket = Cast<ALeakingWaterBucket>(OtherActor);
		if(Bucket == nullptr)
			return;
		
		if(Bucket.PlayerHoldingBucket == nullptr)
			return;

		if(!Bucket.PlayerHoldingBucket.HasControl())
			return;

		UBoxComponent Box = Cast<UBoxComponent>(OtherComponent);
		if(Box == nullptr)
			return;

		if(Bucket.bEverHadWater)
			return;

		NetAttachBucketToWellCrane(Bucket);
    }

	UFUNCTION(NetFunction)
	void NetAttachBucketToWellCrane(ALeakingWaterBucket Bucket)
	{
		Bucket.ForcePlayerToDropBucket();
		Bucket.DisableActor(this);
		ShowHiddenBucketMesh(true);
		BucketAttached = Bucket;
	}


	void ShowHiddenBucketMesh(bool bShow)
	{
		HiddenBucketMesh.SetHiddenInGame(!bShow);
	}
}