import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Clockwork.TimeBomb.TimeBombGameManager;
import Cake.LevelSpecific.Clockwork.TimeBomb.PlayerTimeBombComp;
import Peanuts.Fades.FadeStatics;

class UPlayerBombExplodeCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PlayerBombExplodeCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UPlayerTimeBombComp PlayerComp;

	ATimeBombGameManager TimeBombManager;

	bool bCanShowWinner;
	bool bPlayedAnimation;

	float TimeOut = 0.f;
	float MaxTimeOut = 1.8f;
	float Delay;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UPlayerTimeBombComp::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.TimeBombState == ETimeBombState::Explosion)
	        return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.TimeBombState != ETimeBombState::Explosion)
	        return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TimeBombManager = Cast<ATimeBombGameManager>(PlayerComp.TimeBombManager); 

		if (TimeBombManager == nullptr)
			return;

		Player.BlockCapabilities(n"Respawn", this);
		Player.BlockCapabilities(CapabilityTags::Input, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(MovementSystemTags::Swimming, this);
		Player.BlockCapabilities(MovementSystemTags::Grinding, this);
		Player.BlockCapabilities(MovementSystemTags::LedgeGrab, this);
		Player.BlockCapabilities(MovementSystemTags::LedgeGrabJump, this);

		Player.OtherPlayer.BlockCapabilities(n"Respawn", this);
		Player.OtherPlayer.BlockCapabilities(CapabilityTags::Input, this);
		Player.OtherPlayer.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.OtherPlayer.BlockCapabilities(MovementSystemTags::Swimming, this);
		Player.OtherPlayer.BlockCapabilities(MovementSystemTags::Grinding, this);
		Player.OtherPlayer.BlockCapabilities(MovementSystemTags::LedgeGrab, this);
		Player.OtherPlayer.BlockCapabilities(MovementSystemTags::LedgeGrabJump, this);

		Player.TriggerMovementTransition(this);

		if (PlayerComp.TimeBombWinLoseState == ETimeBombWinLoseState::Lose)
		{
			System::SetTimer(this, n"PlayerExplosion", 2.2f, false);
			SetFullScreen();
			UPlayerTimeBombComp OtherPlayerComp; 
			bPlayedAnimation = false;
			OtherPlayerComp = UPlayerTimeBombComp::Get(Player.OtherPlayer);
			OtherPlayerComp.TimeBombState = ETimeBombState::Default;
		}
		else if (PlayerComp.TimeBombWinLoseState == ETimeBombWinLoseState::Draw)
		{
			System::SetTimer(this, n"PlayerExplosion", 2.2f, false);
			bPlayedAnimation = false;
		}

		TimeOut = MaxTimeOut;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TimeOut -= DeltaTime;

		if (!bPlayedAnimation && TimeOut > 0.f)
		{
			if (Player == Game::May && Game::May.MovementComponent.IsGrounded())
			{
				Player.PlaySlotAnimation(Animation = PlayerComp.PanicAnims[0], bLoop = false);
				bPlayedAnimation = true;
			}
			else if (Player == Game::Cody && Game::Cody.MovementComponent.IsGrounded())
			{
				Player.PlaySlotAnimation(Animation = PlayerComp.PanicAnims[1], bLoop = false);
				bPlayedAnimation = true;
			}
		}
	}

	UFUNCTION()
	void SetFullScreen()
	{
		Game::May.ClearViewSizeOverride(TimeBombManager);
		Game::Cody.ClearViewSizeOverride(TimeBombManager);

		Player.ApplyViewSizeOverride(TimeBombManager, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Fast, EHazeViewPointPriority::Cutscene);
	}

	UFUNCTION()
	void PlayerExplosion()
	{
		PlayerComp.BombMesh.BombExplodes();
		Player.KillPlayer(PlayerComp.DeathEffect);
		PlayerComp.PlayCameraShake();
		PlayerComp.AudioBombExplosion();

		if (PlayerComp.TimeBombWinLoseState == ETimeBombWinLoseState::Draw)
			ShowDraw();
		else
			System::SetTimer(this, n"ShowWinner", 0.6f, false);
	}

	UFUNCTION()
	void ShowWinner()
	{
		Game::May.ClearViewSizeOverride(TimeBombManager);
		Game::Cody.ClearViewSizeOverride(TimeBombManager);

		Player.OtherPlayer.ApplyViewSizeOverride(TimeBombManager, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Fast);

		if (HasControl())
			TimeBombManager.ManagerAnnounceWinner(Player);

		System::SetTimer(this, n"FadeScreensAfterExplosion", 2.f, false);
		System::SetTimer(this, n"EnableRespawn", 1.9f, false);
	}

	UFUNCTION()
	void ShowDraw()
	{
		if (HasControl())
			TimeBombManager.ManagerAnnounceDraw();
		
		System::SetTimer(this, n"FadeScreensAfterExplosion", 1.7f, false);
		System::SetTimer(this, n"EnableRespawn", 2.f, false);
	}

	UFUNCTION()
	void FadeScreensAfterExplosion()
	{
		FadeOutPlayer(Game::May, 0.8f, 0.85f, 0.65f); 
		FadeOutPlayer(Game::Cody, 0.8f, 0.85f, 0.65f); 
	}

	UFUNCTION()
	void EnableRespawn()
	{
		Player.UnblockCapabilities(n"Respawn", this);
		Player.UnblockCapabilities(CapabilityTags::Input, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(MovementSystemTags::Swimming, this);
		Player.UnblockCapabilities(MovementSystemTags::Grinding, this);
		Player.UnblockCapabilities(MovementSystemTags::LedgeGrab, this);
		Player.UnblockCapabilities(MovementSystemTags::LedgeGrabJump, this);

		Player.OtherPlayer.UnblockCapabilities(n"Respawn", this);
		Player.OtherPlayer.UnblockCapabilities(CapabilityTags::Input, this);
		Player.OtherPlayer.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.OtherPlayer.UnblockCapabilities(MovementSystemTags::Swimming, this);
		Player.OtherPlayer.UnblockCapabilities(MovementSystemTags::Grinding, this);
		Player.OtherPlayer.UnblockCapabilities(MovementSystemTags::LedgeGrab, this);
		Player.OtherPlayer.UnblockCapabilities(MovementSystemTags::LedgeGrabJump, this);
	}
}