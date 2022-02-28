import Vino.PlayerHealth.PlayerDeathEffect;
import Vino.PlayerHealth.PlayerHealthStatics;
event void FOnRocketReadyToDisable(AFireworkRocket Rocket);
event void FDissipateRocket(AFireworkRocket Rocket);
event void FRemoveActiveRocket(AFireworkRocket Rocket);

class AFireworkRocket : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	// UPROPERTY(DefaultComponent, Attach = Root)
	// UArrowComponent ArrowComp;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent ParticleTrail;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent ParticleExplosion;
	default ParticleExplosion.SetWorldScale3D(FVector(5.f));

	UPROPERTY(Category = "Particle Effects")
	UNiagaraSystem ExplosionParticle;

	UPROPERTY(Category = "Particle Effects")
	TArray<FLinearColor> Colours;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent AkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent FireworkExplosion;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StartFireworkTravelSound;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StopFireworkTravelSound;

	UPROPERTY(Category = "Death")
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	FOnRocketReadyToDisable EventRocketReadyToDisable;

	FDissipateRocket EventDissipateRocket; 

	FRemoveActiveRocket EventRemoveActiveRocket;

	float MaxHeight = 2900.f;
	float MinHeight = 2000.f;
	float SetHeight;

	float DirectionRadiusValue = 1150.f;
	
	float MinDistance = 235.f;
	float Distance;
	float InitialDistance;

	const float DisableTimer = 6.2f;
	float CurrentTime = 0.f;

	FVector Target;

	bool bStartCountDisable;
	bool bComplete;

	float TravelAlpha;

	void RocketInitiate(FVector StartLocation, FVector EndLocation, UObject FireworkStationRef)
	{
		ParticleTrail.Activate(true);
		ParticleExplosion.SetActive(false);

		ActorLocation = StartLocation;

		float RandomHeight = FMath::RandRange(EndLocation.Z + MinHeight, EndLocation.Z + MaxHeight); 
		SetHeight = RandomHeight;

		float RandomPointX = FMath::RandRange(EndLocation.X - DirectionRadiusValue, EndLocation.X + DirectionRadiusValue);
		float RandomPointY = FMath::RandRange(EndLocation.Y - DirectionRadiusValue, EndLocation.Y + DirectionRadiusValue);

		Target = FVector(RandomPointX, RandomPointY, RandomHeight);

		InitialDistance = (ActorLocation - Target).Size();

		AkComp.HazePostEvent(StartFireworkTravelSound);
		
		bComplete = false;

		PlayerKillCheck(50.f);
	}
	
	void PlayerKillCheck(float Distance)
	{
		float DistanceFromMay = (Game::May.ActorLocation - ActorLocation).Size();
		float DistanceFromCody = (Game::Cody.ActorLocation - ActorLocation).Size();

		if (DistanceFromMay < Distance)
			KillPlayer(Game::May, DeathEffect);

		if (DistanceFromCody < Distance)
			KillPlayer(Game::Cody, DeathEffect);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Distance = (ActorLocation - Target).Size();
		FVector NextLoc = FMath::VInterpTo(ActorLocation, Target, DeltaTime, 1.3f);
		SetActorLocation(NextLoc);


		if (!bComplete)
			FireworkTravelAudio();

		if(bStartCountDisable)
		{
			CurrentTime -= DeltaTime;

			if (CurrentTime <= 0.f)
			{
				EventRocketReadyToDisable.Broadcast(this);
				bStartCountDisable = false;
			}
		}

		if (Distance <= MinDistance && !bComplete)
		{
			EventRemoveActiveRocket.Broadcast(this);
			AkComp.HazePostEvent(StopFireworkTravelSound);
			System::SetTimer(this, n"DelayedDissipate", 1.f, false);
			bComplete = true;
		}
	}

	UFUNCTION()
	void DelayedDissipate()
	{
		EventDissipateRocket.Broadcast(this);
	}

	void FireworkParticleExplosion()
	{
		int R = FMath::RandRange(0, Colours.Num() - 1);
		int R2 = FMath::RandRange(0, Colours.Num() - 1);
		int R3 = FMath::RandRange(0, Colours.Num() - 1);

		ParticleExplosion.SetNiagaraVariableLinearColor("Color", Colours[R]);
		ParticleExplosion.SetNiagaraVariableLinearColor("Color2", Colours[R]);
		ParticleExplosion.SetNiagaraVariableLinearColor("Color3", Colours[R]);
		
		ParticleExplosion.Activate(true);
		ParticleTrail.Deactivate();
		CurrentTime = DisableTimer;
		bStartCountDisable = true;
		bComplete = true;

		AkComp.HazePostEvent(StopFireworkTravelSound);
		AkComp.HazePostEvent(FireworkExplosion);

		PlayerKillCheck(250.f);
	}

	void FireworkTravelAudio()
	{
		TravelAlpha = Distance / (InitialDistance - MinDistance);
		AkComp.SetRTPCValue("Rtcp_World_SideContent_Clockwork_Interactions_Helltower_Fireworks_Projectile_TravelAlpha", TravelAlpha);
	}
}