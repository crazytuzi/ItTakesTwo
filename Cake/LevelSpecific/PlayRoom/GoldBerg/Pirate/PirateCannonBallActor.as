import Vino.Projectile.ProjectileMovement;
import Vino.Trajectory.TrajectoryStatics;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.CannonBallShadowActor;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;
import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailPumpCart;

event void FOnCannonBallExploded(APirateCannonBallActor CannonBall);

UCLASS(Abstract)
class APirateCannonBallActor : ACannonBallActor
{
	default AmountOfDamage = 2.f;
	default LifeDuration = 20.f;

	UPROPERTY()
	TSubclassOf<ACannonBallShadowActor> ShadowClass;

	UPROPERTY()
	FOnCannonBallExploded OnCannonBallExploded;

	const float TargetAudioMaxDistance = 1000.0f;

	UPROPERTY(EditConst)
	ACannonBallShadowActor CreatedShadow;

	UPROPERTY()
	UNiagaraSystem CannonballImpactBoatSystem;

	float NextShadowUpdateTime;
	const float UpdateShadowIntervall = 0.5f;

	bool bHasGroundImpact = false;
	FHazeHitResult GroundHit;

	FCanonBallActivePosition WheelBoatTargetDistance;
	FCanonBallActivePosition FallingTargetDistance;

