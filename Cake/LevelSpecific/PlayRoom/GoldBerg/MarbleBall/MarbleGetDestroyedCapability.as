import Cake.LevelSpecific.PlayRoom.GoldBerg.MarbleBall.MarbleBall;
import Cake.LevelSpecific.PlayRoom.Circus.Marble.MarbleCheckpointTube;

class UMarbleGetDestroyedCapability : UHazeCapability
{
	AMarbleBall Marble;
	AMarbleCheckpointTube Checkpoint;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Marble = Cast<AMarbleBall>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"Checkpoint", Marble.Checkpoint);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{		
		Checkpoint = Cast<AMarbleCheckpointTube>(ActivationParams.GetObject(n"Checkpoint"));

		if(!HasControl())
		{
			PerformDestroy();
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Marble.bShouldBeDestroyed)
		{
			return EHazeNetworkActivation::ActivateUsingCrumb;
		}

		else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	void PerformDestroy()
	{
		if(Checkpoint != nullptr)
		{
			Checkpoint.ActivateMarbleBall();
		}
		
		Marble.DestroyMarbleFX();
		Marble.DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PerformDestroy();
	}
}