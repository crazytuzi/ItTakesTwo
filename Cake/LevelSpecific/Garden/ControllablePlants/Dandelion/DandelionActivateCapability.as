import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Dandelion.DandelionTags;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Dandelion.DandelionComponent;
import Vino.Checkpoints.Statics.DeathStatics;
import Vino.Movement.MovementSystemTags;
import Vino.Camera.Capabilities.CameraTags;

class UDandelionActivateCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 10;

	AHazePlayerCharacter Player;
	UDandelionComponent DandelionComp;
	UHazeMovementComponent MoveComp;
	UControllablePlantsComponent PlantsComp;
	ADandelion Dandelion;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Dandelion = Cast<ADandelion>(Owner);
		Player = Dandelion.OwnerPlayer;
		DandelionComp = UDandelionComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Owner);
		PlantsComp = UControllablePlantsComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		// Place the dandelion slightly above the player so it will not touch the ground yet.
		const FVector StartLocation = Player.ActorLocation + (FVector::UpVector * 10.0f);
		ActivationParams.AddVector(n"StartLocation", StartLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(CameraTags::ChaseAssistance, Owner);
		const FVector StartLocation = ActivationParams.GetVector(n"StartLocation");
		//Owner.TeleportActor(StartLocation, FRotator::ZeroRotator);
		//Dandelion.DandelionMesh.SetVisibility(true);
		Dandelion.TriggerCameraTransitionToPlant();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Dandelion.bWantsToExitDandelion)
		{
			return EHazeNetworkActivation::DontActivate;
		}

		if(!Dandelion.bDandelionActive)
		{
			return EHazeNetworkActivation::DontActivate;
		}
        
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (IsPlayerDead(Player))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!Dandelion.IsPlantActive)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& OutParams)
	{
		// if IsPlantActive has triggered this deactivation we don't want to call deactivate twice
		if(MoveComp.IsGrounded())
			OutParams.AddActionState(n"DeactivatePlant");
		else if(IsPlayerDead(Player))
			OutParams.AddActionState(n"DeactivatePlant");

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{		
		Owner.UnblockCapabilities(CameraTags::ChaseAssistance, Owner);

		DandelionComp.bDandelionActive = false;
		Dandelion.bWantsToExitDandelion = false;
		Dandelion.bDandelionActive = false;

		if(DeactivationParams.GetActionState(n"DeactivatePlant"))
			Dandelion.UnPossessPlant();

		//Player.SetActorRotation(Dandelion.HorizontalVelocity.GetSafeNormal().Rotation());
	}
}
