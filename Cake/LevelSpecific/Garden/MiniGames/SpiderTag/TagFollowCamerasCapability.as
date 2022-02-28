import Cake.LevelSpecific.Garden.MiniGames.SpiderTag.SpiderTagGameManager;

class UTagFollowCamerasCapability : UHazeCapability
{
	default CapabilityTags.Add(n"TagFollowCamerasCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ASpiderTagGameManager GameManager;

	FVector StartingLoc;

	FVector CamLocation;

	bool bHaveSetCamLoc;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		GameManager = Cast<ASpiderTagGameManager>(Owner);
		StartingLoc = GameManager.FollowCam.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (GameManager.TagFollowCamState != ETagFollowCamState::Inactive)
        	return EHazeNetworkActivation::ActivateFromControl;
        
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (GameManager.TagFollowCamState != ETagFollowCamState::Inactive)
			return EHazeNetworkDeactivation::DontDeactivate;
		
		return EHazeNetworkDeactivation::DeactivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bHaveSetCamLoc = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		System::SetTimer(this, n"ResetCams", 1.5f, false);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		switch(GameManager.TagFollowCamState)
		{
			case ETagFollowCamState::Inactive: ResetCams(); break;
			case ETagFollowCamState::FollowMay: FollowCam(Game::May, GameManager.FollowCam, DeltaTime); break;
			case ETagFollowCamState::FollowCody: FollowCam(Game::Cody, GameManager.FollowCam, DeltaTime); break;
		}
	}

	UFUNCTION()
	void FollowCam(AHazePlayerCharacter Player, AHazeCameraActor Camera, float DeltaTime)
	{
		CamLocation = Player.ActorLocation;
		CamLocation += GameManager.ActorForwardVector * 600.f;
		CamLocation += FVector(0.f, 0.f, 450.f);

		FVector NewLoc = FMath::VInterpTo(Camera.ActorLocation, CamLocation, DeltaTime, 1.8f);

		FVector LookDirection = Player.ActorLocation - Camera.ActorLocation;
		LookDirection.Normalize();
		FRotator CamRotation = FRotator::MakeFromX(LookDirection);

		FRotator NewRot = FMath::RInterpTo(Camera.ActorRotation, CamRotation, DeltaTime, 0.7f);

		//	Snapping issue in networking when blending to another cam
		// Camera.SetActorLocationAndRotation(NewLoc, NewRot);	
		
		GameManager.FollowCam.SetActorLocationAndRotation(NewLoc, NewRot);
	}

	UFUNCTION()
	void ResetCams()
	{
		GameManager.FollowCam.SetActorLocation(StartingLoc);
	}
}