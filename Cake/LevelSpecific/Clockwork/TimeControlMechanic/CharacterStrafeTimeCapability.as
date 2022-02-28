import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlComponent;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlParams;
import Vino.Camera.Capabilities.CameraTags;

class UCharacterStrafeTimeCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UTimeControlComponent TimeComp;

	float CurrentBlendSpaceX;
	float CurrentBlendSpaceY;

	bool bHasPoi = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		UCharacterMovementCapability::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		TimeComp = UTimeControlComponent::Get(Player);

		Player.AddLocomotionFeature(TimeComp.TimeControlFeature);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Player.RemoveLocomotionFeature(TimeComp.TimeControlFeature);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{	
		if (!TimeComp.IsTimeControlActive())
			return EHazeNetworkActivation::DontActivate;
		if (!ShouldBeGrounded())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!TimeComp.IsTimeControlActive())
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (!ShouldBeGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ActivationParams) const override
	{
		return true;
	}
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{			
		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"CharacterStrafeTime");
			if (HasControl())
			{
				FrameMove.ApplyTargetRotationDelta();
				FrameMove.FlagToMoveWithDownImpact();
			}
			else
			{
				FHazeActorReplicationFinalized ConsumedParams;
				CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
				FrameMove.ApplyConsumedCrumbData(ConsumedParams);
			}

			MoveCharacter(FrameMove, n"TimeControl");
			CrumbComp.LeaveMovementCrumb();
		}
	}
}