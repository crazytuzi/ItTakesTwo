import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UIceSkatingSlopeCapability : UHazeCapability
{
	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;

	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityTags.Add(IceSkatingTags::Slope);
	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 50;

	FIceSkatingSlopeSettings SlopeSettings;
	FIceSkatingFastSettings FastSettings;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SkateComp = UIceSkatingComponent::GetOrCreate(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!SkateComp.bIsIceSkating)
	        return EHazeNetworkActivation::DontActivate;

	    if (!MoveComp.IsGrounded())
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SkateComp.bIsIceSkating)
			return EHazeNetworkDeactivation::DeactivateLocal;

	    if (!MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Get the slope-down vector
		FHitResult GroundHit = SkateComp.GetGroundHit();
		FVector GroundNormal = GroundHit.Normal;

		if (MoveComp.IsGrounded())
			SkateComp.LastGroundedNormal = GroundNormal;

		FVector SlopeRight = GroundNormal.CrossProduct(FVector::UpVector);
		FVector SlopeDown = GroundNormal.CrossProduct(SlopeRight);
		SlopeDown.Normalize();

		// Slope sin-angle
		float Slope = SlopeDown.DotProduct(-FVector::UpVector);

		// Add forces !
		FVector Velocity = MoveComp.Velocity;
		float Speed = Velocity.Size();

		if (SkateComp.bIsFast)
		{
			// If we're fast; only accelerate in the velocity direction, and the turn separately to that
			FVector VelocityDir = Velocity.GetSafeNormal();

			// If we're REALLY fast, scale down gravity even more
			float SpeedMultiplier = 1.f - Math::GetPercentageBetweenClamped(FastSettings.MaxSpeed_Flat, SlopeSettings.SlopeMaxSpeed, Speed);

			// If we're going uphill, scale down gravity even MORE
			float UphillMultiplier = Velocity.DotProduct(FVector::UpVector) > 200.f ? SlopeSettings.UphillMultiplier : 1.f;

			// Scale gravity based on how much we're aligned downhill'
			// (if we're going perpendicular to the slope, then we shouldnt accelerate)
			float GravityMultiplier = SlopeDown.DotProduct(VelocityDir) * Slope;

			Velocity += VelocityDir * GravityMultiplier * SpeedMultiplier * UphillMultiplier * SlopeSettings.Gravity * DeltaTime;

			// Turn it
			// Take settings into account, if the slope is shallow enough, we dont want to turn at all
			float AngleDeg = FMath::Asin(Slope) * RAD_TO_DEG;
			float TurnSpeed = Math::GetPercentageBetweenClamped(SlopeSettings.MinTurnAngle, SlopeSettings.MaxTurnAngle, AngleDeg);
			float TurnMultiplier = 1.f - FMath::Abs(VelocityDir.DotProduct(SlopeDown));

			if (TurnSpeed >= 0.f)
			{
				TurnSpeed = SlopeSettings.TurnSpeed * TurnSpeed * TurnMultiplier;
				Velocity = SkateComp.SlerpVectorTowardsAroundAxis(Velocity, SlopeDown, GroundNormal, TurnSpeed * Slope * DeltaTime);
			}
		}
		else
		{
			// When going slow, its super annoying if you keep getting accelerated when trying to stand still
			// SO, only add down-slope acceleration if we're either;
			//	Have up-slope velocity
			//	or have input down-slope
			FVector Input = SkateComp.GetScaledPlayerInput();
			Input = SkateComp.TransformVectorToPlane(Input, GroundNormal);

			if (Velocity.DotProduct(SlopeDown) < 0.f || Input.DotProduct(SlopeDown) > 0.f)
				Velocity += SlopeDown * Slope * SlopeSettings.Gravity * DeltaTime;
		}

		MoveComp.Velocity = Velocity;
	}
}