// import Vino.Movement.Capabilities.Standard.CharacterFloorMoveCapability;
// import Vino.Movement.Capabilities.Standard.CharacterAirMoveCapability;
// import Peanuts.Spline.SplineComponent;

// event void FOnDetachBabyOctopus();
// event void FOnAttachBabyOctopus(USceneComponent SceneComponent);


// UCLASS(Abstract)
// class AChargingOctopusActor : AHazeActor
// {
// 	UPROPERTY(DefaultComponent, RootComponent)
// 	USceneComponent Root;

//     UPROPERTY(DefaultComponent, Attach = Root)
// 	UStaticMeshComponent OctopusBase;

// 	UPROPERTY(DefaultComponent, Attach = OctopusBase)
// 	UStaticMeshComponent OctopusMesh;

// 	UPROPERTY(DefaultComponent, Attach = OctopusMesh)
// 	USphereComponent ExplosionCollider;
// 	default ExplosionCollider.CollisionEnabled = ECollisionEnabled::NoCollision;

//     UPROPERTY(DefaultComponent, Attach = OctopusBase)
// 	USphereComponent FollowCollider;
// 	default FollowCollider.CollisionProfileName = n"TriggerOnlyPlayer";	
// 	default FollowCollider.CollisionEnabled = ECollisionEnabled::NoCollision;

//     UPROPERTY(DefaultComponent, Attach = OctopusBase)
// 	UNiagaraComponent SplashEffect;

//     UPROPERTY()
// 	UNiagaraSystem Effect; 

//     UPROPERTY()
// 	FOnDetachBabyOctopus OnDetachBabyOctopus;
//     UPROPERTY()
// 	FOnAttachBabyOctopus OnAttachBabyOctopus;

//     bool FollowingShip = false;

//     UPROPERTY()
//     AActor TargetActor;

//     UPROPERTY()
//     FVector TargetActorLocation;
//     FRotator TargetActorRotation;
//     FVector DirectionToTarget;
    
//     float MovementSpeed = 1000.0f;
//     float LaunchSpeed = 1.0f;

//     UPROPERTY()
//     FVector StartLaunchLocation;
//     UPROPERTY()
//     FVector TargetLaunchLocation;

//     float CurrentAlpha;

//     FRotator BoatTargetRelativeRotation = FRotator(20,0,0);

//     UPROPERTY()
//     bool bBeingLaunched = false;

// 	UPROPERTY()
//     bool bHeldByPirateOctopus = false;

// 	UPROPERTY()
// 	AActor ParentOctopus;

//     UPROPERTY()
//     UCurveFloat VerticalCurve;

// 	UPROPERTY()
// 	bool bInBossStream = false;
	
// 	float BossStreamForce = -1000.0f;
// 	float BossStreamTotalDistance;

// 	UPROPERTY()
// 	float CurrentDistanceInStream = 0.0f;

// 	UHazeSplineComponent BossStreamSpline;
	

//     UFUNCTION(BlueprintCallable)
//     void PrepareLaunch(FVector TargetPosition)
//     {
// 		TargetLaunchLocation = TargetPosition;
// 		FindGroundLocation();
//         StartLaunchLocation = Root.WorldLocation;
// 		ExplosionCollider.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
		
// 		if(bInBossStream)
// 		{
// 			CurrentDistanceInStream = BossStreamSpline.GetDistanceAlongSplineAtWorldLocation(TargetPosition);		
// 		}
//     }

// 	UFUNCTION(BlueprintCallable)
//     void PrepareBossStreamLaunch(float TargetDistance)
//     {
// 		TargetLaunchLocation = BossStreamSpline.GetLocationAtDistanceAlongSpline(TargetDistance, ESplineCoordinateSpace::World);

// 		CurrentDistanceInStream = TargetDistance;					
		
// 		StartLaunchLocation = Root.WorldLocation;
// 		ExplosionCollider.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
//     }

// 	void ApplyBossStreamValues(AActor ThrowArm, UHazeSplineComponent StreamSpline, AActor TargetBoat)
// 	{
// 		bHeldByPirateOctopus = true;
// 		ParentOctopus = ThrowArm;
// 		bInBossStream = true;
// 		BossStreamSpline = StreamSpline;
// 		TargetActor = TargetBoat;
// 	}

//     UFUNCTION(BlueprintOverride)
//     void Tick(float DeltaTime)
//     {
//         if(FollowingShip && !bHeldByPirateOctopus && !bBeingLaunched && !bInBossStream)
//         {
//             FVector NextLocation = (ActorLocation + DirectionToTarget * (MovementSpeed * DeltaTime));
//             SetActorLocation(NextLocation);
//         }

//         if (bBeingLaunched && !bHeldByPirateOctopus)
//         {
//             CurrentAlpha = CurrentAlpha + (DeltaTime * LaunchSpeed);
//             CurrentAlpha = FMath::Clamp(CurrentAlpha, 0.f, 1.f);

//             float VerticalCurveValue = VerticalCurve.GetFloatValue(CurrentAlpha);

//             FVector HorizontalLocation = FMath::Lerp(ActorLocation, TargetLaunchLocation, CurrentAlpha);
//             FVector VerticalLocation = FMath::Lerp(ActorLocation, TargetLaunchLocation, VerticalCurveValue);

