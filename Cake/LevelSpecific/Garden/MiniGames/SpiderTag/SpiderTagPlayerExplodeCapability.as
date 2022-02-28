import Cake.LevelSpecific.Garden.MiniGames.SpiderTag.SpiderTagPlayerComp;

class USpiderTagPlayerExplodeCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PlayerBombExplodeCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	USpiderTagPlayerComp PlayerComp;

	bool bCanShowWinner;

	float Delay;

	float Timer;

	bool bHaveExploded;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = USpiderTagPlayerComp::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.SpiderTagPlayerState == ESpiderTagPlayerState::Exploding)
	        return EHazeNetworkActivation::ActivateFromControl;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.SpiderTagPlayerState != ESpiderTagPlayerState::Exploding)
	        return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// System::SetTimer(this, n"ExplosionEvent", 1.2f, false);
		Timer = 1.f;
		bHaveExploded = true;
		ExplosionEvent();
		// Player.KillPlayer(PlayerComp.DeathEffect);

		if (HasControl())
			PlayerComp.OnTagPlayerExplodedEvent.Broadcast(Player);
	}

	UFUNCTION()
	void ExplosionEvent()
	{
		System::SetTimer(this, n"DelayedEventBroadcast", 2.f, false);
	}

	UFUNCTION()
	void DelayedEventBroadcast()
	{
		PlayerComp.OnTagPlayerAnnounceWinnerEvent.Broadcast(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bHaveExploded)
			return;

		Timer -= DeltaTime;

		if (Timer <= 0.f)
		{
			Print("Kill Player from Tick");
			Player.KillPlayer(PlayerComp.DeathEffect);

			// if (HasControl())
			// 	NetKillPlayer();

			// PlayerComp.BombMesh.BombExplodes();
			bHaveExploded = false;
		}
	}

	UFUNCTION(NetFunction)
	void NetKillPlayer()
	{
		// Player.KillPlayer(PlayerComp.DeathEffect);
	}
}