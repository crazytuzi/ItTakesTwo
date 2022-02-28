import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UIceSkatingMaxSpeedCapability : UHazeCapability
{
	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;

	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 55;

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

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SkateComp.bIsIceSkating)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SkateComp.MaxSpeed = FastSettings.MaxSpeed_Flat;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SkateComp.MaxSpeed = FastSettings.MaxSpeed_Flat;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Only update slope maxspeed if were actually on the ground
		if (MoveComp.IsGrounded())
		{
			FVector VelocityDir = MoveComp.Velocity.GetSafeNormal();
			float Slope = VelocityDir.DotProduct(-FVector::UpVector);

			if (Slope > 0.f)
			{
				SkateComp.MaxSpeed += Slope * FastSettings.MaxSpeedGainSpeed * DeltaTime;
				SkateComp.MaxSpeed = FMath::Clamp(
					SkateComp.MaxSpeed,
					FastSettings.MaxSpeed_Flat,
					FastSettings.MaxSpeed_Slope
				);
			}
		}

		float Speed = MoveComp.Velocity.Size();
		if (Speed < SkateComp.MaxSpeed)
		{
			SkateComp.MaxSpeed = FMath::Clamp(Speed, FastSettings.MaxSpeed_Flat, FastSettings.MaxSpeed_Slope);
		}
	}
}