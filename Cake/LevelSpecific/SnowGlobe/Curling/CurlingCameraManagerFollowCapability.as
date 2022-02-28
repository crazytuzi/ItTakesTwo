import Cake.LevelSpecific.SnowGlobe.Curling.CurlingCameraManager;

class UCurlingCameraManagerFollowCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CurlingCameraManagerFollowCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 100;

	ACurlingCameraManager CameraManager;
	
	float NetworkTime;
	float NetworkRate = 0.4f;

	FVector NetCamLocation;
	FRotator NetCamRotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CameraManager = Cast<ACurlingCameraManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (CameraManager.CamManagerState == ECurlingCamManagerState::Following)
	        return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (CameraManager.CamManagerState != ECurlingCamManagerState::Following)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CameraManager.ResetFollowCamera();
		CameraManager.SetBlockNonControlledCam(true);
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		UpdateFollowCameraPosition(CameraManager.InPlayCurlingStone, DeltaTime, CameraManager.SpeedPercentage);
	}

	void UpdateFollowCameraPosition(ACurlingStone InPlayCurlingStone, float DeltaTime, float SpeedPercent)
	{
		if (CameraManager.FollowCam == nullptr)
			return;

		if (InPlayCurlingStone == nullptr)
			return;

		FVector DeltaFromStartLine = CameraManager.InPlayCurlingStone.ActorLocation - CameraManager.StartingLine.ActorLocation;
		float DistanceFromStartLine1 = CameraManager.StartingLine.ActorForwardVector.DotProduct(DeltaFromStartLine);

		FVector NewCamLocation;

		if (DistanceFromStartLine1 < 0.f)
		{
			FVector Location = FVector(InPlayCurlingStone.ActorLocation.X, InPlayCurlingStone.ActorLocation.Y, CameraManager.ZValue);	
			FVector CamZOffset(0,0,550.f);	
			FVector StoneMoveDir = InPlayCurlingStone.MoveComp.Velocity;
			StoneMoveDir.Normalize();
			NewCamLocation = Location + (StoneMoveDir * -1000.f) + CamZOffset;
		}
		else
		{
			FVector Location = FVector(InPlayCurlingStone.ActorLocation.X, InPlayCurlingStone.ActorLocation.Y, CameraManager.ZValue);	
			FVector CamZOffset(0,0,1050.f);	
			NewCamLocation = Location + (CameraManager.ArenaForwardDirection * -700.f) + CamZOffset;
		}

		FRotator LookAtRot = FRotator::MakeFromX((InPlayCurlingStone.ActorLocation - CameraManager.FollowCam.ActorLocation).GetSafeNormal());

		CameraManager.AcceleratedCamRotation.AccelerateTo(LookAtRot, 2.3f, DeltaTime);
		CameraManager.AcceleratedCamLocation.AccelerateTo(NewCamLocation, 2.2f, DeltaTime);
		
		CameraManager.FollowCam.SetActorLocation(CameraManager.AcceleratedCamLocation.Value);
		CameraManager.FollowCam.SetActorRotation(CameraManager.AcceleratedCamRotation.Value);
	}
}