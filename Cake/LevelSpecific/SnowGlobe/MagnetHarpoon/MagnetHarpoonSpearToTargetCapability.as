import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetHarpoonActor;
class UMagnetHarpoonSpearToTargetCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MagnetHarpoonSpearToTargetCapability");
	default CapabilityTags.Add(n"MagnetHarpoon");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AMagnetHarpoonActor MagnetHarpoon;

	FVector EndLoc;

	FHazeAcceleratedFloat AccelFloat;

	bool bPendingFire;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MagnetHarpoon = Cast<AMagnetHarpoonActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (MagnetHarpoon.HarpoonSpearState == EHarpoonSpearState::ToTarget /* && MagnetHarpoon.CanPendingFire()*/)
			return EHazeNetworkActivation::ActivateFromControl;
			
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (MagnetHarpoon.HarpoonSpearState != EHarpoonSpearState::ToTarget)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MagnetHarpoon.AudioStartHarpoonMovement();
		MagnetHarpoon.SetClawState(EHarpoonClawAnimState::Open);
		MagnetHarpoon.ResetWaterSplash();
		MagnetHarpoon.BlockCapabilities(n"MagnetHarpoonRotationCapability", this);
		MagnetHarpoon.SpearTargetLocation = MagnetHarpoon.TraceEndPoint;
		MagnetHarpoon.AccelSpearSpeed.SnapTo(MagnetHarpoon.SpearSpeed);
		MagnetHarpoon.SetAnimBoolParam(n"HarpoonFired", true);
		MagnetHarpoon.bWaitingForPending = false;

		UHarpoonPlayerComponent PlayerComp = UHarpoonPlayerComponent::Get(MagnetHarpoon.UsingPlayer);
		
		//NULL CHECK FOR MagnetHarpoon.UsingPlayer

		if (PlayerComp != nullptr)
			PlayerComp.PlayFeedback(MagnetHarpoon.UsingPlayer, 0.8f);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		MagnetHarpoon.UnblockCapabilities(n"MagnetHarpoonRotationCapability", this);
		MagnetHarpoon.AudioStartGunMovement();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		float Distance = (MagnetHarpoon.HarpoonSpearSkel.WorldLocation - MagnetHarpoon.SpearTargetLocation).Size();
		FMath::Abs(Distance);

		if (Distance <= 1000.f)
			MagnetHarpoon.AccelSpearSpeed.AccelerateTo((MagnetHarpoon.SpearSpeed * 0.2f), 1.6f, DeltaTime);

		if (Distance <= 10.f)
			MagnetHarpoon.HarpoonSpearState = EHarpoonSpearState::ToOrigin;
	}
}