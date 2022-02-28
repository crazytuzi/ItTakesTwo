import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingCameraComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UIceSkatingBoostCapability : UHazeCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityTags.Add(IceSkatingTags::Boost);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 120;

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;
	UIceSkatingCameraComponent SkateCamComp;

	FIceSkatingBoostSettings BoostSettings;
	FIceSkatingCameraSettings CamSettings;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SkateComp = UIceSkatingComponent::GetOrCreate(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
		SkateCamComp = UIceSkatingCameraComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HasControl())
	        return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
	        return EHazeNetworkActivation::DontActivate;

		if (!SkateComp.bIsIceSkating)
	        return EHazeNetworkActivation::DontActivate;

	    if (!MoveComp.IsGrounded())
	       return EHazeNetworkActivation::DontActivate;

	    if (!WasActionStarted(ActionNames::MovementDash))
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{	
		ActivationParams.DisableTransformSynchronization();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (HasControl())
		{
			float Speed = MoveComp.Velocity.Size();
			float BoostMultiplier = 1.f - Math::Saturate(Speed / SkateComp.MaxSpeed);

			float Impulse = BoostSettings.Impulse * BoostMultiplier;
			Impulse = FMath::Max(Impulse, BoostSettings.MinImpulse);

		    FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);
		    if (Input.IsNearlyZero())
		    	Input = Player.ActorForwardVector;

		    Input = SkateComp.TransformVectorToPlane(Input, SkateComp.GroundNormal);
		    Input.Normalize();

			MoveComp.AddImpulse(Input * Impulse);
		}

		MoveComp.SetAnimationToBeRequested(n"SkateBoost");

		SkateComp.CallOnBoostEvent();
	}
}