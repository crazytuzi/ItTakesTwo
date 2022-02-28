import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.Ballista.CourtyardGlueStickPool;
import Peanuts.ButtonMash.Progress.ButtonMashProgress;

class UCourtyardGlueStuckCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Example");

	default CapabilityDebugCategory = n"Example";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	ACourtyardGlueStickPool ActivePool;

	UButtonMashProgressHandle ButtonMashHandle;
	float ButtonMashDecay = 0.25f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{	
		if (!IsActive())
		{
			UObject Pool;
			ConsumeAttribute(n"GluePool", Pool);
			ActivePool = Cast<ACourtyardGlueStickPool>(Pool);
		}
    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (ActivePool == nullptr)
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (ButtonMashHandle.Progress < 1.f)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ButtonMashHandle = StartButtonMashProgressAttachToComponent(Player, Player.Mesh, NAME_None, FVector::ZeroVector);

		Player.BlockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		StopButtonMash(ButtonMashHandle);

		ActivePool.DestroyActor();
		ActivePool = nullptr;

		Player.UnblockCapabilities(CapabilityTags::Movement, this);		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		ButtonMashHandle.Progress -= ButtonMashDecay * DeltaTime;
		ButtonMashHandle.Progress += ButtonMashHandle.MashRateControlSide * 0.1f * DeltaTime;
	}
}