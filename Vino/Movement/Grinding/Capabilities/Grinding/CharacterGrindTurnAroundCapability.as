import Vino.Movement.MovementSystemTags;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.Grinding.GrindSettings;
import Vino.Movement.Components.MovementComponent;

class UCharacterGrindingTurnAroundCapability : UHazeCapability
{
	default RespondToEvent(GrindingActivationEvents::Grinding);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::Grinding);
	default CapabilityTags.Add(GrindingCapabilityTags::Movement);
	default CapabilityTags.Add(GrindingCapabilityTags::TurnAround);

	default CapabilityDebugCategory = n"Grinding";	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 110;

	AHazePlayerCharacter Player;
	UUserGrindComponent UserGrindComp;
	UHazeMovementComponent MoveComp;

	float Deceleration = 0.f;
	bool bDecelerating = true;

	const float ExitSpeed = 4400.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		UserGrindComp = UUserGrindComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!UserGrindComp.HasActiveGrindSpline())
        	return EHazeNetworkActivation::DontActivate;

		if (UserGrindComp.ActiveGrindSpline.TravelDirection != EGrindSplineTravelDirection::Bidirectional)
        	return EHazeNetworkActivation::DontActivate;

		if (!UserGrindComp.ActiveGrindSpline.bCanTurnAround)
        	return EHazeNetworkActivation::DontActivate;

		if (DeactiveDuration < GrindSettings::TurnAround.Cooldown)
        	return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::MovementDash))
        	return EHazeNetworkActivation::DontActivate;

		FVector MoveInput = GetAttributeVector(AttributeVectorNames::MovementDirection);
		FVector Tangent = UserGrindComp.SplinePosition.WorldForwardVector.ConstrainToPlane(MoveComp.WorldUp);
		Tangent.Normalize();

		float TangentInputDot = Tangent.DotProduct(MoveInput.GetSafeNormal());
		float AngleDifference = Math::DotToDegrees(TangentInputDot);
		if (AngleDifference < GrindSettings::TurnAround.RequiredAngle)
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!UserGrindComp.HasActiveGrindSpline())
        	return EHazeNetworkDeactivation::DeactivateLocal;

		if (!FMath::IsNearlyZero(UserGrindComp.CurrentSpeed))
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(GrindingCapabilityTags::Dash, this);
		Player.BlockCapabilities(GrindingCapabilityTags::Speed, this);
		Player.BlockCapabilities(GrindingCapabilityTags::Jump, this);
		Player.BlockCapabilities(GrindingCapabilityTags::Transfer, this);

		bDecelerating = true;

		Deceleration = UserGrindComp.CurrentSpeed / GrindSettings::TurnAround.DecelerationTime;

		MoveComp.SetSubAnimationTagToBeRequested(n"TurnAround");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UserGrindComp.CurrentSpeed = ExitSpeed;

		Player.UnblockCapabilities(GrindingCapabilityTags::Dash, this);
		Player.UnblockCapabilities(GrindingCapabilityTags::Speed, this);		
		Player.UnblockCapabilities(GrindingCapabilityTags::Jump, this);
		Player.UnblockCapabilities(GrindingCapabilityTags::Transfer, this);
	}	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bDecelerating)
		{
			float DeltaDeceleration = Deceleration * DeltaTime;			
			UserGrindComp.CurrentSpeed -= FMath::Min(UserGrindComp.CurrentSpeed, DeltaDeceleration);
			
			if (FMath::IsNearlyZero(UserGrindComp.CurrentSpeed) || UserGrindComp.CurrentSpeed < 0.f)
			{
				bDecelerating = false;
				UserGrindComp.FollowComp.Reverse();

				MoveComp.SetSubAnimationTagToBeRequested(n"TurnAroundCompleted");
			}
		}
	}
}
