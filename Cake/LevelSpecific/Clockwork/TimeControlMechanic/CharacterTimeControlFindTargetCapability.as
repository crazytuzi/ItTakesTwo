import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlComponent;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlParams;
import Vino.ActivationPoint.ActivationPointStatics;

// This capability seeks out the valid components that can be time controlled
class UCharacterTimeControlFindTargetCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(TimeControlCapabilityTags::TimeControlCapability);
	default CapabilityTags.Add(TimeControlCapabilityTags::FindTimeObjectsCapability);
	
	default CapabilityDebugCategory = n"Gameplay";

	default TickGroup = ECapabilityTickGroups::Input;

	AHazePlayerCharacter Player;
	UTimeControlComponent TimeComp;
	UTimeControlActorComponent LastTarget;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		TimeComp = UTimeControlComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// TimeComp.TimeControlBeamComponent.Deactivate();
		if(LastTarget != nullptr)
		{
			LastTarget.DeactivateEffect();
		}	

		LastTarget = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		Player.UpdateActivationPointAndWidgets(UTimeControlActorComponent::StaticClass());

		UTimeControlActorComponent WantedTarget = TimeComp.GetCurrentTargetComponent();
	 	if(WantedTarget != LastTarget)
	 	{
			// Clear last target
			if(LastTarget != nullptr)
			{
				LastTarget.DeactivateEffect();	
			}
			
			// Update new target
			if(WantedTarget != nullptr)
			{
				WantedTarget.ActivatePassiveTarget();
			}
			
	 		LastTarget = WantedTarget;
		}

		// Activate new target and update beam
		if(WantedTarget != nullptr)
		{
			//ContainerComponent.SetTargetPoint(BestPoint, TimeControlCapabilityTags::TimeControlCapability);
			TimeComp.UpdateBeamLocation(WantedTarget);
		}
		else
		{
			// TimeComp.TimeControlBeamComponent.Deactivate();
		}
	}
}