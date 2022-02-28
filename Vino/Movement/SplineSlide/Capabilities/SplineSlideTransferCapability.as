import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.SplineSlide.SplineSlideComponent;
import Vino.Movement.SplineSlide.SplineSlideSettings;
import Rice.Math.MathStatics;
import Vino.Movement.Capabilities.Sliding.CharacterSlidingComponent;
import Vino.Movement.SplineSlide.SplineSlideTags;
import Vino.Movement.SplineSlide.SplineSlideSpline;

class USplineSlideTransferCapability : UCharacterMovementCapability
{	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::SplineSlide);
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 1;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter Player;
	USplineSlideComponent SplineSlideComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		
		Player = Cast<AHazePlayerCharacter>(Owner);
		SplineSlideComp = USplineSlideComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (SplineSlideComp.ActiveSplineSlideSpline == nullptr)
       		return EHazeNetworkActivation::DontActivate;

		if (MoveComp.IsGrounded())
		{	
			ASplineSlideSpline SplineSlide = SplineSlideComp.GetValidSplineForActivation(MoveComp, true);
			if (SplineSlide != nullptr && SplineSlide != SplineSlideComp.ActiveSplineSlideSpline)
				return EHazeNetworkActivation::ActivateLocal;
		}

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SplineSlideComp.ActiveSplineSlideSpline = SplineSlideComp.GetValidSplineForActivation(MoveComp, true);
	}
}