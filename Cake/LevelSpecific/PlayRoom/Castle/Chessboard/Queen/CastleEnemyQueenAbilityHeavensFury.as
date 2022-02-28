import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.Queen.CastleEnemyQueenHeavensFury;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.CastleEnemyBossAbilitiesComponent;

class UCastleEnemyQueenAbilityHeavensFury : UHazeCapability
{
	default CapabilityTags.Add(n"QueenAbility");
    default CapabilityTags.Add(n"CastleEnemyAI");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	ACastleEnemy Enemy;
	UChessPieceComponent PieceComp;
	UCastleEnemyBossAbilitiesComponent AbilitiesComp; 

	UPROPERTY()
	TSubclassOf<ACastleEnemyQueenHeavensFury> HeavensFury;
	TPerPlayer<ACastleEnemyQueenHeavensFury> HeavensFuryRefs;
	ACastleEnemyQueenHeavensFury HeavensFuryRef;

	UPROPERTY()
	float Duration = 12.f;
	UPROPERTY()
	float DurationCurrent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Enemy = Cast<ACastleEnemy>(Owner);
        PieceComp = UChessPieceComponent::GetOrCreate(Owner);
		AbilitiesComp = UCastleEnemyBossAbilitiesComponent::GetOrCreate(Owner);		
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!AbilitiesComp.ShouldStartAbility(this))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		TickDuration(DeltaTime);
	}

	void TickDuration(float DeltaTime)
	{
		if (DurationCurrent < Duration)
			DurationCurrent += DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (DurationCurrent >= Duration)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		DurationCurrent = 0.f;

		if (HeavensFury.IsValid())
		{
			for (AHazePlayerCharacter iPlayer : Game::GetPlayers())
			{
				HeavensFuryRefs[iPlayer] = Cast<ACastleEnemyQueenHeavensFury>(SpawnActor(HeavensFury, Owner.ActorLocation));
				HeavensFuryRefs[iPlayer].TargetPlayer = Player;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		for (AHazePlayerCharacter iPlayer : Game::GetPlayers())
		{
			HeavensFuryRefs[iPlayer].DestroyActor();
			HeavensFuryRefs[iPlayer] = nullptr;
		}

		AbilitiesComp.AbilityFinished();
	}
}
