import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.ControllableUFO;

class UUfoAlignToSurfaceCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Gravity");
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

    UHazeMovementComponent MoveComp;

	FRotator TargetUpRotation = FVector::UpVector.Rotation();
    FHazeAcceleratedRotator UpRotation;
    default UpRotation.Value = TargetUpRotation;
    default UpRotation.Velocity = FRotator::ZeroRotator;

	bool bOnGravityPath = false;

	AControllableUFO ControllableUFO;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        MoveComp = UHazeMovementComponent::GetOrCreate(Owner);

		ControllableUFO = Cast<AControllableUFO>(GetAttributeObject(n"ControllableUFO"));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (ControllableUFO.bActive)
        	return EHazeNetworkActivation::ActivateFromControl;
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FHitResult Ground;
		if (MoveComp.LineTraceGround(Owner.GetActorLocation(), Ground, 10000.f))
		{
			TargetUpRotation = Ground.Normal.Rotation();
			UpRotation.SnapTo(TargetUpRotation, FRotator::ZeroRotator);
			Owner.ChangeActorWorldUp(UpRotation.Value.Vector());
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{        

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHitResult Ground;
        if (MoveComp.LineTraceGround(Owner.GetActorLocation(), Ground, 10000.f) && Ground.Component.HasTag(ComponentTags::GravBootsWalkable))
        {
			bOnGravityPath = true;
            TargetUpRotation = Ground.Normal.Rotation();
        }
		else
		{
			bOnGravityPath = false;
		}
		
		FRotator CurUpRot = UpRotation.AccelerateTo(TargetUpRotation, 1.f, DeltaTime);
        Owner.ChangeActorWorldUp(CurUpRot.Vector());
	}
}