
class ATownsFolkDisabler : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent, Category = "Disable")
	USphereComponent VisualRange;
	default VisualRange.SetCollisionProfileName(n"NoCollision");
	default VisualRange.bGenerateOverlapEvents = false;
	default VisualRange.SphereRadius = 1000.f;

	UPROPERTY(Category = "Disable")
	float MaxVisualRange = 14000.f;

	UPROPERTY(EditInstanceOnly, Category = "Disable")
	TArray<AHazeActor> Members;

	TPerPlayer<bool> bIsDisabledByPlayer;
	TArray<AHazePlayerCharacter> ControllerPlayers;
	float TimeToCheckDisable = 0.f;

	uint LastFrameDisabled = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto Players = Game::GetPlayers();
		for(auto Player : Players)
		{
			if(Player.HasControl())
				ControllerPlayers.Add(Player);
		}

		TimeToCheckDisable = FMath::RandRange(0.f, 1.f);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(TimeToCheckDisable > 0)
		{
			TimeToCheckDisable -= DeltaSeconds;
		}
		else
		{
			const bool bWantsToBeDisabled = ShouldAutoDisable();
			if(Network::IsNetworked())
			{
				for(auto Player : ControllerPlayers)
				{
					if(bIsDisabledByPlayer[Player] != bWantsToBeDisabled)
						NetSetDisabled(Player.Player, bWantsToBeDisabled);
				}
			}
			else
			{	
				if(IsDisabled() != bWantsToBeDisabled)
				{
					bIsDisabledByPlayer[0] = bIsDisabledByPlayer[1] = bWantsToBeDisabled;
					SetActorDisabledInternal(bWantsToBeDisabled);
				}
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetSetDisabled(EHazePlayer Player, bool bStatus)
	{
		const bool bWasDisabled = IsDisabled();
		bIsDisabledByPlayer[Player] = bStatus;
		if(bWasDisabled != IsDisabled())
		{
			SetActorDisabledInternal(!bWasDisabled);
		}
	}

	bool IsDisabled() const
	{
		return bIsDisabledByPlayer[0] && bIsDisabledByPlayer[1];
	}

	private bool ShouldAutoDisable()
	{
		const float MaxRange = FMath::Square(MaxVisualRange);

		float ClosestPlayerDistSq = BIG_NUMBER;
		auto Players = ControllerPlayers;
		for(auto Player : Players)
		{
			const float Dist = Player.GetActorLocation().DistSquared(GetActorLocation());
			if(Dist >= MaxRange)
				continue;

			if(Dist < FMath::Square(VisualRange.GetScaledSphereRadius()))
			{
				TimeToCheckDisable = 1.f;
			 	return false;
			}

			if(Dist < ClosestPlayerDistSq)
				ClosestPlayerDistSq = Dist;

			if(SceneView::ViewFrustumSphereIntersection(Player, VisualRange))
			{
				TimeToCheckDisable = 1.f;
				return false;
			}
		}

		// The longer away we are, the longer time we need to validate again
		float TimeAlpha = FMath::Max(ClosestPlayerDistSq - MaxRange, 0.f);
		TimeAlpha =	FMath::Min(TimeAlpha / MaxRange * 2, 1.f);
		TimeToCheckDisable = FMath::Lerp(0.1f, 1.f, TimeAlpha);
		return true;
	}

	private void SetActorDisabledInternal(bool bStatus)
	{
		if(bStatus)
		{
			LastFrameDisabled = Time::GetFrameNumber();
			for(auto Member : Members)
			{
				Member.DisableActor(this);
			}	
		}
		else
		{
			if(Time::GetFrameNumber() < LastFrameDisabled + 2)
			{
				int test = 0;
			}


			for(auto Member : Members)
			{
				Member.EnableActor(this);	
			}	
		}
	}
}