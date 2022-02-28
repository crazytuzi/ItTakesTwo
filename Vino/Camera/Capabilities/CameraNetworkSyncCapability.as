import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Capabilities.CameraTags;

class UCameraNetworkSyncCapability : UHazeCapability
{
	UCameraUserComponent User;
	UHazeCrumbComponent CrumbComp;

	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(CameraTags::CameraReplication);
	default CapabilityTags.Add(n"PlayerDefault");

    default CapabilityDebugCategory = CameraTags::Camera;
	default TickGroup = ECapabilityTickGroups::LastDemotable;

	bool bShouldDeactivate = false;
	float SyncTime = 0.f;
	const float SyncInterval = 0.1f;

	AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		User = UCameraUserComponent::Get(Owner);
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (User == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!User.ShouldReplicateRotation())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (User == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (bShouldDeactivate)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		bShouldDeactivate = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{	
			if(!User.IsSyncingWithCrumb())
			{
				float Time = Time::GetRealTimeSeconds();
				if (Time >= SyncTime)
				{	
					FHazeCameraReplicationFinalized RepData;
					User.GetDesiredReplicationRotation(RepData);
					if(!RepData.Rotation.Equals(User.GetLastReplicatedRotation(), 1.f))
					{
						SyncTime += SyncInterval;
						NetSyncRotation(RepData);
					}
				}
			}
			else
			{
				CrumbComp.LeaveCameraCrumb();
			}
		}
		else
		{
			if(User.IsSyncingWithCrumb())
			{
				FHazeCameraReplicationFinalized ReplicationParams;
				CrumbComp.ConsumeCrumbTrailCamera(DeltaTime, ReplicationParams);	
				User.SetDesiredReplicatedRotation(ReplicationParams);			
			}
		}
	}

	UFUNCTION(NetFunction, Unreliable)
	void NetSyncRotation(FHazeCameraReplicationFinalized TargetRotation)
	{
		User.SetDesiredReplicatedRotation(TargetRotation);	
	}
};