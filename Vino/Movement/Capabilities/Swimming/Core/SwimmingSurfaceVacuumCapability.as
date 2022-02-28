import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingVolume;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;
import Vino.Movement.Capabilities.Swimming.SwimmingSurfaceComponent;

class USwimmingSurfaceVacuumCapability : UHazeCapability
{	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Swimming);
	default CapabilityTags.Add(SwimmingTags::Surface);
	default CapabilityTags.Add(n"SurfaceVacuum");
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	default CapabilityDebugCategory = n"Movement Swimming";

	AHazePlayerCharacter Player;
	USnowGlobeSwimmingComponent SwimComp;
	USwimmingSurfaceComponent SurfaceComp;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SwimComp = USnowGlobeSwimmingComponent::GetOrCreate(Player);
		SurfaceComp = USwimmingSurfaceComponent::Get(Player);
		MoveComp = UHazeMovementComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if (!SwimComp.bIsInWater)
			return EHazeNetworkActivation::DontActivate;

		// if (SwimComp.SwimmingState != ESwimmingState::Swimming)
		// 	return EHazeNetworkActivation::DontActivate;

		if (MoveComp.Velocity.Size() > SwimmingSettings::Surface.VacuumTotalSpeedThreshold)
        	return EHazeNetworkActivation::DontActivate;

		if (MoveComp.Velocity.DotProduct(-MoveComp.WorldUp) > SwimmingSettings::Surface.VacuumTotalSpeedThreshold)
        	return EHazeNetworkActivation::DontActivate;

		if (SurfaceComp.SurfaceData.DistanceToSurface >= SwimmingSettings::Surface.VacuumRange)
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SwimComp.bIsInWater)
			return EHazeNetworkDeactivation::DeactivateLocal;

		// if (SwimComp.SwimmingState != ESwimmingState::Slow)
        // 	return EHazeNetworkDeactivation::DeactivateLocal;

		if (MoveComp.Velocity.Size() >= SwimmingSettings::Surface.VacuumTotalSpeedThreshold)
        	return EHazeNetworkDeactivation::DeactivateLocal;

		if (MoveComp.Velocity.DotProduct(-MoveComp.WorldUp) > SwimmingSettings::Surface.VacuumTotalSpeedThreshold)
        	return EHazeNetworkDeactivation::DeactivateLocal;

		if (SurfaceComp.SurfaceData.DistanceToSurface >= SwimmingSettings::Surface.VacuumRange)
        	return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		float VacuumStrength = 1 - (SurfaceComp.SurfaceData.DistanceToSurface / SwimmingSettings::Surface.VacuumRange);
		FVector Acceleration = SurfaceComp.SurfaceData.ToSurface.GetSafeNormal() * SwimmingSettings::Surface.VacuumAcceleration * VacuumStrength * DeltaTime;

		MoveComp.Velocity += Acceleration;
	}
}