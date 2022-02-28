import Peanuts.Spline.SplineComponent;
import Peanuts.ButtonMash.Progress.ButtonMashProgress;

event void FOnSpaceWeightLanded();

UCLASS(Abstract)
class ASpaceWeightSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
	UStaticMeshComponent SpawnerMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent WeightRoot;

	UPROPERTY(DefaultComponent, Attach = WeightRoot)
	UStaticMeshComponent WeightMesh;

	UPROPERTY(DefaultComponent, Attach = WeightRoot)
	UHazeSplineComponent SplineComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBoxComponent ButtonMashTrigger;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ButtonMashAttachmentPoint;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlayerAttachmentPoint;

	UPROPERTY()
	FOnSpaceWeightLanded OnSpaceWeightLanded;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeCapability> RequiredCapability;

	UPROPERTY(EditDefaultsOnly)
	UBlendSpace1D MayBlendSpace;

	UPROPERTY(EditDefaultsOnly)
	UBlendSpace1D CodyBlendSpace;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike PushWeightTimeLike;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ImpactEffect;

	UButtonMashProgressHandle MayMashHandle;
	UButtonMashProgressHandle CodyMashHandle;

	bool bWeightPushed = false;

	FTransform WeightDefaultTransform;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WeightDefaultTransform = WeightRoot.RelativeTransform;
		SplineComp.DetachFromComponent(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		Capability::AddPlayerCapabilityRequest(RequiredCapability);

		ButtonMashTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterTrigger");
		ButtonMashTrigger.OnComponentEndOverlap.AddUFunction(this, n"ExitTrigger");

		PushWeightTimeLike.BindUpdate(this, n"UpdatePushWeight");
		PushWeightTimeLike.BindFinished(this, n"FinishPushWeight");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Capability::RemovePlayerCapabilityRequest(RequiredCapability);
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		if (bWeightPushed)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		StartButtonMash(Player);
	}

	void StartButtonMash(AHazePlayerCharacter Player)
	{
		if (Player == Game::GetMay())
		{
			if (MayMashHandle != nullptr)
				return;

			MayMashHandle = StartButtonMashProgressAttachToComponent(Player, ButtonMashAttachmentPoint, NAME_None, FVector::ZeroVector);
		}
		else
		{
			if (CodyMashHandle != nullptr)
				return;

			CodyMashHandle = StartButtonMashProgressAttachToComponent(Player, ButtonMashAttachmentPoint, NAME_None, FVector::ZeroVector);
		}

		Player.SetCapabilityAttributeObject(n"SpaceWeightSpawner", this);
	}

	UFUNCTION(NotBlueprintCallable)
    void ExitTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Player == Game::GetMay())
		{
			if (MayMashHandle == nullptr)
				return;

			Player.SetCapabilityAttributeObject(n"SpaceWeightSpawner", nullptr);
			StopButtonMash(MayMashHandle);
			MayMashHandle = nullptr;
		}
		else
		{
			if (CodyMashHandle == nullptr)
				return;

			Player.SetCapabilityAttributeObject(n"SpaceWeightSpawner", nullptr);
			StopButtonMash(CodyMashHandle);
			CodyMashHandle = nullptr;
		}

		Player.SetCapabilityAttributeObject(n"SpaceWeightSpawner", nullptr);
    }

	void PushWeight()
	{
		bWeightPushed = true;
		PushWeightTimeLike.PlayFromStart();
		StopButtonMashes();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdatePushWeight(float CurValue)
	{
		FVector CurLoc = SplineComp.GetLocationAtTime(CurValue, ESplineCoordinateSpace::World);
		WeightRoot.SetWorldLocation(CurLoc);
		WeightRoot.AddLocalRotation(FRotator(-500.f * ActorDeltaSeconds, 0.f, 0.f));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishPushWeight()
	{
		OnSpaceWeightLanded.Broadcast();
		Niagara::SpawnSystemAtLocation(ImpactEffect, WeightRoot.WorldLocation);
		WeightRoot.SetRelativeTransform(WeightDefaultTransform);
		bWeightPushed = false;

		TArray<AActor> OverlappingActors;
		ButtonMashTrigger.GetOverlappingActors(OverlappingActors, AHazePlayerCharacter::StaticClass());
		
		for (AActor CurActor : OverlappingActors)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(CurActor);
			if (Player != nullptr)
			{
				StartButtonMash(Player);
			}
		}
	}

	void StopButtonMashes()
	{
		if (MayMashHandle != nullptr)
		{
			StopButtonMash(MayMashHandle);
			MayMashHandle = nullptr;
		}

		if (CodyMashHandle != nullptr)
		{
			StopButtonMash(CodyMashHandle);
			CodyMashHandle = nullptr;
		}
	}
}