
import Cake.FlyingMachine.Melee.Capability.FlyingMachineMeleeCapabilityBase;
import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleePlayerComponent;
import Cake.FlyingMachine.Melee.LocomotionFeatures.LocomotionFeaturePlaneFightDodge;
import Cake.FlyingMachine.Melee.LocomotionFeatures.LocomotionFeaturePlaneFightAttack;

class UFlyingMachineMeleePlayerActionInputCapability : UFlyingMachineMeleeCapabilityBase
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MeleeTags::Melee);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(MeleeTags::MeleeBlockedWhenGrabbed);
	
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 101;

	default CapabilityDebugCategory = MeleeTags::Melee;

	AHazePlayerCharacter Player;
	UFlyingMachineMeleePlayerComponent PlayerMeleeComponent;
	EHazeMeleeActionInputType ActivatedAction = EHazeMeleeActionInputType::None;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerMeleeComponent = Cast<UFlyingMachineMeleePlayerComponent>(MeleeComponent);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(MeleeComponent.ActionInputIsBlocked())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(MeleeComponent.ActionInputIsBlocked())
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
		PlayerMeleeComponent.PendingActivationData.Clear();
		ResetActionInput(ActivatedAction);
		ActivatedAction = EHazeMeleeActionInputType::None;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		bool bJumping = false;
		PlayerMeleeComponent.PendingActivationData.Clear();
		EHazeMeleeActionInputType CurrentAction = EHazeMeleeActionInputType::None;
		
		if(WasActionStartedDuringTime(ActionNames::MeleePunch, 0.1f))
		{
			CurrentAction = EHazeMeleeActionInputType::Punch;
		}
		else if(WasActionStartedDuringTime(ActionNames::MeleeKick, 0.1f))
		{
			CurrentAction = EHazeMeleeActionInputType::Kick;
		}
		
		if(CurrentAction != EHazeMeleeActionInputType::None)
		{
			FHazeMeleeInputAmount Input;
			if(MeleeComponent.GetMovementInput(Input))
			{
				if(MeleeComponent.IsGrounded())
				{
					if(Input.StickType == EHazeMeleeStickInputType::Bwd
					|| Input.StickType == EHazeMeleeStickInputType::BwdDown
					|| Input.StickType == EHazeMeleeStickInputType::BwdUp)
						CurrentAction = EHazeMeleeActionInputType::Reaction;
				}	
			}
		}

		if(CurrentAction != ActivatedAction)
		{
			SetActionInput(CurrentAction);
			ActivatedAction = CurrentAction;
			PlayerMeleeComponent.PendingActivationData.ActionType = ActivatedAction;
			if(CurrentAction == EHazeMeleeActionInputType::Reaction)
				PlayerMeleeComponent.PendingActivationData.Feature = MeleeComponent.GetFeatureOfClass(UHazeLocomotionFeaturePlaneFightDodge::StaticClass());
			else
				PlayerMeleeComponent.PendingActivationData.Feature = MeleeComponent.GetFeatureOfClass(ULocomotionFeaturePlaneFightAttack::StaticClass());
		}
	}
}

