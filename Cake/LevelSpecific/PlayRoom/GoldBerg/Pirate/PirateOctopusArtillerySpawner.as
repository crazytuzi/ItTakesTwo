import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.PirateOctopusArtilleryActor;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;

UCLASS(Abstract)
class APirateOctopusArtillerySpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(Category = "References")
	AWheelBoatActor WheelBoat;
	
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<APirateOctopusArtilleryActor> OctopusArtilleryClass;

	APirateOctopusArtilleryActor Octopus;

	TArray<APirateCannonBallActor> CannonBallsShot;


	bool bExplosionDelayOn = false;
	float DelayTimer = 0.0f;
	float ExplosionDelayDuration = 10.0f;
	float SpawnDistance = 6000;
	float SpawnDisableDistance = 2000;
	bool bActivatedOctopus = false;

	float MaxRandomOffset = 200.0f;

	float InitialDelay = 5.f;

	void Initialize(AWheelBoatActor Boat, UHazeSplineComponent BossSpline)	
	{
		WheelBoat = Boat;
		Octopus = Cast<APirateOctopusArtilleryActor>(SpawnActor(OctopusArtilleryClass, ActorLocation, ActorRotation, Level = GetLevel(), bDeferredSpawn = true));
		Octopus.MakeNetworked(this);
		Octopus.SetControlSide(this);
		Octopus.FinishSpawningActor();
		Octopus.OnPirateShipExploded.AddUFunction(this, n"OctopusExploded");
		Octopus.SplineToFollow = BossSpline;

		Octopus.ShootPirateCannonBallsComponent.OnCannonBallsLaunched.AddUFunction(this, n"OnShipCannonBallLaunched");

		Octopus.DisableActor(this);
		
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		if(Octopus != nullptr)
		{
			System::ClearAndInvalidateTimerHandle(Octopus.ActivationTimerHandle);
			
			Octopus.DestroyActor();

			for(APirateCannonBallActor CannonBall : CannonBallsShot)
			{
				if(CannonBall != nullptr)
				{
					// Force the canonball to land and destroy it
					CannonBall.EndCanonBallMovement(false, false);
					CannonBall.DestroyCannonBall();
				}
			}

			Octopus = nullptr;
		}
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(InitialDelay > 0)
		{
			InitialDelay -= DeltaTime;
			return;
		}

		if(bExplosionDelayOn)
		{
			DelayTimer += DeltaTime;
			if(DelayTimer >= ExplosionDelayDuration)
			{
				bExplosionDelayOn = false;
			}
			else
			{
				return;
			}
		}

		if(HasControl())
		{
			if(!Octopus.bActivated && !Octopus.bFloatingUp && WheelBoat != nullptr && !bActivatedOctopus)
			{
				float DistanceSq = ActorLocation.DistSquared2D(WheelBoat.ActorLocation);
				if(DistanceSq <= FMath::Square(SpawnDistance) && DistanceSq > FMath::Square(SpawnDisableDistance))
				{
					NetActivateOctopusWithRandomDelay(FMath::RandRange(0.f, 0.25f));	
				}
			}
		}

	}

	UFUNCTION(NetFunction)
	void NetActivateOctopusWithRandomDelay(float Delay)
	{
		System::SetTimer(this, n"ActivateOctopus", Delay, false);
		Octopus.EnableActor(this);
		bActivatedOctopus = true;
	}

	UFUNCTION(NotBlueprintCallable)
	void ActivateOctopus()	
	{
		FVector NewLocation = ActorLocation;
		NewLocation.X += FMath::RandRange(-MaxRandomOffset, MaxRandomOffset);
		NewLocation.Y += FMath::RandRange(-MaxRandomOffset, MaxRandomOffset);
		Octopus.FloatUp(NewLocation);
	}

	UFUNCTION(NotBlueprintCallable)
	void OctopusExploded(APirateShipActor Ship)
	{
		DelayTimer = 0.0f;
		bExplosionDelayOn = true;
		bActivatedOctopus = false;
		Octopus.DisableActor(this);
	}

	UFUNCTION()
	void OnShipCannonBallLaunched(FVector LaunchLocation, FRotator LaunchRotation, APirateCannonBallActor CannonBall)
	{
		if(!CannonBallsShot.Contains(CannonBall))
			CannonBallsShot.Add(CannonBall);
	}
}
