import Cake.LevelSpecific.SnowGlobe.Swimming.UnderwaterMechanics.UnderwaterHidingComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UUnderwaterHidingExitCapability : UCharacterMovementCapability
{
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 80.f;

	AHazePlayerCharacter Player;
	UUnderwaterHidingComponent HidingComp;

	float ExitDuration = 1.f;
	float ExitTime;
	FVector ExitLocation;
	FHazeAcceleratedVector AcceleratedLocation;

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

	    if (!WasActionStarted(ActionNames::MovementJump))
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (Time::GetGameTimeSeconds() > ExitTime)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AcceleratedLocation.SnapTo(Player.GetActorLocation());

		ExitLocation = Player.GetPlayerViewLocation() + Player.GetPlayerViewRotation().ForwardVector * 1000.f;
		ExitTime = Time::GetGameTimeSeconds() + ExitDuration;

		HidingComp.bIsHiding = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.SetCapabilityActionState(n"UnderwaterHiding", EHazeActionState::Inactive);

		UGentlemanFightingComponent GentlemanComp = UGentlemanFightingComponent::Get(Player);
		if(GentlemanComp != nullptr)
			GentlemanComp.RemoveTag(n"FishHiding");
	}	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		AcceleratedLocation.AccelerateTo(ExitLocation, ExitDuration, DeltaTime);

		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"UnderwaterHidingExit");

		if (HasControl())
		{
			MoveData.ApplyDelta(AcceleratedLocation.Value - Player.GetActorLocation());
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