//             SetActorLocation(FVector(HorizontalLocation.X, HorizontalLocation.Y, VerticalLocation.Z));

//             if (CurrentAlpha >= 0.95)
//             {
//                 LandedAfterLaunching();
//             }
//         }

// 		if(bInBossStream && !bHeldByPirateOctopus && !bBeingLaunched)
// 		{
// 			CurrentDistanceInStream = CurrentDistanceInStream + ((BossStreamForce) * DeltaTime);
// 			Root.SetWorldLocation(BossStreamSpline.GetLocationAtDistanceAlongSpline(CurrentDistanceInStream, ESplineCoordinateSpace::World));
// 			Root.SetWorldRotation(BossStreamSpline.GetRotationAtDistanceAlongSpline(CurrentDistanceInStream, ESplineCoordinateSpace::World));
// 			//flip the rotation so it's facing the direction it's going
// 		}
//     }

//     void LandedAfterLaunching()
//     {
//         bBeingLaunched = false;
// 		if(bInBossStream)
// 		{
// 			FollowShip();
// 		}
// 		else
// 		{
// 			AllowToFollow();
// 		}
//     }

//     UFUNCTION(BlueprintCallable)
//     void Launch()
//     {
//         bBeingLaunched = true;
// 		DetachOctopus();
// 		bHeldByPirateOctopus = false;

		
// 	// 	FVector AboveLocation = FVector(TargetLaunchLocation.X, TargetLaunchLocation.Y, TargetLaunchLocation.Z + (TargetLaunchLocation.Z * 4000.f));		
// 	// 	FVector GroundLocation = FVector(TargetLaunchLocation.X, TargetLaunchLocation.Y, TargetLaunchLocation.Z - (TargetLaunchLocation.Z * 4000.f));

// 	// 	TArray<AActor> ActorsToIgnore;
// 	// 	ActorsToIgnore.Add(Game::GetCody());
// 	// 	ActorsToIgnore.Add(Game::GetMay());

// 	// 	FHitResult HitResult;

// 	// 	System::LineTraceSingle(AboveLocation, GroundLocation, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::Persistent, HitResult, true, FLinearColor::Blue, FLinearColor::Green, 2.f);
//     }

//     void CalculateDirectionToLocation(FVector Location)
// 	{
// 		FVector Direction = FVector(Location.X - ActorLocation.X, Location.Y -  ActorLocation.Y, 0);
// 		Direction.Normalize();
// 		FRotator NewRotator = Math::MakeRotFromX(Direction);
//         TargetActorRotation = NewRotator;
//         DirectionToTarget = Direction;
//     }

// 	void AllowToFollow()
// 	{
// 		FollowCollider.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
// 	}


//     UFUNCTION(BlueprintCallable)
//     void FollowShip()
//     {
// 		FollowCollider.CollisionEnabled = ECollisionEnabled::NoCollision;
// 		ExplosionCollider.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
//         FollowingShip = true;
//         CalculateDirectionToLocation(TargetActor.GetActorLocation());
//         SetActorRotation(TargetActorRotation);
//         OctopusBase.SetRelativeRotation(BoatTargetRelativeRotation);
//         PlaySplashEffect();
//     }


//     void PlaySplashEffect()
// 	{
//         SplashEffect = Niagara::SpawnSystemAttached(
//         Effect,
//         OctopusBase, 
//         NAME_None,
//         FVector::ZeroVector,
//         FRotator::ZeroRotator,
//         EAttachLocation::SnapToTargetIncludingScale,
//         true
//         );        
// 	}

	
// 	UFUNCTION()
// 	void FindGroundLocation()
// 	{
// 		FVector AboveLocation = FVector(TargetLaunchLocation.X, TargetLaunchLocation.Y, TargetLaunchLocation.Z + (TargetLaunchLocation.Z * 4000.f));		
// 		FVector GroundLocation = FVector(TargetLaunchLocation.X, TargetLaunchLocation.Y, TargetLaunchLocation.Z - (TargetLaunchLocation.Z * 4000.f));

// 		TArray<AActor> ActorsToIgnore;
// 		ActorsToIgnore.Add(Game::GetCody());
// 		ActorsToIgnore.Add(Game::GetMay());

// 		FHitResult HitResult;

// 		System::LineTraceSingle(AboveLocation, GroundLocation, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::Persistent, HitResult, true, FLinearColor::Blue, FLinearColor::Green, 2.f);

// 		TargetLaunchLocation = FVector(TargetLaunchLocation.X, TargetLaunchLocation.Y, HitResult.Location.Z);
// 	}

// 	UFUNCTION()
// 	void AttachOctopus(USceneComponent SceneComponent)
// 	{
// 		OnAttachBabyOctopus.Broadcast(SceneComponent);
// 		//Root.DetachFromComponent(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
// 		//this.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);		
// 	}

// 	UFUNCTION()
// 	void DetachOctopus()
// 	{
// 		OnDetachBabyOctopus.Broadcast();
// 		//Root.DetachFromComponent(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
// 		//this.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);		
// 	}
// }