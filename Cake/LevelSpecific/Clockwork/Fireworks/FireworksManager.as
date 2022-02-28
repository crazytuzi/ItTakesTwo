import Cake.LevelSpecific.Clockwork.Fireworks.FireworkRocket;
import Cake.LevelSpecific.Clockwork.Fireworks.FireworkStation;

class AFireworksManager : AHazeActor
{
	UPROPERTY(Category = "References")
	TSubclassOf<AFireworkRocket> RocketClass;
	AFireworkRocket RocketRef;

	TArray<AFireworkRocket> RocketsArray;

	TArray<AFireworkRocket> ActiveRocketArray;

	UPROPERTY()
	TArray<AFireworkStation> FireworkStationArray;

	UPROPERTY(Category = "Setup")
	UForceFeedbackEffect ExplodeRumble;

	int MaxRockets = 55;
	int CurrentRockets;

	int FireworkStationIndex;
	int FireworksMaxIndex;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentRockets = 0;

		while (RocketsArray.Num() < MaxRockets)
		{
		 	RocketRef = Cast<AFireworkRocket>(SpawnActor(RocketClass, FireworkStationArray[0].SpawnLoc.WorldLocation, FireworkStationArray[0].SpawnLoc.WorldRotation, Level = GetLevel()));

			RocketsArray.Add(RocketRef);
			RocketRef.DisableActor(this);
			RocketRef.EventRocketReadyToDisable.AddUFunction(this, n"DisableRocket");
			RocketRef.EventDissipateRocket.AddUFunction(this, n"DissipateRocket");
			RocketRef.EventRemoveActiveRocket.AddUFunction(this, n"RemoveRocket");
		}

		for (AFireworkStation Station : FireworkStationArray)
		{
			// Station.InteractionComp.OnActivated.AddUFunction(this, n"LaunchRocket");
			Station.OnFireworkeExplodedEvent.AddUFunction(this, n"FireworkExplode");
		}

		FireworksMaxIndex = FireworkStationArray.Num() - 1;
	}	

	UFUNCTION()
	void LaunchRocket(UInteractionComponent InteractComp = nullptr, AHazePlayerCharacter Player = nullptr)
	{
		int LaunchAmount = 0;

		if (FireworkStationIndex <= 0)
			FireworkStationIndex = FireworksMaxIndex;
		else
			FireworkStationIndex--;

		AFireworkStation FireworkStationSolo;

		if (InteractComp != nullptr)
			FireworkStationSolo = Cast<AFireworkStation>(InteractComp.Owner);

		FireworkStationSolo = FireworkStationArray[FireworkStationIndex];

		FireworkStationSolo.InitateRocketFeedback();

		for (AFireworkRocket Rocket : RocketsArray)
		{
			if (Rocket.IsActorDisabled() && LaunchAmount < 1)
			{
				Rocket.RocketInitiate(FireworkStationSolo.SpawnLoc.WorldLocation, FireworkStationSolo.EndLoc.ActorLocation, this);
				Rocket.EnableActor(this);
				ActiveRocketArray.Add(Rocket);
				LaunchAmount++;				
			}
		}
	}

	UFUNCTION()
	void FireworkExplode(AHazePlayerCharacter Player)
	{
		if (ActiveRocketArray.Num() <= 0)
			return;

		AFireworkRocket Rocket = ActiveRocketArray[0];
		Rocket.FireworkParticleExplosion();
		ActiveRocketArray.Remove(Rocket);

		if (Player != nullptr)
			Player.PlayForceFeedback(ExplodeRumble, false, true, n"Shoot");
	}

	UFUNCTION()
	void DissipateRocket(AFireworkRocket Rocket)
	{
		DisableRocket(Rocket);
	}

	UFUNCTION()
	void RemoveRocket(AFireworkRocket Rocket)
	{
		ActiveRocketArray.Remove(Rocket);
	}

	UFUNCTION()
	void DisableRocket(AFireworkRocket Rocket)
	{
		if (!Rocket.IsActorDisabled())
			Rocket.DisableActor(this);
	}
}

