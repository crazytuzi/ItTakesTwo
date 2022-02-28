import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Capabilities.Balance.CharacterBalanceComponent;

class UCharacterBalanceCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"Balance");
	default CapabilityTags.Add(CapabilityTags::Movement);

	default CapabilityDebugCategory = n"Movement";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UCharacterBalanceComponent BalanceComp;
	UHazeSplineComponentBase BalanceSpline;
	
	float CurrentDistanceAlongSpline;
	float CurrentRotation;
	bool bBalancing = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		BalanceComp = UCharacterBalanceComponent::GetOrCreate(Owner);
		Super::Setup(SetupParams);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// if (IsActioning(n"Balancing"))
	    // 	return EHazeNetworkActivation::ActivateFromControl;
        
		if (BalanceComp.BalanceSpline != nullptr)
			return EHazeNetworkActivation::ActivateFromControl;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!bBalancing)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		//return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bBalancing = true;
		BalanceSpline = BalanceComp.BalanceSpline;
		FTransform ClosestTransform = BalanceSpline.FindTransformClosestToWorldLocation(Player.ActorLocation, ESplineCoordinateSpace::World);
		BalanceSpline.FindDistanceAlongSplineAtWorldLocation(ClosestTransform.Location, FVector(), CurrentDistanceAlongSpline);
		Player.SmoothSetLocationAndRotation(ClosestTransform.Location, ClosestTransform.Rotator());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		BalanceComp.BalanceSpline = nullptr;
		CurrentDistanceAlongSpline = 0;
		Player.Mesh.SetRelativeRotation(FRotator::ZeroRotator);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeFrameMovement FrameData = MoveComp.MakeFrameMovement(n"Balancing");
		FVector2D MovementInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);

		CurrentDistanceAlongSpline += MovementInput.Y * DeltaTime * 200;

		FVector DeltaMove = BalanceSpline.GetLocationAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World) - Player.ActorLocation;
		FRotator TargetRotation = BalanceSpline.GetRotationAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World);

		MoveComp.SetTargetFacingRotation(TargetRotation);

		FrameData.ApplyDelta(DeltaMove);
		FrameData.OverrideStepUpHeight(0.f);
		FrameData.OverrideStepDownHeight(0.f);
		FrameData.ApplyTargetRotationDelta();

		CurrentRotation += MovementInput.X * DeltaTime * 100;
		Player.Mesh.SetRelativeRotation(FRotator(0,0,CurrentRotation));

		MoveComp.Move(FrameData);

		if (CurrentDistanceAlongSpline >= BalanceSpline.SplineLength || CurrentDistanceAlongSpline < 0)
			bBalancing = false;
	}
}