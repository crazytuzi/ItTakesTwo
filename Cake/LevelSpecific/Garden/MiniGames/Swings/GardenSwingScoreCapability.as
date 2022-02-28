import Cake.LevelSpecific.Garden.MiniGames.Swings.GardenSwingPlayerComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSystemTags;

class UGardenSwingScoreCapability : UHazeCapability
{
	default CapabilityTags.Add(n"GardenSwings");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UGardenSwingPlayerComponent SwingComp;
	AGardenSwingsActor Swings;

	UGardenSingleSwingComponent PlayerSwing;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SwingComp = UGardenSwingPlayerComponent::Get(Owner);

		Swings = SwingComp.Swings;
		PlayerSwing = SwingComp.CurrentSwing;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(SwingComp.bAwaitingScore)
			return EHazeNetworkActivation::ActivateLocal;
		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!Swings.bMiniGameIsOn)
			return EHazeNetworkDeactivation::DeactivateLocal;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if(Swings.bShowScore)
			return;

		bool bFinishedAnimFeature = false;

		if(Player.IsMay() && HasPlayerFinishedAnims(Game::May))
			bFinishedAnimFeature = true;
		if(Player.IsCody() && HasPlayerFinishedAnims(Game::Cody))
			bFinishedAnimFeature = true;

		if(!bFinishedAnimFeature)
		{
			Swings.OnPlayerFinishedAnimationsOfGardenSwing.AddUFunction(this, n"PlayerFinishedAnimations");
		}
		else
		{
			StartWaitingAnimations();
		}
	}

	bool HasPlayerFinishedAnims(AHazePlayerCharacter Player)
	{
		UGardenSwingPlayerComponent PlayerComp = UGardenSwingPlayerComponent::Get(Player);

		if (PlayerComp != nullptr)
			return PlayerComp.bPlayerFinishedAnimations;
		else
			return false;
	}

	UFUNCTION()
	void StartWaitingAnimations()
	{
		Swings.OnBeforeAnnouncingSwingWinner.AddUFunction(this, n"WinnerAnnounced");

		UAnimSequence StartWaitingAnim = Player.IsMay() ? Swings.MayStartWaitingAnimation : Swings.CodyStartWaitingAnimation;

		FHazeAnimationDelegate OnBlendedIn;
		FHazeAnimationDelegate OnBlendingOut;

		OnBlendingOut.BindUFunction(this, n"StartWaitingAnimFinished");
		
		Player.PlaySlotAnimation(OnBlendedIn, OnBlendingOut, StartWaitingAnim, false);
	}
	
	
	UFUNCTION()
	void PlayerFinishedAnimations(AHazePlayerCharacter FinishedPlayer)
	{
		if(FinishedPlayer != Player)
			return;

		if(Swings.bShowScore)
			return;

		Swings.OnPlayerFinishedAnimationsOfGardenSwing.Clear();

		StartWaitingAnimations();
	}

	UFUNCTION()
	void WinnerAnnounced()
	{
		UAnimSequence StartWaitingAnim = Player.IsMay() ? Swings.MayStartWaitingAnimation : Swings.CodyStartWaitingAnimation;
		UAnimSequence WaitingMHAnim = Player.IsMay() ? Swings.MayWaitingMHAnimation : Swings.CodyWaitingMHAnimation;

		if(Player.IsPlayingAnimAsSlotAnimation(StartWaitingAnim))
			Player.StopAnimationByAsset(StartWaitingAnim);

		if(Player.IsPlayingAnimAsSlotAnimation(WaitingMHAnim))
			Player.StopAnimationByAsset(WaitingMHAnim);

	}

	UFUNCTION()
	void StartWaitingAnimFinished()
	{
		UAnimSequence WaitingMHAnim = Player.IsMay() ? Swings.MayWaitingMHAnimation : Swings.CodyWaitingMHAnimation;

		FHazeAnimationDelegate OnBlendedIn;
		FHazeAnimationDelegate OnBlendingOut;

		Player.PlaySlotAnimation(OnBlendedIn, OnBlendingOut, WaitingMHAnim, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(SwingComp.bFailed)
		{
			SwingComp.bFailed = false;
		}

		Player.UnblockCapabilities(CapabilityTags::Input, Swings);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, Swings);
		Player.UnblockCapabilities(MovementSystemTags::Jump, Swings);
		//Player.UnblockCapabilities(n"CameraControl", Swings);
				
		Swings.ResetSwing(PlayerSwing);
		SwingComp.bAwaitingScore = false;	

		if(Swings.OnBeforeAnnouncingSwingWinner.IsBound())
			Swings.OnBeforeAnnouncingSwingWinner.Clear();
	}

}