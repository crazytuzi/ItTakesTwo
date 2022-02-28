import Cake.LevelSpecific.SnowGlobe.Swimming.UnderwaterMechanics.UnderwaterHidingComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UUnderwaterHidingHiddenCapability : UCharacterMovementCapability
{
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 100.f;

	AHazePlayerCharacter Player;
	UUnderwaterHidingComponent HidingComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		HidingComp = UUnderwaterHidingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (HidingComp.bIsHiding != true)
			return EHazeNetworkActivation::DontActivate;

		if (HidingComp.ActiveHidingPlace == nullptr)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (HidingComp.bIsHiding != true)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (HidingComp.ActiveHidingPlace == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;	

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"UnderwaterHidingHidden");

		if (HasControl())
		{
//			MoveData.ApplyDelta(0);
//			MoveData.ApplyTargetRotationDelta();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			MoveData.ApplyConsumedCrumbData(ConsumedParams);
			MoveData.SetRotation(FQuat(ConsumedParams.Rotation));
		}

		MoveData.OverrideStepDownHeight(0.f);
		MoveData.OverrideGroundedState(EHazeGroundedState::Airborne);
		MoveCharacter(MoveData, FeatureName::Swimming);
		CrumbComp.LeaveMovementCrumb();
	}

}
