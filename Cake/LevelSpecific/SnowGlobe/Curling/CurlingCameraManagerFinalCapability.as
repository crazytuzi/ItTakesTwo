import Cake.LevelSpecific.SnowGlobe.Curling.CurlingCameraManager;

class UCurlingCameraManagerFinalCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CurlingCameraManagerFinalCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 100;

	ACurlingCameraManager CameraManager;

	FVector FinalLookLoc;
	FRotator FinalRot;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CameraManager = Cast<ACurlingCameraManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (CameraManager.CamManagerState == ECurlingCamManagerState::FinalShot)
	        return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (CameraManager.CamManagerState != ECurlingCamManagerState::FinalShot)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FVector BackAmount = CameraManager.FollowCam.ActorForwardVector * -300.f;
	 	FinalLookLoc = CameraManager.FollowCam.ActorLocation + BackAmount + FVector(0.f, 0.f, 800.f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		UpdateFollowCameraPosition(CameraManager.InPlayCurlingStone, DeltaTime, CameraManager.SpeedPercentage);
	}

	void UpdateFollowCameraPosition(ACurlingStone InPlayCurlingStone, float DeltaTime, float SpeedPercent)
	{
		FRotator LookAtRot = FRotator::MakeFromX((InPlayCurlingStone.ActorLocation - CameraManager.FollowCam.ActorLocation).GetSafeNormal());
		CameraManager.AcceleratedCamRotation.AccelerateTo(LookAtRot, 4.f, DeltaTime);
		CameraManager.FollowCam.SetActorRotation(CameraManager.AcceleratedCamRotation.Value);

		CameraManager.AcceleratedCamLocation.AccelerateTo(FinalLookLoc, 5.5f, DeltaTime);
		CameraManager.FollowCam.SetActorLocation(CameraManager.AcceleratedCamLocation.Value);
	}
}