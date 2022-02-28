import Vino.MinigameScore.PlayerMinigameComponent;
import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.Movement.MovementSystemTags;
import Vino.MinigameScore.MinigameStatics;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;

class UPlayerMinigameReactionCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PlayerMinigameReactionCapability");
	default CapabilityTags.Add(MinigameCapabilityTags::Minigames);

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 110;

	AHazePlayerCharacter Player;
	
	UPlayerMinigameComponent PlayerMinigameComp;
	USnowGlobeSwimmingComponent SwimmingComp;

	UAnimSequence SequenceToPlay;

	int PlayIndex;
	int MaxPlayIndexWin;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerMinigameComp = UPlayerMinigameComponent::Get(Player);
		MaxPlayIndexWin = PlayerMinigameComp.LocoReaction[Player].Won.GetNumAnimations() - 1;
		SwimmingComp = USnowGlobeSwimmingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (SwimmingComp == nullptr)
			SwimmingComp = USnowGlobeSwimmingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (PlayerMinigameComp.PlayerMinigameReactionState == EPlayerMinigameReactionState::Inactive)
			return EHazeNetworkActivation::DontActivate;

		if (SwimmingComp != nullptr)
			if (SwimmingComp.IsSwimmingActive())
       	 		return EHazeNetworkActivation::ActivateUsingCrumb;

		if (!Player.MovementComponent.IsGrounded())
			return EHazeNetworkActivation::DontActivate;

		if (Player.IsAnyCapabilityActive(MovementSystemTags::GroundPound))
			return EHazeNetworkActivation::DontActivate;

		if (Player.IsAnyCapabilityActive(n"CharacterJumpToCapability"))
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (PlayerMinigameComp.PlayerMinigameReactionState == EPlayerMinigameReactionState::Active && !Player.IsPlayerDead())
			return EHazeNetworkDeactivation::DontDeactivate;
		
		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		PlayIndex = FMath::RandRange(0, MaxPlayIndexWin);
		EMinigameAnimationPlayerState EndState = PlayerMinigameComp.MinigameAnimationPlayerState;
		ActivationParams.AddValue(n"PlayIndex", PlayIndex);
		ActivationParams.AddNumber(n"EndState", EndState);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(CapabilityTags::Interaction, this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(CapabilityTags::Weapon, this);
		Player.TriggerMovementTransition(this);

		if (SwimmingComp != nullptr)
		{
			if (SwimmingComp.IsSwimmingActive())
			{
				ReactionAnimCompleted();
				return;
			}
		}

		UAnimSequence WinSequence = PlayerMinigameComp.LocoReaction[Player].Won.GetAnimationFromIndex(ActivationParams.GetValue(n"PlayIndex"));
		UAnimSequence LoseSequence = PlayerMinigameComp.LocoReaction[Player].Lost.GetAnimationFromIndex(0);
		int EndState = ActivationParams.GetNumber(n"EndState");
		EMinigameAnimationPlayerState MinigamePlayerState;

		switch (EndState)
		{
			case 0: 
				MinigamePlayerState = EMinigameAnimationPlayerState::WinnerAnim;
			break;

			case 1:
				MinigamePlayerState = EMinigameAnimationPlayerState::LoserAnim;
			break;
		}

		FHazeAnimationDelegate OnBlendOutDelegate;
		OnBlendOutDelegate.BindUFunction(this, n"ReactionAnimCompleted");

		if (MinigamePlayerState == EMinigameAnimationPlayerState::WinnerAnim)
			Player.PlaySlotAnimation(Animation = WinSequence, BlendTime = 0.4f, OnBlendingOut = OnBlendOutDelegate);
		else
			Player.PlaySlotAnimation(Animation = LoseSequence, BlendTime = 0.4f, OnBlendingOut = OnBlendOutDelegate);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Weapon, this);
		
		if (!Player.IsPlayerDead())
			PlayerMinigameComp.OnMinigameReactionAnimationComplete.Broadcast(Player);
	}

	UFUNCTION()
	void ReactionAnimCompleted()
	{
		PlayerMinigameComp.PlayerMinigameReactionState = EPlayerMinigameReactionState::Inactive;
	}
}