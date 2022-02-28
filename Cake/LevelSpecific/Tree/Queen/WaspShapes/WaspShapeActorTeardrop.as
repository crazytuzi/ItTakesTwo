import Cake.LevelSpecific.Tree.Queen.WaspShapes.WaspShapeActor;

UCLASS(Abstract)
class AWaspShapeActorTearDrop : AWaspShapeActor
{
	bool bIsFalling = true;
	float TimeOnGround = 0;
	float TimeExpanding = 0;
	float ScaleSpeed = 7;
	float TimeSinceStarted = 0;
	FVector FallVector;
	FVector SplineStartScale;
	FVector DecalPosition;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDecalComponent NestDecal;

	UPROPERTY()
	UNiagaraSystem NestExplosionEffect;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Beehive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		SplineStartScale = Shape.RelativeScale3D;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bIsSpawning)
		{
			TimeSinceStarted += DeltaTime;

			if (TimeSinceStarted > 2.f)
			{
				if (bIsFalling)
				{
					UpdateFallingBehaviour(DeltaTime);

					//Small hack, this only fires once as bisfalling is set to false once when updatefalling behaviour has laneded.
					if(!bIsFalling)
					{
						Beehive.SetHiddenInGame(true);
						Niagara::SpawnSystemAtLocation(NestExplosionEffect, Beehive.WorldLocation);
					}
				}

				else
				{
					UpdateExpansionBehaviour(DeltaTime);
				}
			}
		}
	}

	void UpdateExpansionBehaviour(float DeltaTime)
	{
		Shape.SetRelativeScale3D(Shape.RelativeScale3D +(FVector::OneVector  * DeltaTime * ScaleSpeed));
		TimeExpanding += DeltaTime;

		UpdateSplineMeshes();
		if(TimeExpanding > 10)
		{
			StopSpawning();
		}
	}
	void StartSpawning() override
	{
		Super::StartSpawning();
		SetDecalPostion();
		NestDecal.SetHiddenInGame(false);
		Beehive.SetHiddenInGame(false);
		TimeSinceStarted = 0;
		
		Shape.SetRelativeScale3D(FVector::OneVector);
		UpdateSplineMeshes();
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
	}

	void StopSpawning() override
	{
		NestDecal.SetHiddenInGame(true);
		Super::StopSpawning();
		Shape.SetRelativeScale3D(SplineStartScale);
		TimeOnGround = 0;
		bIsFalling = true;
		TimeExpanding = 0;
		FallVector = FVector::ZeroVector;
	}

	void UpdateFallingBehaviour(float DeltaTime)
	{
		NestDecal.SetWorldLocation(DecalPosition);
		FallVector += FVector::UpVector * -1 * 5.82f;
		FVector DesiredLocation = ActorLocation + FallVector;
		FHitResult HitResult;
		
		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.Add(this);

		System::LineTraceSingle(ActorLocation, DesiredLocation, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::ForOneFrame, HitResult, true);

		if (HitResult.bBlockingHit)
		{
			SetActorLocation(HitResult.Location + FVector::UpVector * 50);
			TimeOnGround += DeltaTime;

			if (TimeOnGround > 1)
			{
				bIsFalling = false;
				NestDecal.SetHiddenInGame(true);
			}
		}
		else
		{
			SetActorLocation(DesiredLocation);
		}
	}
}