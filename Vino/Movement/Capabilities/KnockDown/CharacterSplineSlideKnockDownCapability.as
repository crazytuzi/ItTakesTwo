
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Peanuts.Animation.Features.LocomotionFeatureKnockDown;
import Vino.Movement.Helpers.BurstForceStatics;
import Vino.Movement.AnimNotify.Knockdown.AnimNotify_KnockdownStop;
import Vino.Movement.Capabilities.KnockDown.CharacterKnockDownCapability;
import Vino.Movement.SplineSlide.SplineSlideComponent;

// In spline slides we only want to change animation
class UCharacterSplineSlideKnockDownCapability : UHazeCapability
{
	default CapabilityTags.Add(n"KnockDown");
	default CapabilityTags.Add(n"MovementAction");
	default CapabilityTags.Add(n"GameplayAction");
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 120; // We trigger after hit response and will stop regular knockdown from becoming active next tick.

	AHazeCharacter CharOwner;
	USplineSlideComponent SplineSlideComp;

	float KnockdownExitTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CharOwner = Cast<AHazeCharacter>(Owner);
		SplineSlideComp = USplineSlideComponent::GetOrCreate(Owner);	
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (SplineSlideComp.ActiveSplineSlideSpline == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!IsActioning(n"KnockDown"))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

    UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ActivationParams) const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetMutuallyExclusive(n"KnockDown", true);

		// ABP should handle this
		CharOwner.Mesh.SetAnimBoolParam(n"HitReaction", true);		
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		CharOwner.Mesh.SetAnimBoolParam(n"HitReaction", false);		
		ConsumeAction(n"KnockDown"); 
		SetMutuallyExclusive(n"KnockDown", false);
	}
}
