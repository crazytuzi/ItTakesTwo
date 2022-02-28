import Vino.Interactions.ThreeShotInteraction;
import Cake.LevelSpecific.Clockwork.LeaveCloneMechanic.PlayerTimeSequenceComponent;

/* A three shot interaction that may can teleport out of with her clockwork ability. */
class ATeleportableThreeShotInteraction : AThreeShotInteraction
{
    UFUNCTION(NotBlueprintCallable, BlueprintOverride)
    void OnTriggerComponentActivated(UHazeTriggerComponent Trigger, AHazePlayerCharacter Player)
    {
		Super::OnTriggerComponentActivated(Trigger, Player);
		if (Player.IsMay())
		{
			Player.AddCapability(n"TeleportableThreeShotCancelCapability");
			Player.SetCapabilityActionState(n"ThreeShotTeleportable", EHazeActionState::Active);
		}
	}

	void AnimationEndBlendingOut() override
	{
		if (ActivePlayer != nullptr)
			ActivePlayer.SetCapabilityActionState(n"ThreeShotTeleportable", EHazeActionState::Inactive);
		Super::AnimationEndBlendingOut();
	}
};

class UTeleportableThreeShotCancelCapability : UHazeCapability
{
    default CapabilityTags.Add(n"CancelAction");
    default CapabilityTags.Add(n"Animation");

	UThreeShotAnimationComponent ThreeShotComponent;
	UTimeControlSequenceComponent SequenceComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        ThreeShotComponent = UThreeShotAnimationComponent::GetOrCreate(Owner);
		SequenceComp = UTimeControlSequenceComponent::Get(Owner);
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
    {
        if (ThreeShotComponent.CurrentAnimation == nullptr)
            return EHazeNetworkActivation::DontActivate;
		if (SequenceComp == nullptr || !SequenceComp.IsCloneActive())
            return EHazeNetworkActivation::DontActivate;
        if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkActivation::DontActivate;
        if (!IsActioning(n"ThreeShotTeleportable"))
			return EHazeNetworkActivation::DontActivate;
        if (!ThreeShotComponent.HasCancelableThreeShots())
            return EHazeNetworkActivation::DontActivate;
        return EHazeNetworkActivation::ActivateLocal;
    }

    UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
    {
		return EHazeNetworkDeactivation::DeactivateLocal;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams Params)
    {
		ThreeShotComponent.NetForceStopThreeShots();
    }
};