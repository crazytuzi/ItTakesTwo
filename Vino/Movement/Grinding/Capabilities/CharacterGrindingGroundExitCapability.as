import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Vino.Movement.Grinding.GrindingNetworkNames;

class UCharacterGrindingGroundExitCapability : UHazeCapability
{
	default RespondToEvent(GrindingActivationEvents::Grinding);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Grinding);
	default CapabilityTags.Add(GrindingCapabilityTags::Movement);
	default CapabilityTags.Add(GrindingCapabilityTags::Obsctruction);

	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 45;

	UHazeMovementComponent MoveComp;
	UUserGrindComponent UserGrindComp;

	float EvaluatePauseTimer = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		UserGrindComp = UUserGrindComponent::Get(Owner);
		ensure(UserGrindComp != nullptr);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (!UserGrindComp.HasActiveGrindSpline())
			return EHazeNetworkActivation::DontActivate;

		if (UserGrindComp.GetTimeSinceGrindingStarted() < 0.6f)
			return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.HasAnyBlockingHit())
			return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.DownHit.bBlockingHit)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (EvaluatePauseTimer <= 0.f)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		EvaluatePauseTimer = GrindSettings::GroundExit.EvaluatePauseDuration;

		FHitResult DownHit = MoveComp.DownHit;

		FVector Forward = UserGrindComp.SplinePosition.WorldForwardVector;
		Forward = Math::ConstrainVectorToSlope(Forward, DownHit.Normal, MoveComp.WorldUp);

		MoveComp.Velocity = Forward * UserGrindComp.CurrentSpeed;

		if (UserGrindComp.HasActiveGrindSpline())
			UserGrindComp.LeaveActiveGrindSpline(EGrindDetachReason::Obstructed);
		else
			UserGrindComp.ResetTargetGrindSpline();

		Owner.BlockCapabilities(MovementSystemTags::Grinding, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		Owner.UnblockCapabilities(MovementSystemTags::Grinding, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		EvaluatePauseTimer -= DeltaTime;
	}
}
