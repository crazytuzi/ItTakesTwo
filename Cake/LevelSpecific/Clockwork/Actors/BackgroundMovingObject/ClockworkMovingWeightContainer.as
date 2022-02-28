import Cake.LevelSpecific.Clockwork.Actors.BackgroundMovingObject.ClockworkTimelineMovingObject;


class AClockworkMovingWeight : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
    USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
    UStaticMeshComponent Mesh;
	default Mesh.SetCollisionProfileName(n"NoCollision");
	default Mesh.bGenerateOverlapEvents = false;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent BeginPlayAudioEvent;

	UPROPERTY(Category = "Transform")
	FVector FinalPositionOffset;

	UPROPERTY(Category = "Transform")
	float StartOffset = 0.f;

	UPROPERTY(Category = "Transform")
	float LoopDuration = 12.f;

	UPROPERTY(Category = "Transform")
	bool bInvertMovement = false;

	UPROPERTY(Category = "Transform")
	FRuntimeFloatCurve Curve;

	float BeginPlayTime = 0;
	float LastUpdateTime = 0;
	float ForcedUpdateToGameTime = 0;
	float RandomTimeUpdate = 0;

	float PositionValue = 0;
	FVector StartLocation;
	FVector EndLocation;

	void SetPosition(float RawValue)
	{
		PositionValue = Curve.GetFloatValue(RawValue);
		if (bInvertMovement)
			PositionValue = 1.f - PositionValue;
		ActorLocation = FMath::Lerp(StartLocation, EndLocation, PositionValue);
	}
}

