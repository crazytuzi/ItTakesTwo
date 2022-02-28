import Cake.LevelSpecific.PlayRoom.GoldBerg.MarbleBall.MarbleBall;
import Cake.LevelSpecific.PlayRoom.GoldBerg.MarbleTags;

class UMarbleNetworkSyncCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::AfterPhysics;
	default TickGroupOrder = 100;
	UHazeCrumbComponent CrumbComponent;
	AMarbleBall Marble;

	default CapabilityTags.Add(FMarbleTags::MarbleNetworkSync);

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Marble = Cast<AMarbleBall>(Owner);
		CrumbComponent = UHazeCrumbComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		
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
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		Marble.TriggerMovementTransition(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			CrumbComponent.LeaveMovementCrumb();
		}

		else
		{
			if (Marble.Mesh.BodyInstance.bSimulatePhysics)
			{
				Marble.Mesh.SetSimulatePhysics(false);
			}

			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime,ConsumedParams);
			
			Marble.SetActorLocation(ConsumedParams.Location);
			//Marble.AddActorWorldOffset(ConsumedParams.DeltaTranslation);
			
			
			Marble.SetActorRotation(ConsumedParams.Rotation);
			Marble.SetMarblePhysicsVelocity(ConsumedParams.Velocity);
		}
	}
}