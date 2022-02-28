import Cake.LevelSpecific.Tree.Queen.WaspShapes.WaspShapeActor;
import Rice.Positions.GetClosestPlayer;
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;

class AWaspShapeActorTriangle : AWaspShapeActor
{
	bool bIsFalling = true;
	float TimeNestRestedonGround = 0;
	float TimeSinceStartedTriangle;
	float TimeSinceStartedTrackingPlayer = 0;
	float RoateSpeed = 1.75f;
	float MoveSpeed = 700;
	FVector FallVector;
	FVector DecalPosition;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDecalComponent NestDecal;

	UPROPERTY()
	UNiagaraSystem NestExplosionEffect;

	AHazePlayerCharacter TargetPlayer;

	UPROPERTY()
	ASwarmActor ScissorSwarm;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Beehive;

	float ShouldStartDroppingTimer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bIsSpawning)
		{
			UpdateSplineMeshes();

			if (bIsFalling)
			{
				ShouldStartDroppingTimer += DeltaTime;

				if (ShouldStartDroppingTimer > 2)
				{
					UpdateFallingBehaviour(DeltaTime);

					//Small hack, this only fires once as bisfalling is set to false once when updatefalling behaviour has laneded.
					if(!bIsFalling)
					{
						
						SetupForTackingPlayer();
					}
				}
			}

			else
			{
				TrackplayerBehaviour(DeltaTime);
			}
		}
	}

	void SetDecalPostion()
	{
		FHitResult HitResult;
		FVector DesiredLocation = ActorLocation + FVector::UpVector * -100000.f;

		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.Add(this);
		System::LineTraceSingle(ActorLocation, DesiredLocation, ETraceTypeQuery::WeaponTrace, false, ActorsToIgnore, EDrawDebugTrace::None, HitResult, false);

		if (HitResult.bBlockingHit)
		{
			DecalPosition = HitResult.Location;
		}
		NestDecal.SetWorldLocation(DecalPosition);
	}


	void SetupForTackingPlayer()
	{
		TargetPlayer = GetClosestPlayer(ActorLocation);
		WaspSpawner.StartSpawning();
		SetActorHiddenInGame(false);
		bIsSpawning = true;
		FVector FaceDirection = TargetPlayer.ActorLocation - ActorLocation;
		SetActorRotation(Math::MakeRotFromX(FaceDirection));
		Beehive.SetHiddenInGame(true);
		Niagara::SpawnSystemAtLocation(NestExplosionEffect, Beehive.WorldLocation);
		NestDecal.SetHiddenInGame(true);
	}

	void TrackplayerBehaviour(float DeltaTime)
	{
		TimeSinceStartedTrackingPlayer += DeltaTime;
		FVector DesiredDirection = TargetPlayer.ActorLocation - ActorLocation;
		DesiredDirection = DesiredDirection.GetSafeNormal();
		DesiredDirection.Z = 0;

		FVector FaceDirection = FMath::Lerp(ActorRotation.ForwardVector, DesiredDirection, DeltaTime * RoateSpeed);
		SetActorRotation(Math::MakeRotFromX(FaceDirection));

		FVector DesiredLocation = ActorLocation + FaceDirection * MoveSpeed * DeltaTime;
		FVector TraceLocation = ActorLocation + FaceDirection * (500 + MoveSpeed * DeltaTime) + FVector::UpVector * 10;
		FHitResult HitResult;
		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.Add(Game::GetCody());
		ActorsToIgnore.Add(Game::GetMay());
		ActorsToIgnore.Add(this);

		System::LineTraceSingle(ActorLocation + FVector::UpVector * 20, TraceLocation , ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, HitResult, true);
		SetActorLocation(DesiredLocation);


		if (HitResult.bBlockingHit && Cast<AWaspShapeActor>(HitResult.Actor) != nullptr || TimeSinceStartedTrackingPlayer > 10) 
		{
			StopSpawning();
		}
	}

	void StartSpawning() override
	{
		if (bIsSpawning)
		{
			StopSpawning();
		}

		SetDecalPostion();
		Shape.SetRelativeScale3D(FVector::OneVector * 0.1f);
		SetActorHiddenInGame(false);
		bIsSpawning = true;
		bIsFalling = true;
		Beehive.SetHiddenInGame(false);
		NestDecal.SetHiddenInGame(false);
		ShouldStartDroppingTimer = 0;
		TimeSinceStartedTrackingPlayer = 0;
	}

	void StopSpawning() override
	{
		Super::StopSpawning();
		TimeNestRestedonGround = 0;
		bIsFalling = true;
		FallVector = FVector::ZeroVector;
		Beehive.SetHiddenInGame(false);
		Shape.SetRelativeScale3D(FVector::OneVector);
		TimeSinceStartedTriangle = 0;
	}

	void UpdateFallingBehaviour(float DeltaTime)
	{
		NestDecal.SetWorldLocation(DecalPosition);
		FallVector += FVector::UpVector * -1 * 5.82f;
		FVector DesiredLocation = ActorLocation + FallVector;
		FHitResult HitResult;

		TArray<AActor> ActorsToIgnore;
		System::LineTraceSingle(ActorLocation, DesiredLocation, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, HitResult, true);

		if (HitResult.bBlockingHit)
		{
			SetActorLocation(HitResult.Location);
			TimeNestRestedonGround += DeltaTime;
			NestDecal.SetHiddenInGame(true);
			if (TimeNestRestedonGround > 1)
			{
				bIsFalling = false;
			}
		}
		else
		{
			SetActorLocation(DesiredLocation);
		}
	}
}