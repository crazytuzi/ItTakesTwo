import Cake.LevelSpecific.Music.VolleyBall.Player.MinigameVolleyballPlayer;
import Cake.LevelSpecific.Music.VolleyBall.Ball.MinigameVollyeballBall;

class UMinigameVolleyballPlayerLogicCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UMinigameVolleyballPlayerComponent VolleyballComponent;

	//float TimeLeftToSpawnBall = 0;
	//bool bExtraBallIsGood = true;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        Player = Cast<AHazePlayerCharacter>(Owner);
		VolleyballComponent = UMinigameVolleyballPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(!VolleyballComponent.Field.bGameHasStarted)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!VolleyballComponent.Field.bGameHasStarted)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for(int i = VolleyballComponent.Balls.Num() - 1; i >= 0; --i)
		{
			UpdateBall(VolleyballComponent.Balls[i]);
		}
	}

	UFUNCTION(NetFunction)
	protected void NetSpawnExtraBall(FVolleyballSpawnBallData Data)
	{
		SpawnBall(Data);
	}

	void UpdateBall(AMinigameVolleyballBall Ball)
	{
		// This is so the movement component has time to update itself
		if(!Ball.bHasBeenUpdatedByAPlayer)
		{
			Ball.bHasBeenUpdatedByAPlayer = true;
			return;
		}

		// This ball has left the playfield... should never happen
		if(Ball.bIsOutsidePlayField)
		{
			FVolleyballReplicatedEOLData OutOffField(Ball);
			OutOffField.EffectToSpawn = Ball.GroundImpactEffectType;
			SpawnNewBall(GetNewBallSpawnData(OutOffField));
			EndBall(OutOffField);
			ensure(false);
			return;
		}

		FVolleyballHitBallData HasHitBallData;
		const FVector BallVelocity = Ball.GetActorVelocity();
		if (Trace::ComponentOverlapComponent(
			Player.CapsuleComponent,
			Ball.ImpactSize,
			Ball.Root.WorldLocation,
			Ball.Root.ComponentQuat,
			bTraceComplex = false
		))
		{
			const bool bGrounded = !IsActioning(DashTags::AirDashing) && (Player.MovementComponent.IsGrounded() ||  IsActioning(DashTags::GroundDashing));
			const bool bIsDashing = IsActioning(DashTags::AirDashing) || IsActioning(DashTags::GroundDashing);
			HasHitBallData = Ball.HitByPlayer(Player, bGrounded, bIsDashing);
		}

		FVolleyballReplicatedEOLData UpdateData(Ball);
		if(Ball.IsValidUpdate(Player, HasHitBallData, UpdateData))
		{
			if(HasHitBallData.bSwappedPlayer && 
				(Ball.bIsMainBall && Ball.MainBallBouncsesLeftToNewBall == 0)
				|| (!Ball.bIsMainBall && VolleyballComponent.Field.ActiveBallTime > 6 && VolleyballComponent.Field.Balls.Num() == 1))
			{
				FVolleyballSpawnBallData SpawnData;
				SpawnData.ForPlayer = Player.Player;
				SpawnData.SpawnFromBall = Ball;
				if(Ball.bIsMainBall)
				{
					SpawnData.BallToApplyTo = Ball;
					SpawnData.MainBallBouncesToNewBall = FMath::RandRange(3, 5);
				}

				// Initialize the next ball to spawn
				if(VolleyballComponent.Field.GoodBallSpawnsSinceEvilBall > 1 
					&& FMath::RandRange(VolleyballComponent.Field.GoodBallSpawnsSinceEvilBall, 10) > 6)
				{
					VolleyballComponent.Field.GetEvilBallTypeToSpawn(SpawnData);
				}
				else
				{
					VolleyballComponent.Field.GetGoodBallTypeToSpawn(SpawnData);
				}

				//SpawnNewBall(SpawnData);
				NetSpawnExtraBall(SpawnData);
			}
		}
		else
		{
			SpawnNewBall(GetNewBallSpawnData(UpdateData));
			EndBall(UpdateData);
		}
	}

	FVolleyballSpawnBallData GetNewBallSpawnData(FVolleyballReplicatedEOLData UpdateData) const
	{
		FVolleyballSpawnBallData SpawnData;
		SpawnData.MainBallBouncesToNewBall = FMath::RandRange(3, 5);
		if(UpdateData.ScoringPlayer != EHazePlayer::MAX)
			SpawnData.ForPlayer = UpdateData.ScoringPlayer;
		else
			SpawnData.ForPlayer = Player.GetOtherPlayer().Player;

		VolleyballComponent.Field.GetGoodBallTypeToSpawn(SpawnData);
		SpawnData.SpawnFromBall = UpdateData.Ball;
		return SpawnData;
	}

	void SpawnNewBall(FVolleyballSpawnBallData SpawnData)
	{
		for(auto PlayerWithScore : Game::GetPlayers())
		{
			if(VolleyballComponent.Field.GetPlayerScore(PlayerWithScore) >= VolleyballComponent.Field.ScoreToWin)
				return;
		}

		if(VolleyballComponent.Balls.Num() > 1)
			return;

		FHazeDelegateCrumbParams Params;
		Params.AddStruct(n"SpawnBall", SpawnData);
		ensure(SpawnData.ForPlayer != EHazePlayer::MAX);
		SpawnData.SpawnFromBall.Crumb.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_SpawnBall"), Params);
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_SpawnBall(const FHazeDelegateCrumbData& CrumbData)
	{
		FVolleyballSpawnBallData SpawnData;
		CrumbData.GetStruct(n"SpawnBall", SpawnData);
		if(SpawnData.Class.IsValid())
		{
			SpawnBall(SpawnData);
		}
	}

	void EndBall(FVolleyballReplicatedEOLData UpdateData)
	{
		FHazeDelegateCrumbParams Params;
		Params.AddStruct(n"Ball", UpdateData);
		UpdateData.Ball.Crumb.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_DestroyBall"), Params);
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_DestroyBall(const FHazeDelegateCrumbData& CrumbData)
	{
		FVolleyballReplicatedEOLData BallData;
		CrumbData.GetStruct(n"Ball", BallData);

		// Give score to player if we have that
		if(BallData.ScoringPlayer != EHazePlayer::MAX)
		{
			auto ScoringPlayer = Game::GetPlayer(BallData.ScoringPlayer);
			VolleyballComponent.Field.GiveScoreToPlayer(BallData.ScoringPlayer);
			VolleyballComponent.Field.ShowWorldScoreWidget(Game::GetPlayer(BallData.ScoringPlayer), BallData.Ball);
			Niagara::SpawnSystemAttached(
				UMinigameVolleyballPlayerComponent::Get(ScoringPlayer).GiveScoreEffectType, 
				ScoringPlayer.Mesh, 
				NAME_None, 
				FVector::ZeroVector, 
				FRotator::ZeroRotator, 
				EAttachLocation::SnapToTarget, 
				true);
		}

		// Spawn effect if we have that
		if(BallData.EffectToSpawn != nullptr)
		{
			Niagara::SpawnSystemAtLocation(BallData.EffectToSpawn, BallData.Ball.GetActorLocation(), BallData.Ball.GetActorRotation());
		}
		UHazeAkComponent::HazePostEventFireForget(BallData.Ball.BallDestroyedAudioEvent, BallData.Ball.GetActorTransform());
		DestroyBall(BallData.Ball);
	}
}