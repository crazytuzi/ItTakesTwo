import Cake.LevelSpecific.PlayRoom.Circus.SlingShot.SlingShot;
import Cake.LevelSpecific.PlayRoom.Circus.SlingShot.SlingShotWidget;
class USlingshotWidgetCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ASlingShotActor Slingshot;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Slingshot = Cast<ASlingShotActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Slingshot.IsBothPlayersPulling && Slingshot.bIsArmed && Slingshot.HandleCloseToMaxPosition) 
		{
			return EHazeNetworkActivation::ActivateLocal;
		}
        else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	void HideWidget()
	{
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Slingshot.IsBothPlayersPulling || !Slingshot.HandleCloseToMaxPosition)
		{
			return EHazeNetworkDeactivation::DeactivateLocal;
		}
		else
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
	}
}