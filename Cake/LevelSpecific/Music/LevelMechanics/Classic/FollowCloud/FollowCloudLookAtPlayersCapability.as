import Cake.LevelSpecific.Music.LevelMechanics.Classic.FollowCloud.FollowCloud;

class UFollowCloudLookAtPlayersCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	AFollowCloud FollowCloud;
	AHazePlayerCharacter Target;
	float DistanceToMay;
	float DistanceToCody;
	float FollowDuration = 3.f;

	FHazeAcceleratedRotator AccRotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		FollowCloud = Cast<AFollowCloud>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (FollowCloud.ShouldLookAtPlayer == false)
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (FollowCloud.ShouldLookAtPlayer == false)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AccRotation.SnapTo(FollowCloud.CloudMesh.GetWorldRotation());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		DistanceToCody = (FollowCloud.GetActorLocation() - Game::GetCody().GetActorLocation()).Size();
		DistanceToMay = (FollowCloud.GetActorLocation() - Game::GetMay().GetActorLocation()).Size();

		if(DistanceToCody < 7000 or DistanceToMay < 7000)
		{
			if(DistanceToMay > DistanceToCody)
			{
				Target = Game::GetCody();
			}
			else
			{
				Target = Game::GetMay();
			}

			FVector DirToPlayer = Target.GetActorLocation() - FollowCloud.GetActorLocation();
			FRotator CurRot = AccRotation.AccelerateTo(DirToPlayer.Rotation(), FollowDuration, DeltaTime);
			FollowCloud.CloudMesh.SetWorldRotation(CurRot);
		}
	}	
}
