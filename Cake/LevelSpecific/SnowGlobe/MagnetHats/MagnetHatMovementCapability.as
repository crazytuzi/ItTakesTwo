import Cake.LevelSpecific.SnowGlobe.MagnetHats.MagnetHat;

class UMagnetHatMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MagnetHatMovementCapability");
	default CapabilityTags.Add(n"MagnetHat");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AMagnetHat Hat;

	FHazeAcceleratedFloat AccelSpeed;

	FVector TargetLoc;

	float MaxSpeed = 2500.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Hat = Cast<AMagnetHat>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Hat.MagnetHatMovementState == EMagnetHatMovementState::MovingToPlayer)
        	return EHazeNetworkActivation::ActivateFromControl;
        
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Hat.MagnetHatMovementState != EMagnetHatMovementState::MovingToPlayer)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if ((Hat.ActorLocation - TargetLoc).Size() <= 100.f)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AccelSpeed.SnapTo(0.f);
		Hat.MagnetHatMovementState = EMagnetHatMovementState::Attached;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (Hat.TargetPlayer == nullptr)
			return;

		float Distance;

		TargetLoc = Hat.TargetPlayer.ActorLocation + FVector(0.f, 0.f, 170.f);
		
		AccelSpeed.AccelerateTo(MaxSpeed, 0.6f, DeltaTime);
		Hat.AccelScale.AccelerateTo(Hat.MayScale, 0.4f, DeltaTime);
		Hat.SetActorScale3D(Hat.AccelScale.Value);

		FVector Direction = (TargetLoc - Hat.ActorLocation).GetSafeNormal();
		Hat.ActorLocation = Hat.ActorLocation + Direction * AccelSpeed.Value * DeltaTime;
		Distance = (Hat.ActorLocation - TargetLoc).Size();
	}
}