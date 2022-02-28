// import Cake.LevelSpecific.Garden.ControllablePlants.Vine.VineImpactComponent;
// import Vino.Movement.Components.MovementComponent;

// class ADraggablePlantActor : AHazeActor
// {
// 	UPROPERTY(DefaultComponent, RootComponent)
// 	USceneComponent RootComp;

// 	UPROPERTY(DefaultComponent, Attach = RootComp)
// 	UBoxComponent CollisionComp;

// 	UPROPERTY(DefaultComponent, Attach = RootComp)
// 	UStaticMeshComponent DraggableMesh;

// 	UPROPERTY(DefaultComponent)
// 	UVineImpactComponent VineImpactComp;

// 	UPROPERTY(DefaultComponent)
// 	UHazeMovementComponent MoveComp;

// 	FVector InitialDirection;
// 	FVector InitialRightVector;
// 	FVector InitialOffset;

// 	UFUNCTION(BlueprintOverride)
// 	void BeginPlay()
// 	{
// 		MoveComp.Setup(CollisionComp);

// 		VineImpactComp.OnVineConnected.AddUFunction(this, n"VineConnected");
// 	}

// 	UFUNCTION(NotBlueprintCallable)
// 	void VineConnected()
// 	{
// 		InitialDirection = Game::GetCody().ActorForwardVector;
// 		InitialRightVector = Game::GetCody().ActorRightVector;
// 		InitialOffset = Game::GetCody().ActorTransform.InverseTransformPosition(ActorLocation);
// 		InitialOffset.Z = 0.f;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void Tick(float DeltaTime)
// 	{
// 		if (VineImpactComp.bVineAttached)
// 		{
// 			FVector TargetLoc = Game::GetCody().ActorLocation + (InitialDirection * InitialOffset.X);
// 			TargetLoc += (InitialRightVector * InitialOffset.Y);
// 			TargetLoc.Z = ActorLocation.Z;
// 			FVector CurTargetLoc = FMath::VInterpTo(ActorLocation, TargetLoc, DeltaTime, 2.f);
// 			FVector CurLoc = CurTargetLoc - ActorLocation;

// 			FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"DragPlant");
// 			MoveData.ApplyDelta(CurLoc);
// 			MoveComp.Move(MoveData);
// 		}
// 	}
// }