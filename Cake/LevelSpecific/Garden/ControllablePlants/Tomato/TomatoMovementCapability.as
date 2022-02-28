import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.Tomato;
import Cake.LevelSpecific.Garden.ControllablePlants.PlantMovementCapability;

class UTomatoMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::Movement);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 10;

	ATomato Tomato;

	FVector CurrentVelocity;

	float RotationSpeed = 0.5f;

	FVector2D CollisionSize;

	UPROPERTY(NotEditable)
	UHazeMovementComponent MoveComp;

	UPROPERTY(NotEditable)
	UHazeCrumbComponent CrumbComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Tomato = Cast<ATomato>(Owner);

		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		CrumbComp = UHazeCrumbComponent::GetOrCreate(Owner);

		auto Capsule = UCapsuleComponent::Get(Owner);
		CollisionSize.X = Capsule.GetCapsuleRadius();
		CollisionSize.Y = Capsule.GetCapsuleHalfHeight();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (MoveComp.CanCalculateMovement() && Tomato.bFinishedSpawning)
		{
			return EHazeNetworkActivation::ActivateUsingCrumb;
		}
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
		{
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}
		
		return EHazeNetworkDeactivation::DontDeactivate;
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
		if(!MoveComp.CanCalculateMovement())
		{
			return;
		}

		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(TomatoTags::Tomato); 
		MoveData.OverrideStepUpHeight(CollisionSize.Y);

		if(HasControl())
		{	
			MoveData.ApplyVelocity(Tomato.Velocity);
			MoveData.ApplyActorVerticalVelocity();
			MoveData.ApplyGravityAcceleration();

			//FHazeActorReplication ReplicationData = Tomato.MakeReplicationData();
			
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			MoveData.ApplyConsumedCrumbData(ConsumedParams);
		}

		if(!MoveData.Velocity.IsNearlyZero())
		{
			MoveComp.Move(MoveData);
			CrumbComp.LeaveMovementCrumb();
			Tomato.CalculateRotationFromVelocity(MoveData.Velocity, DeltaTime);
		}
	}
}
