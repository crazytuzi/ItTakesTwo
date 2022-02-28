import Cake.LevelSpecific.Music.VolleyBall.Ball.MinigameVollyeballBall;

UCLASS(Abstract)
class AMinigameVollyeballBall_Bomb : AMinigameVolleyballBall
{
	UPROPERTY(EditDefaultsOnly, Category = "Default")
	int SecondsUntilExplosion = 10;

	int CountsUntilExplision = -1;
	float NextUpdateTime = 0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime) override
	{
		Super::Tick(DeltaTime);
		if(CountsUntilExplision > 0 && Time::GetGameTimeSeconds() >= NextUpdateTime)
		{
			NextUpdateTime += 1.f;
			CountsUntilExplision--;
			SetBounceLeftToFail(CountsUntilExplision);
		}
	}

	bool IsValidUpdate(AHazePlayerCharacter Player, FVolleyballHitBallData Data, FVolleyballReplicatedEOLData& OutUpdateData) const override
	{
		if(!Data.bHasTouchedBall && Movement.IsGrounded())
		{
			OutUpdateData.ScoringPlayer = Player.GetOtherPlayer().Player;
			OutUpdateData.EffectToSpawn = GroundImpactEffectType;
			return false;
		}

		if(CountsUntilExplision == 0)
		{
			AHazePlayerCharacter DyingPlayer = nullptr;
			float SmallestDist = BIG_NUMBER;
			auto Players = Game::GetPlayers();
			for(auto PlayerIndex : Players)
			{
				const float DistToBomb = PlayerIndex.GetDistanceTo(this);
				if(DistToBomb < 800.f && DistToBomb < SmallestDist)
				{
					SmallestDist = DistToBomb;
					DyingPlayer = PlayerIndex;
				}
			}

			// Someone was close enough to the bomb
			if(DyingPlayer != nullptr)
				OutUpdateData.ScoringPlayer = DyingPlayer.GetOtherPlayer().Player;

			OutUpdateData.EffectToSpawn = GroundImpactEffectType;
			return false;
		}

		return true;
	}


	FVolleyballHitBallData HitByPlayer(AHazePlayerCharacter Player, bool bPlayerIsGrounded, bool bPlayerIsDashing) override
	{
		FVolleyballHitBallData OutStatus;
		if(ValidBounces == 0 && HasControl())
		{
			Crumb.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_FirstTouch"), FHazeDelegateCrumbParams());	
		}

		if(_MovingType == EMinigameVolleyballMoveType::DecendingToFail)
		{
			OutStatus.bIsBadTouch = true;
			return OutStatus;
		}
		
		const EHazePlayer CurrentControllingPlayer = ControllingPlayer;
		if(!bPlayerIsGrounded)
		{
			if(bPlayerIsDashing)
				AddSmashForce(Player);
			else
				AddUpAndOverForce(Player, FMath::RandRange(100.f, 300.f));	
		}
		else
		{
			AddUpAndOverForce(Player);	
			// if(bPlayerIsDashing)
			// 	AddUpAndOverForce(Player);
			// else
			// 	AddServeForce(Player);
		}

		OutStatus.bSwappedPlayer = ControllingPlayer != CurrentControllingPlayer;

		if(_MovingType == EMinigameVolleyballMoveType::DecendingToFail)
		{
			OutStatus.bHasTouchedBall = false;
			OutStatus.bIsBadTouch = true;
		}
	
		return OutStatus;
	}

	UFUNCTION(NotBlueprintCallable)
	protected void Crumb_FirstTouch(const FHazeDelegateCrumbData& CrumbData)
	{
		NextUpdateTime = Time::GetGameTimeSeconds() + 1;
		CountsUntilExplision = SecondsUntilExplosion;
		SetBounceLeftToFail(CountsUntilExplision);
	}

	void SetBounceLeftToFail(int NewIndex)
	{
		if(NewIndex == 0)
		{
			CodyText.SetText(FText());
			MayText.SetText(FText());
		}
		else
		{
			CodyText.SetText(FText::FromString("" + NewIndex));
			MayText.SetText(FText::FromString("" + NewIndex));
		}
	}

}