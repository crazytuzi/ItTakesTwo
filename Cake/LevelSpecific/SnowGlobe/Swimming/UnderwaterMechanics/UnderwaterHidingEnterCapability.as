import Cake.LevelSpecific.SnowGlobe.Swimming.UnderwaterMechanics.UnderwaterHidingComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UUnderwaterHidingEnterCapability : UCharacterMovementCapability
{
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 90.f;

	AHazePlayerCharacter Player;
	UUnderwaterHidingComponent HidingComp;

	FHazeAcceleratedVector AcceleratedLocation;
	float EnterTime;
	float EnterDuration = 1.f;

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

		if (HidingComp.ActiveHidingPlace != nullptr && HidingComp.ActiveHidingPlace == HidingComp.LastHidingPlace)
			return EHazeNetworkActivation::DontActivate;

		if (HidingComp.ActiveHidingPlace == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (HidingComp.bIsHiding == true)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (HidingComp.ActiveHidingPlace == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (HidingComp.bIsHiding == true)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (Time::GetGameTimeSeconds() > EnterTime)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.SetCapabilityActionState(n"UnderwaterHiding", EHazeActionState::Active);

		AcceleratedLocation.SnapTo(Player.GetActorLocation());

		EnterTime = Time::GetGameTimeSeconds() + EnterDuration;

		HidingComp.HidingLocation = HidingComp.ActiveHidingPlace.Spline.FindLocationClosestToWorldLocation(Player.GetActorLocation(), ESplineCoordinateSpace::World);
		HidingComp.LastHidingPlace = HidingComp.ActiveHidingPlace;

		UGentlemanFightingComponent GentlemanComp = UGentlemanFightingComponent::Get(Player);
		if(GentlemanComp != nullptr)
			GentlemanComp.AddTag(n"FishHiding");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		HidingComp.bIsHiding = true;
	}	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AcceleratedLocation.AccelerateTo(HidingComp.HidingLocation, EnterDuration, DeltaTime);

		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"UnderwaterHidingEnter");

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