class AClockworkMovingWeightContainer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.bVisualizeComponent = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent AttachmentRoot;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 5000;
	default DisableComponent.bActorIsVisualOnly = true;
	default DisableComponent.bRenderWhileDisabled = true;

	// The time after the first rendering that we will continue to update the pendulum
	UPROPERTY(EditAnywhere, Category = "Pendulum|Optimization")
	float UpdateLingerTime = 3.f;

	// A value that makes the pendulum update even if it has not been rendered since some pendulums swing into vision
	UPROPERTY(EditAnywhere, Category = "Pendulum|Optimization")
	FHazeMinMax RandomForcedUpdateInterval = FHazeMinMax(0.5f, 1.f);

	UPROPERTY(EditInstanceOnly, Category = "EDITOR ONLY")
	TSubclassOf<AClockworkTimelineMovingObject> TypeToConvert = AClockworkTimelineMovingObject::StaticClass();
	
	UPROPERTY(EditConst, Category = "EDITOR ONLY")
	FTransform LockedRootTransform;
	default LockedRootTransform.SetScale3D(FVector::ZeroVector);

	UPROPERTY(EditInstanceOnly, Category = "EDITOR ONLY")
	float ConversionDistance = -1;

	UPROPERTY(EditConst)
	TArray<AClockworkMovingWeight> MovingWeights;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(LockedRootTransform.GetScale3D().IsNearlyZero())
			LockedRootTransform = AttachmentRoot.GetWorldTransform();

		for(int i = MovingWeights.Num() - 1; i >= 0; --i)
		{
			if(MovingWeights[i] == nullptr)
				MovingWeights.RemoveAt(i);

			MovingWeights[i].AttachToComponent(AttachmentRoot, AttachmentRule = EAttachmentRule::KeepWorld);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		for(auto Weight : MovingWeights)
			Weight.Mesh.SetVisibility(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorPostDisabled()
	{
		for(auto Weight : MovingWeights)
			Weight.Mesh.SetVisibility(false);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		const float GameTime = Time::GetGameTimeSeconds();
		for(int i = MovingWeights.Num() - 1; i >= 0; --i)
		{
			if(MovingWeights[i] == nullptr)
			{
				MovingWeights.RemoveAt(i);
				continue;
			}

			auto Weight = MovingWeights[i];
			Weight.BeginPlayTime = GameTime;
			Weight.StartLocation = Weight.GetActorLocation();
			Weight.EndLocation = Weight.StartLocation + GetActorRotation().RotateVector(Weight.FinalPositionOffset);
			Weight.LastUpdateTime = GameTime;
			Weight.SetPosition((Weight.StartOffset % Weight.LoopDuration) / Weight.LoopDuration);
			Weight.ForcedUpdateToGameTime = GameTime + 0.1f;
			if(Weight.BeginPlayAudioEvent != nullptr)
			{
				auto AkComponent = UHazeAkComponent::GetOrCreateHazeAkComponent(Weight);
				AkComponent.HazePostEvent(Weight.BeginPlayAudioEvent);
			}
		}	
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const float GameTime = Time::GetGameTimeSeconds();
		for(auto Weight : MovingWeights)
		{
			UpdateWeight(Weight, GameTime);
		}
	}

	void UpdateWeight(AClockworkMovingWeight Weight, float GameTime)
	{
		const bool bHasBeenRendered = Weight.Mesh.WasRecentlyRendered(UpdateLingerTime);
		if(bHasBeenRendered)
			Weight.ForcedUpdateToGameTime = GameTime + UpdateLingerTime;

		if(GameTime < Weight.ForcedUpdateToGameTime 
			|| GameTime >= Weight.LastUpdateTime + Weight.RandomTimeUpdate)
		{
			float ActiveTime = Time::GetGameTimeSince(Weight.BeginPlayTime);
			Weight.SetPosition((ActiveTime % Weight.LoopDuration) / Weight.LoopDuration);  

			Weight.LastUpdateTime = GameTime;

			// We use a random timer to sometimes force update the pendulums since some of them can swing into picture
			Weight.RandomTimeUpdate = FMath::RandRange(RandomForcedUpdateInterval.Min, RandomForcedUpdateInterval.Max);
		}
	}

#if EDITOR

	// This will fill all the pendulum data from BP
	UFUNCTION(CallInEditor, Category = "EDITOR ONLY")
	void CovertClockworkTimelineMovingObjectBPtoAS()
	{	
		TArray<AClockworkTimelineMovingObject> BP_Actors;
		GetAllActorsOfClass(TypeToConvert, BP_Actors);
		for(auto BP_Actor : BP_Actors)
		{
			if(ConversionDistance > 0 && BP_Actor.GetDistanceTo(this) > ConversionDistance)
				continue;

		 	const FMovingObjectConvertData Data = BP_Actor.GetConvertData();

		 	auto NewWeight = Cast<AClockworkMovingWeight>(SpawnActor(AClockworkMovingWeight::StaticClass(), FVector::ZeroVector, FRotator::ZeroRotator, NAME_None, true, GetLevel()));
		 	NewWeight.FinalPositionOffset = Data.FinalPositionOffset;
		 	NewWeight.StartOffset = Data.DelayUntilStart;
			NewWeight.LoopDuration = Data.LoopDuration;
			NewWeight.bInvertMovement = Data.bStartAtEnd;
		 	NewWeight.Curve = Data.Curve;
		 	FinishSpawningActor(NewWeight);

			NewWeight.RootComponent.SetWorldTransform(Data.WorldTransform);
			NewWeight.MeshRoot.SetRelativeTransform(Data.MeshRootTransform);
			NewWeight.Mesh.SetStaticMesh(Data.MeshToUse);
			NewWeight.Mesh.SetRelativeTransform(Data.MeshTransform);

			if(Data.bUseCollision)
				NewWeight.Mesh.SetCollisionProfileName(n"BlockAll", false);

			// Create audio
			if(Data.BeginPlayAudio != nullptr)
				NewWeight.BeginPlayAudioEvent = Data.BeginPlayAudio;

		 	NewWeight.AttachRootComponentTo(AttachmentRoot, NAME_None, EAttachLocation::KeepWorldPosition);
		 	MovingWeights.Add(NewWeight);
		 	BP_Actor.DestroyActor();
		}
	}

	// This will move the actor to the center of the cogs and update the disable range to cover the actor
	UFUNCTION(CallInEditor, Category = "EDITOR ONLY")
	void UpdateDisableComponentRangeAndRootPosition()
	{
		if(MovingWeights.Num() == 0)
			return;

		float BiggestDistance = 0;
		FVector MiddleOrigin = FVector::ZeroVector; 
		for(auto Weight : MovingWeights)
		{
			FVector Origin = FVector::ZeroVector;
			FVector Extends = FVector::ZeroVector;
			Weight.GetActorBounds(false, Origin, Extends);
			MiddleOrigin += Origin;
			float Distance = (Origin + Extends).Distance(Root.GetWorldLocation());
			if(Distance > BiggestDistance)
				BiggestDistance = Distance;
		}
		
		MiddleOrigin /= MovingWeights.Num();
		LockedRootTransform_Update();
		SetActorLocation(MiddleOrigin);
		LockedRootTransform_Apply();

		DisableComponent.AutoDisableRange = BiggestDistance;
		DisableComponent.AutoDisableRange *= FMath::Sqrt(3.f);
		DisableComponent.AutoDisableRange = FMath::CeilToInt(DisableComponent.AutoDisableRange);
	}

	UFUNCTION(CallInEditor, Category = "EDITOR ONLY")
	void LockedRootTransform_Update()
	{
		LockedRootTransform = AttachmentRoot.GetWorldTransform();
		
		for(int i = MovingWeights.Num() - 1; i >= 0; --i)
		{
			if(MovingWeights[i] == nullptr)
				MovingWeights.RemoveAt(i);

			MovingWeights[i].AttachToComponent(AttachmentRoot, AttachmentRule = EAttachmentRule::KeepWorld);
		}

	}

	UFUNCTION(CallInEditor, Category = "EDITOR ONLY")
	void LockedRootTransform_Apply()
	{
		AttachmentRoot.SetWorldTransform(LockedRootTransform);
	}
#endif
}