
class UPlatformTraceComponent : USceneComponent
{
	UPROPERTY()
	EHazeSelectPlayer TraceAgainstPlayer = EHazeSelectPlayer::Both;

	UPROPERTY()
	TArray<UHazeBaseMovementComponent> MoveComps;

	UPrimitiveComponent PrimitiveToControl;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (TraceAgainstPlayer == EHazeSelectPlayer::Cody || TraceAgainstPlayer == EHazeSelectPlayer::Both)
			AddMovementComponentToTrack(UHazeBaseMovementComponent::Get(Game::GetCody()));

		if (TraceAgainstPlayer == EHazeSelectPlayer::May || TraceAgainstPlayer == EHazeSelectPlayer::Both)
			AddMovementComponentToTrack(UHazeBaseMovementComponent::Get(Game::GetMay()));

		PrimitiveToControl = FindTracePrimitive();
	}

	UFUNCTION()
	void AddMovementComponentToTrack(UHazeBaseMovementComponent MoveCompToAdd)
	{
		MoveComps.AddUnique(MoveCompToAdd);
	}

	UFUNCTION()
	void MovePlatformWithDelta(FVector DeltaToTrace)
	{
		if (PrimitiveToControl == nullptr)
			return;

		FHazeTraceParams MoveTrace;
		MoveTrace.InitWithPrimitiveComponent(PrimitiveToControl);
		MoveTrace.From = PrimitiveToControl.WorldLocation;
		MoveTrace.To = MoveTrace.From + DeltaToTrace;
		//MoveTrace.DebugDrawTime = 10.f;

		for (auto iMoveComp : MoveComps)
		{
			UPrimitiveComponent CurrentMoveWith;
			FVector DummyLocation;
			iMoveComp.GetCurrentMoveWithComponent(CurrentMoveWith, DummyLocation);
			if (CurrentMoveWith == PrimitiveToControl)
				continue;

			FHazeHitResult Hit;
			if (!MoveTrace.SingleTrace(iMoveComp.CollisionShapeComponent, Hit))
				continue;

			FTransform HitTransform(PrimitiveToControl.ComponentQuat, Hit.ShapeLocation, PrimitiveToControl.WorldScale);
			iMoveComp.OverrideMoveWithState(PrimitiveToControl, HitTransform, iMoveComp.OwnerLocation);

			//System::DrawDebugSphere(iMoveComp.OwnerLocation, 15.f, 12, FLinearColor::Green, Duration =  5.f);
			//System::DrawDebugBox(HitTransform.Location, PrimitiveToControl.BoundingBoxExtents, FLinearColor::Blue, Duration =  5.f);
		}

		Owner.SetActorLocation(Owner.ActorLocation + DeltaToTrace);
	}

	UFUNCTION()	
	void MovePlatformToLocation(FVector TargetLocation)
	{
		MovePlatformWithDelta(TargetLocation - Owner.ActorLocation);
	}

	UPrimitiveComponent FindTracePrimitive() const
	{
		UPrimitiveComponent Output = nullptr;
		if (!devEnsure(AttachParent != nullptr, "PlatformTraceComponent can not be root component on a actor"))
			return Output;
		
		Output = Cast<UPrimitiveComponent>(AttachParent);
		if (Output != nullptr)
			return Output;
		
		Output = Cast<UPrimitiveComponent>(Owner.RootComponent);
		devEnsure(Output != nullptr, "Either the root of the actor needs to be a primitive or the trace component needs to be directly attached to a primtive for it to function");
		return Output;
	}
}
