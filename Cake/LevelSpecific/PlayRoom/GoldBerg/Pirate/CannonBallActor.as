import Vino.Projectile.ProjectileMovement;
import Vino.Trajectory.TrajectoryStatics;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.CannonBallDamageableComponent;
import Peanuts.Audio.AudioStatics;

struct FCanonBallActivePosition
{
	bool bIsActive = false;
	FVector Position = FVector::ZeroVector;
	AActor Actor = nullptr;
	float StartDistanceSq = 0.0f;
	FVector StartPosition = FVector::ZeroVector;

	void TargetInit(FVector CurrentActorLocation, AActor InActor, FVector InTargetPosition)
	{
		Actor = InActor;
		Position = InTargetPosition;
		StartPosition = CurrentActorLocation;
		StartDistanceSq = Position.DistSquared(InTargetPosition);
	}

	void TargetInit(FVector CurrentActorLocation, AActor InActor, FVector InTargetPosition, FVector ConstrainDistanceDirection)
	{
		Actor = InActor;
		Position = InTargetPosition;
		StartPosition = CurrentActorLocation;
		StartDistanceSq = Position.DistSquared2D(InTargetPosition, ConstrainDistanceDirection);
	}
}

UCLASS(Abstract)
class ACannonBallActor : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;
	default Mesh.LightmapType = ELightmapType::ForceVolumetric;
	default Mesh.CollisionProfileName = n"OverlapAll";
	default Mesh.CollisionEnabled = ECollisionEnabled::NoCollision;	
	default Mesh.CastShadow = false;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent FlyTrail;

	UPROPERTY(DefaultComponent, NotEditable, Attach = Root)
	UHazeAkComponent AkComponent;

	UPROPERTY()
	ETraceTypeQuery TraceProfile = ETraceTypeQuery::Visibility;

	UPROPERTY()
	float AmountOfDamage = 1.f;

	UPROPERTY()
	float LifeDuration = 10.0f;

	UPROPERTY()
	UNiagaraSystem ExplosionEffect;

	UPROPERTY()
	UNiagaraSystem SplashEffect;

	UPROPERTY()
	UAkAudioEvent CannonBallSpawnAudioEvent;

	UPROPERTY()
	UAkAudioEvent CannonBallWaterSplashAudioEvent;

	UPROPERTY()
	UAkAudioEvent CannonBallExplosionAudioEvent;

	UPROPERTY()
	UAkAudioEvent CannonBallImpactAudioEvent;

	UPROPERTY(EditDefaultsOnly)
	UCapsuleComponent CustomCapsuleTraceCollisionShape;

	const float CollisionSize = 60.f;

	TArray<AActor> TraceIgnoreActors;
	
	float ActivationGameTime = 0.f;
	FVector StartLocation;
	FCanonBallActivePosition MoveRelativeToActor;

	FVector CurrentVelocity = FVector::ZeroVector;
	FVector LastActorTraceLocation = FVector::ZeroVector;
	float CurrentGravity = 0;
	FVector MovementDirection;

	private AActor ParentShooting;
	private AHazePlayerCharacter PlayerShooting;
	private bool bIsMoving = false;

	private int IsUsingPreditionMovementIndex = 0;
	private float PredictionTimeSinceActivation = 0;

	void Initialize(AActor Parent,  AHazePlayerCharacter PlayerOwner = nullptr)
	{
		ParentShooting = Parent;
		PlayerShooting = PlayerOwner;
		DisableActor(Parent);
	}

	void ActivateBall(FVector StartLocation, FRotator StartRotation, FVector InitialVelocity, float InitialGravity)
	{
		if(bIsMoving)
		{
			ensure(false, "The amount of canonballs in " + ParentShooting + " is not enough");
			EndCanonBallMovement(false, false);
		}

		EnableActor(ParentShooting);
		SetActorLocationAndRotation(StartLocation, StartRotation);
		LastActorTraceLocation = StartLocation;
		
		CurrentVelocity = InitialVelocity;
		CurrentGravity = InitialGravity;
		ActivationGameTime = Time::GetGameTimeSeconds();
		bIsMoving = true;
		Mesh.RelativeLocation = FVector::ZeroVector;
		IsUsingPreditionMovementIndex = 0;
		PredictionTimeSinceActivation = 0.f;

		if(CannonBallSpawnAudioEvent != nullptr)
			AkComponent.HazePostEvent(CannonBallSpawnAudioEvent);

		if(ParentShooting.HasControl() != HasControl())
		{
			if(!HasControl())
			{
				IsUsingPreditionMovementIndex = 1;
				PredictionTimeSinceActivation = 0.f;
			}
			else
			{
				NetStopUsingPredictionMovement();
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetStopUsingPredictionMovement()
	{
		IsUsingPreditionMovementIndex = 2;
	}

	void EndCanonBallMovement(bool bShowExplosionEffect, bool bShowWaterEffect)
	{	
		if(!bIsMoving)
			return;

		bIsMoving = false;
		OnCanonBallMovementEnded(bShowExplosionEffect, bShowWaterEffect);
	}

	protected void OnCanonBallMovementEnded(bool bShowExplosionEffect, bool bShowWaterEffect)
	{
		ClearRelativeMovement();

		FVector ImpactLocation = GetActorLocation();
		if(bShowExplosionEffect)
		{
			if(ExplosionEffect != nullptr)
			{
				auto NiagaraComponent = Niagara::SpawnSystemAtLocation(ExplosionEffect, ImpactLocation, ActorRotation);
				NiagaraComponent.SetTranslucentSortPriority(3);
			}				
			
			if(CannonBallExplosionAudioEvent != nullptr)
				PlayAudioEventAtActor(CannonBallExplosionAudioEvent, this);
		}	

		if(bShowWaterEffect)
		{
			if(SplashEffect != nullptr)
			{
				auto NiagaraComponent = Niagara::SpawnSystemAtLocation(SplashEffect, ImpactLocation, FRotator::ZeroRotator);
				NiagaraComponent.SetTranslucentSortPriority(3);
			}	

			if(CannonBallWaterSplashAudioEvent != nullptr)
				PlayAudioEventAtActor(CannonBallWaterSplashAudioEvent, this);	
		}

		// Destroy the canon if the controller is no longer valid
		if(ParentShooting != nullptr)
			DisableActor(ParentShooting);
		else
			DestroyCannonBall();
	}	

	bool DestroyCannonBall()
	{
		if(!IsActorDisabled() && ParentShooting != nullptr)
		{
			// this will destroy the actor when it tries to disable,
			// this usually happens when it hits something or the timer runs out
			ParentShooting = nullptr;
			return false;
		}
		else
		{
			DestroyActor();
			return true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bIsMoving)
		{
			MoveCannonBall(DeltaTime);
						
			if(HasControl() && bIsMoving)
			{
				const FVector CurrentLoc = GetActorLocation();
				const FVector LastInvisilbeWallTraceLocation = LastActorTraceLocation;
				const bool bTestTracing = LastActorTraceLocation.DistSquared(CurrentLoc) > FMath::Square(CollisionSize);
				
				if(bTestTracing)
				{
					bool bImpact = false;
					FHazeTraceParams Trace;
					GetTraceParams(Trace);	
					FHazeHitResult Hit;

					int TraceCount = 0;
					do
					{
						const FVector DirToCurrent = (CurrentLoc - LastActorTraceLocation).GetSafeNormal();
						LastActorTraceLocation += DirToCurrent * (CollisionSize - 1); // Use small overlap
					
						Trace.From = LastActorTraceLocation;
						Trace.To = LastActorTraceLocation + (FVector(0.f, 0.f, -500.f));
						//LastActorTraceLocation = CurrentLoc;	

						if(Trace.Trace(Hit))
						{
							if(Hit.Component.HasTag(n"Water") ||
								Hit.Actor.IsA(ALandscape::StaticClass()))
							{
								bImpact = Hit.Distance < CollisionSize * 0.5f;
							}
							else
							{
								bImpact = true;
							}
						}
	
						if(bImpact || TraceCount > 3)
							break;

						TraceCount++;
					} while(LastActorTraceLocation.DistSquared(CurrentLoc) > FMath::Square(CollisionSize));

					if(!bImpact) //Extra trace for invisible walls
					{
						FHazeTraceParams ExtraTrace = Trace;
						ExtraTrace.InitWithTraceChannel(ETraceTypeQuery::ETraceTypeQuery_MAX);
						ExtraTrace.From = LastInvisilbeWallTraceLocation;
						ExtraTrace.To = CurrentLoc;
						bImpact = ExtraTrace.Trace(Hit);

						if(bImpact)
						{
							if(Hit.Component.GetCollisionProfileName() == n"InvisibleWall")
							{
								bImpact = true;
							}
							else
							{
								bImpact = false;
							}
						}
			
					}

					if(bImpact)
						NetSendCanonBallHit(Hit);
					else
						UpdateActiveTimer();
				}	
			}
		}
	}

	void MoveCannonBall(float DeltaTime)
	{
		if(IsUsingPreditionMovementIndex == 0 || IsUsingPreditionMovementIndex == 2)
		{
			CurrentVelocity -= FVector(0, 0, CurrentGravity * DeltaTime);
			AddActorWorldOffset(CurrentVelocity * DeltaTime);

			if(MoveRelativeToActor.bIsActive && MoveRelativeToActor.Actor != nullptr)
			{
				const FVector NewWorldLocation = MoveRelativeToActor.Actor.GetActorLocation();
				const FVector Delta = NewWorldLocation - MoveRelativeToActor.Position;
				MoveRelativeToActor.Position = NewWorldLocation;
				AddActorWorldOffset(Delta);
			}

			if(Mesh.RelativeLocation.IsNearlyZero())
			{
				Mesh.RelativeLocation = FMath::VInterpTo(Mesh.RelativeLocation, FVector::ZeroVector, DeltaTime, 10);
			}
		}

		float LagMultiplier = Network::GetPingRoundtripSeconds();
		if(IsUsingPreditionMovementIndex == 1 && LagMultiplier > 0)
		{
			LagMultiplier = 1.f / LagMultiplier;
			float NetworkDeltaTime = DeltaTime / LagMultiplier;
			PredictionTimeSinceActivation = FMath::Min(PredictionTimeSinceActivation + NetworkDeltaTime, 1.f);
			CurrentVelocity -= FVector(0, 0, CurrentGravity * DeltaTime * PredictionTimeSinceActivation);
			Mesh.AddWorldOffset(CurrentVelocity * DeltaTime * PredictionTimeSinceActivation);
		}
	}

	void GetTraceParams(FHazeTraceParams& Out)
	{
		Out.InitWithTraceChannel(TraceProfile);
		Out.IgnoreActors(TraceIgnoreActors);
		Out.SetToSphere(CollisionSize);

		//Out.DebugDrawTime = 0.1f;	
	}

	// bool TraceForHits(FHazeTraceParams& Trace, FHazeHitResult& OutHit)
	// {
	// 	bool bHasHit = Trace.Trace(OutHit);
	// 	return bHasHit;
	// }

	void UpdateActiveTimer()
	{
		if(Time::GetGameTimeSeconds() >= ActivationGameTime + LifeDuration)
		{
			NetSendCanonBallHit(FHazeHitResult());
		}
	}

	UFUNCTION(BlueprintEvent)
	void PlaySpecialVFX(FHazeHitResult Impact)
	{

	}

	UFUNCTION(NetFunction)
	void NetSendCanonBallHit(FHazeHitResult Impact)
	{
		// AWheelBoatActor WheelBoat = Cast<> Impact.Actor
		
		PlaySpecialVFX(Impact);

		// Actor is already destroyed
		if(Impact.Component == nullptr)
		{
			EndCanonBallMovement(false, false);
			return;
		}

		// Force the cannonball to be at the impact point
		if(Impact.bBlockingHit)
			SetActorLocation(Impact.ImpactPoint);

		if(HandleCollision(Impact))
			return;
	
		EndCanonBallMovement(true, false);
	}

	// Returns true if the impact was handled and the canonball movement was stopped
	bool HandleCollision(FHazeHitResult Impact)
	{
		if(Impact.Actor != nullptr)
		{
			auto CannonBallDmgComp = Cast<UCannonBallDamageableComponent>(Impact.Actor.GetComponentByClass(UCannonBallDamageableComponent::StaticClass()));
			
			if (CannonBallDmgComp != nullptr)
			{
				// Print("CannonBallDmgComp FOUND");

				// if (CannonBallDmgComp.CanTakeDamage())
				// 	Print("CanTakeDamage = TRUE");
			}

			if(CannonBallDmgComp != nullptr && CannonBallDmgComp.CanTakeDamage())
			{
				CannonBallDmgComp.CallOnCannonBallHit(Impact.FHitResult, AmountOfDamage, CurrentVelocity, PlayerShooting); 
				EndCanonBallMovement(true, false);
				return true;
			}
		}

		// Impact with water
		bool bWaterCollision = false;
		if(Impact.Actor != nullptr)
			bWaterCollision = Impact.Actor.ActorHasTag(n"Water") || Impact.Actor.RootComponent.HasTag(n"Water");

		if(!bWaterCollision)
		{
			if(Impact.Component != nullptr)
				bWaterCollision = Impact.Component.HasTag(n"Water");
		}


		if(bWaterCollision)
		{
			EndCanonBallMovement(false, true);
			return true;
		}

		return false;
	}

	void PlayAudioEventAtActor(UAkAudioEvent AudioEvent, AHazeActor Actor)
	{
		if (AudioEvent != nullptr && Actor != nullptr)
			HazeAudio::PostEventAtLocation(AudioEvent, Actor);
			
	}

	void ActivateRelativeMovement(AActor ActorToFollow)
	{
		if(ActorToFollow == nullptr)
			return;

		MoveRelativeToActor.bIsActive = true;
		MoveRelativeToActor.Actor = ActorToFollow;
		MoveRelativeToActor.Position = ActorToFollow.GetActorLocation();
		MoveRelativeToActor.StartPosition = GetActorLocation();
	}

	void ClearRelativeMovement()
	{
		MoveRelativeToActor = FCanonBallActivePosition();
	}

	// void ActivateTargetMovement(FVector TargetPosition, AActor TargetActor)
	// {
	// 	MoveToTargetPosition.bIsActive = true;
	// 	MoveToTargetPosition.Position = TargetPosition;
	// 	MoveToTargetPosition.StartPosition = GetActorLocation();
	// 	MoveToTargetPosition.Actor = TargetActor;
	// }

	// void ClearTargetMovement()
	// {
	// 	MoveToTargetPosition = FCanonBallActivePosition();
	// }



// OLD


	//bool bBeingLaunched = false;
	
	// FVector TargetLocation;

	// float Speed = 3000.0f;
	// FVector NewVelocity;

	// FVector Direction;

	// FVector InheritedVelocity;

	// UFUNCTION(BlueprintOverride)
	// void Tick(float DeltaTime)
	// {
	// 	if(bHitDelay)
	// 	{
	// 		HitDelayTimer += DeltaTime;
	// 		if(HitDelayTimer >= HitDelayDuration)
	// 		{
	// 			HitDelayTimer = 0.0f;
	// 			bHitDelay = false;
	// 		}
	// 	}
	// }

	// UFUNCTION()
	// void SetStartValues(FVector StartLocation, FRotator StartRotation, AActor ParentShipFiring, AActor ParentCannonFiring, FVector TargetDirection, float NewSpeed, FVector NewInheritedVelocity)
	// {
	// 	SetActorLocation(StartLocation);
	// 	SetActorRotation(StartRotation);
		
	// 	ParentShip = ParentShipFiring;
	// 	ParentCannon = ParentCannonFiring;

	// 	Direction = TargetDirection;

	// 	Speed = NewSpeed;

	// 	InheritedVelocity = NewInheritedVelocity;
	// }

	// UFUNCTION()
	// void StartLaunchingCannonBall()
	// {
	// 	Mesh.SetHiddenInGame(false);
	// 	Mesh.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
	// 	Mesh.SetSimulatePhysics(true);
		
	// 	NewVelocity = Direction * Speed;

	// 	//NewVelocity += InheritedVelocity;		
		        
 	// 	LaunchCannonBall();
	// }

	// void LaunchCannonBall()
	// {
	// 	Mesh.SetPhysicsLinearVelocity(NewVelocity, true, n"");
	// 	bBeingLaunched = true;
	// }
}