
import Vino.Movement.Components.MovementComponent;

class UDebugChangeWorldUpCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"WorldUpShifter");
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	// Internal Variables
	UHazeMovementComponent MoveComp;
	UHazeActiveCameraUserComponent CamUserComp;
	AHazeCharacter CharacterOwner;

    FRotator PendingUpRotation = FVector::UpVector.Rotation();
    bool bPendingIsValid = false;

    FRotator TargetUpRotation = FVector::UpVector.Rotation();
    FHazeAcceleratedRotator UpRotation;
    default UpRotation.Value = TargetUpRotation;
    default UpRotation.Velocity = FRotator::ZeroRotator;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CharacterOwner = Cast<AHazeCharacter>(Owner);
        ensure(CharacterOwner != nullptr);

		MoveComp = UHazeMovementComponent::GetOrCreate(CharacterOwner);
		CamUserComp = UHazeActiveCameraUserComponent::Get(CharacterOwner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		FVector Dif = TargetUpRotation.Vector() - MoveComp.WorldUp;
		if (!Dif.IsNearlyZero())
			return EHazeNetworkActivation::ActivateLocal;
		
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		FVector Dif = TargetUpRotation.Vector() - MoveComp.WorldUp;
		if (!Dif.IsNearlyZero())
			return EHazeNetworkDeactivation::DontDeactivate;
		
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{        
        FVector ZExtentz = MoveComp.ActorShapeExtents;
        ZExtentz.X = 0.f;
        ZExtentz.Y = 0.f;

        FHazeHitResult NewGround;
        FVector CheckFrom = CharacterOwner.GetActorLocation() + ZExtentz;
        FVector CheckTo = CheckFrom + Owner.ControlRotation.Vector() * 2000.f;

        bPendingIsValid = false;
        if (MoveComp.LineTrace(CheckFrom, CheckTo, NewGround))
        {
            TargetUpRotation = NewGround.Normal.Rotation();
            bPendingIsValid = true;
        }     
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FRotator CurUpRot = UpRotation.AccelerateTo(TargetUpRotation, 1.f, DeltaTime);
        CharacterOwner.ChangeActorWorldUp(CurUpRot.Vector());
        CamUserComp.SetYawAxis(CurUpRot.Vector());

        FVector Start = CharacterOwner.GetActorLocation() + CurUpRot.Vector() * 200;
        System::DrawDebugLine(Start, Start + CurUpRot.Vector() * 100, FLinearColor::Blue, 0, 3);
        System::DrawDebugLine(Start, Start + CamUserComp.BaseRotation.Vector() * 100, FLinearColor::Red, 0, 3);
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		return "HELLo";
	}
};
