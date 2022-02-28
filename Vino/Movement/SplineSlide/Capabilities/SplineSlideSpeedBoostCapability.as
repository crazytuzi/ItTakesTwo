import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.SplineSlide.SplineSlideComponent;
import Vino.Movement.SplineSlide.SplineSlideSettings;
import Rice.Math.MathStatics;
import Vino.Movement.Capabilities.Sliding.CharacterSlidingComponent;
import Vino.Movement.SplineSlide.SplineSlideTags;
import Vino.Movement.SplineSlide.SplineSlideSpline;
import Vino.Movement.SplineSlide.SplineSlideSpeedBoost;

class USplineSlideSpeedBoostCapability : UCharacterMovementCapability
{	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::SplineSlide);
	default CapabilityTags.Add(SplineSlideTags::Speed);
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 80;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter Player;
	USplineSlideComponent SplineSlideComp;

	ASplineSlideSpeedBoost ActiveBoost;

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

		if (SplineSlideComp.ActiveBoost == nullptr)
       		return EHazeNetworkActivation::DontActivate;

		if (MoveComp.IsAirborne())
       		return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SplineSlideComp.ActiveSplineSlideSpline == nullptr)
       		return EHazeNetworkDeactivation::DeactivateLocal;

		if (SplineSlideComp.ActiveBoost == nullptr)
       		return EHazeNetworkDeactivation::DeactivateLocal;

		if (MoveComp.IsAirborne())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetMutuallyExclusive(SplineSlideTags::Speed, true);

		ActiveBoost = Cast<ASplineSlideSpeedBoost>(SplineSlideComp.ActiveBoost);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{		
		SetMutuallyExclusive(SplineSlideTags::Speed, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		SplineSlideComp.CurrentLongitudinalSpeed += ActiveBoost.Settings.Acceleration * DeltaTime;
		SplineSlideComp.CurrentLongitudinalSpeed = FMath::Min(SplineSlideComp.CurrentLongitudinalSpeed, ActiveBoost.Settings.Speed);

		if (IsDebugActive())
			PrintToScreenScaled("Speed: " + SplineSlideComp.CurrentLongitudinalSpeed);
	}
}