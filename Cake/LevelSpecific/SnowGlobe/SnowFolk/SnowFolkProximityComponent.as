event void FOnPlayerEnterProximitySignature(AHazePlayerCharacter Player, bool bFirstEnter);
event void FOnPlayerLeaveProximitySignature(AHazePlayerCharacter Player, bool bLastLeave);

struct FSnowFolkProximityData
{
	UPROPERTY()
	float Distance = MAX_flt;
	UPROPERTY()
	float PreviousDistance = MAX_flt;
}

class USnowFolkProximityComponent : UActorComponent
{
	UPROPERTY(Category = "Proximity")
	float ProximityRadius = 1000.f;

	UPROPERTY(Category = "Proximity")
	FOnPlayerEnterProximitySignature OnEnterProximity;
	UPROPERTY(Category = "Proximity")
	FOnPlayerLeaveProximitySignature OnLeaveProximity;

	TArray<AHazePlayerCharacter> ProximityPlayers;
	private TPerPlayer<FSnowFolkProximityData> ProximityData;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float ProximitySqr = FMath::Square(ProximityRadius);
		for (auto Player : Game::Players)
		{
			float DistanceSqr = (Player.ActorLocation - Owner.ActorLocation).SizeSquared();

			FSnowFolkProximityData& Proximity = ProximityData[Player.Player];
			Proximity.PreviousDistance = Proximity.Distance;
			Proximity.Distance = DistanceSqr;

			// Check whether we had any players in proximity prior to updating
			bool bWasAnyProximity = IsAnyProximity();
			bool bWasProximity = ProximityPlayers.Contains(Player);
			bool bProximity = (DistanceSqr < ProximitySqr);

			if (bProximity && !bWasProximity)
			{
				ProximityPlayers.Add(Player);
				OnEnterProximity.Broadcast(Player, !bWasAnyProximity);
			}
			else if (!bProximity && bWasProximity)
			{
				ProximityPlayers.Remove(Player);
				OnLeaveProximity.Broadcast(Player, !IsAnyProximity());
			}
		}

		// Slow down tick while nobody is within proximity
		SetComponentTickInterval(IsAnyProximity() ? 0.f : 0.1f);
	}

	UFUNCTION()
	float GetDistance(AHazePlayerCharacter Player)
	{
		return ProximityData[Player.Player].Distance;
	}

	UFUNCTION()
	float GetPreviousDistance(AHazePlayerCharacter Player)
	{
		return ProximityData[Player.Player].PreviousDistance;
	}

	UFUNCTION()
	bool IsPlayerProximity(AHazePlayerCharacter Player)
	{
		return ProximityPlayers.Contains(Player);
	}

	UFUNCTION()
	bool IsAnyProximity()
	{
		return ProximityPlayers.Num() != 0;
	}

	UFUNCTION()
	AHazePlayerCharacter GetClosestPlayer()
	{
		float CurrentDistance = MAX_flt;
		AHazePlayerCharacter CurrentPlayer = nullptr;
		
		for (auto Player : ProximityPlayers)
		{
			float Distance = ProximityData[Player.Player].Distance;
			if (Distance < CurrentDistance)
			{
				CurrentDistance = Distance;
				CurrentPlayer = Player;
			}
		}

		return CurrentPlayer;
	}
}