	void Initialize(AActor Parent, AHazePlayerCharacter PlayerOwner = nullptr) override
	{
		CreatedShadow = Cast<ACannonBallShadowActor>(SpawnActor(ShadowClass, Level = GetLevel()));
		CreatedShadow.SetOwner(this);
		Super::Initialize(Parent);
	}
		
	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		if(CreatedShadow != nullptr)
		 	CreatedShadow.DestroyActor();
		CreatedShadow = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		CreatedShadow.EnableActor(this);
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		CreatedShadow.DisableActor(this);
		return true;
	}

	void ClearTargetMovement()
	{
		WheelBoatTargetDistance = FCanonBallActivePosition();
		FallingTargetDistance = FCanonBallActivePosition();
	}

	void ActivateBall(FVector StartLocation, FRotator StartRotation, FVector InitialVelocity, float InitialGravity, FVector TargetLocation, AActor TargetActor)
	{	
		FVector NewInitialVelocity = CalculateVelocityForPathWithHeight(StartLocation, TargetLocation, InitialGravity, 2500.f);
		ActivateBall(StartLocation, StartRotation, NewInitialVelocity, InitialGravity);
		WheelBoatTargetDistance.TargetInit(StartLocation, TargetActor, TargetLocation, FVector::UpVector);
		WheelBoatTargetDistance.bIsActive = true;
		CreatedShadow.Activate(TargetLocation);
		NextShadowUpdateTime = Time::GetGameTimeSeconds();
		bHasGroundImpact = false;
		GroundHit = FHazeHitResult();		
	}

	protected void OnCanonBallMovementEnded(bool bShowExplosionEffect, bool bShowWaterEffect) override
	{
		OnCannonBallExploded.Broadcast(this);
		AkComponent.SetRTPCValue("Rtpc_Weapon_Cannon_Cannonball_Trajectory", 0.f, 0.f);
		AkComponent.SetRTPCValue("Rtpc_Weapon_Cannon_Cannonball_BoatOnTarget", 0.f, 0.f);
		Super::OnCanonBallMovementEnded(bShowExplosionEffect, bShowWaterEffect);
	}

	void MoveCannonBall(float DeltaTime) override
	{
		Super::MoveCannonBall(DeltaTime);

		// Update the shadow position
		const float WorldTime = Time::GetGameTimeSeconds();
		if(WorldTime >= NextShadowUpdateTime)
		{
			NextShadowUpdateTime = WorldTime + UpdateShadowIntervall;
			FHazeTraceParams GroundTrace;
			GetTraceParams(GroundTrace);
			GroundTrace.SetToLineTrace();
			GroundTrace.From = CreatedShadow.TargetLocation + (FVector::UpVector * 200);
			GroundTrace.To = CreatedShadow.TargetLocation - (FVector::UpVector * 200);
			
			FHazeHitResult NewGroundHit;
			if(GroundTrace.Trace(NewGroundHit))
			{
				bHasGroundImpact = true;
				GroundHit = NewGroundHit;
			}
		}

		if(bHasGroundImpact)	
		{
			FVector NewLocation = FMath::VInterpConstantTo(CreatedShadow.GetActorLocation(), GroundHit.ImpactPoint, DeltaTime, 2.f);
			CreatedShadow.SetActorLocation(NewLocation);
		}

		const FVector CurrentLocation = GetActorLocation();
		if(FallingTargetDistance.bIsActive && !WheelBoatTargetDistance.bIsActive)
		{
			const float CurrentDistance = FallingTargetDistance.StartPosition.DistSquared(CurrentLocation);
			const float DistanceToBoat = FMath::Min(CurrentDistance / FallingTargetDistance.StartDistanceSq, 1.f);
			CreatedShadow.ScaleLinesWithDistance(DistanceToBoat);
			AkComponent.SetRTPCValue("Rtpc_Weapon_Cannon_Cannonball_BoatOnTarget", 1.f - DistanceToBoat, 0.f);	
		}
		else
		{
			const FVector DeltaMoveDir = CurrentVelocity.GetSafeNormal();
			if(DeltaMoveDir.DotProduct(-FVector::UpVector) > 0.1f)
			{
				FallingTargetDistance.TargetInit(CurrentLocation, WheelBoatTargetDistance.Actor, WheelBoatTargetDistance.Position);
				FallingTargetDistance.bIsActive = true;
		
			}
		}

		if(WheelBoatTargetDistance.bIsActive)
		{
			const float CurrentDistance = WheelBoatTargetDistance.StartPosition.DistSquared2D(CurrentLocation);
			const float DistanceToBoat = FMath::Min(CurrentDistance / WheelBoatTargetDistance.StartPosition.DistSquared(WheelBoatTargetDistance.Position), 1.f);
			CreatedShadow.ScaleLinesWithDistance(DistanceToBoat);

			AkComponent.SetRTPCValue("Rtpc_Weapon_Cannon_Cannonball_Trajectory", 1.f - DistanceToBoat, 0.f);
			AkComponent.SetRTPCValue("Rtpc_Weapon_Cannon_Cannonball_BoatOnTarget", 1.f - DistanceToBoat, 0.f);
		}
	}

	bool HandleCollision(FHazeHitResult Impact) override
	{
		AWheelBoatActor WheelBoat = Cast<AWheelBoatActor>(Impact.Actor);
		ARailPumpCart RailCart = Cast<ARailPumpCart>(Impact.Actor);

		if (RailCart != nullptr)
		{
			TArray<AWheelBoatActor> WheelBoatArray;
			GetAllActorsOfClass(WheelBoatArray);

			if (WheelBoatArray.Num() > 0)
			{
				WheelBoat = WheelBoatArray[0];

				if (WheelBoat != nullptr)
				{
					WheelBoat.BoatWasHit(AmountOfDamage, EWheelBoatHitType::CannonBall);
					EndCanonBallMovement(true, false);
					return true;
				}
			}
		}

		if (WheelBoat != nullptr)
		{
			WheelBoat.BoatWasHit(AmountOfDamage, EWheelBoatHitType::CannonBall);
			EndCanonBallMovement(true, false);
			return true;
		}

		return Super::HandleCollision(Impact);
	}

	UFUNCTION(BlueprintOverride)
	void PlaySpecialVFX(FHazeHitResult Impact)
	{
		AWheelBoatActor WheelBoat = Cast<AWheelBoatActor>(Impact.Actor);

		ARailCart RailCart = Cast<ARailCart>(Impact.Actor);

		if (WheelBoat != nullptr)
		{
			// System::DrawDebugSphere(Impact.ImpactPoint, 200.f, 12, FLinearColor::Red, 5.f);
			Niagara::SpawnSystemAtLocation(CannonballImpactBoatSystem, Impact.ImpactPoint, FRotator(0.f), FVector(5.f));
		}
		else if (RailCart != nullptr)
		{
			// System::DrawDebugSphere(Impact.ImpactPoint, 200.f, 12, FLinearColor::Red, 5.f);
			Niagara::SpawnSystemAtLocation(CannonballImpactBoatSystem, Impact.ImpactPoint, FRotator(0.f), FVector(5.f));			
		}
	}	

	UFUNCTION()
	void PlayAudioEventAtActor(UAkAudioEvent AudioEvent, AHazeActor Actor)
	{
		if (AudioEvent != nullptr && Actor != nullptr)			
			AkComponent.HazePostEvent(AudioEvent);			
	}
}