import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.BackstagePowerSwitch;

class UBackstagePowerSwitchCapability : UHazeCapability
{
	default CapabilityTags.Add(n"BackstagePowerSwitchCapability");
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"BackstagePowerSwitchCapability";
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UInteractionComponent InteractionComp;
	ABackstagePowerSwitch BackstagePowerSwitch;
	bool bCanceled = false;
	

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (InteractionComp != nullptr)
			return EHazeNetworkActivation::ActivateLocal;

		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(InteractionComp == nullptr || bCanceled)
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
		Player.BlockCapabilities(n"Movement", this);
		Player.BlockCapabilities(n"LevelSpecific", this);
		Player.TriggerMovementTransition(this);
		Player.BlockMovementSyncronization(this);
		Player.AttachToComponent(InteractionComp);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		Player.UnblockCapabilities(n"Movement", this);
		Player.UnblockCapabilities(n"LevelSpecific", this);
		BackstagePowerSwitch.PlayerStoppedUsingSwitch(Player);
		
		Player.UnblockMovementSyncronization(this);
		bCanceled = false;

		if (InteractionComp != nullptr)
		{
			BackstagePowerSwitch.SetInteractionPointEnabled(InteractionComp);
			InteractionComp = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		UObject Comp;
		if (ConsumeAttribute(n"InteractionComponent", Comp))
		{
			InteractionComp = Cast<UInteractionComponent>(Comp);
		}

		UObject Switch;
		if (ConsumeAttribute(n"BackstagePowerSwitch", Switch))
		{
			BackstagePowerSwitch = Cast<ABackstagePowerSwitch>(Switch);
		}
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{			
		if (WasActionStarted(ActionNames::Cancel) && BackstagePowerSwitch.DoubleInteract.CanPlayerCancel(Player) && BackstagePowerSwitch.bPlayersEverAllowedToCancel)
		{
			NetSetCanceled();
		}
	}

	UFUNCTION(NetFunction)
	void NetSetCanceled()
	{
		bCanceled = true;
	}
}