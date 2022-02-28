import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrog;
import Vino.Movement.Components.MovementComponent;

class UJumpingFrogAlignMeshCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::Movement);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	AJumpingFrog OwningFrog;
	UHazeMovementComponent MoveComp;
	FVector UpVector = FVector::UpVector;
	FQuat LastRotation;
	//FVector UpVector = FVector::UpVector;
	// UHazeAsyncTraceComponent AsyncTrace;

	// FVector PitchAmount;
	// FVector RollAmount;
	// bool bIsFirstFrame = false;

	// FHitResult ForwardHit;
	// FHitResult BackwardHit;
	// FHitResult LeftHit;
	// FHitResult RightHit;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		OwningFrog = Cast<AJumpingFrog>(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		LastRotation = OwningFrog.Mesh.GetComponentQuat();
		//AsyncTrace = UHazeAsyncTraceComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(OwningFrog.MountedPlayer == nullptr)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(OwningFrog.MountedPlayer == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		LastRotation = OwningFrog.Mesh.GetComponentQuat();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		OwningFrog.Mesh.SetRelativeRotation(FQuat::Identity);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		FQuat WantedMeshRotation = OwningFrog.GetActorQuat();

		if(MoveComp.IsGrounded())
		{
			UpVector = Math::SlerpVectorTowards(UpVector, MoveComp.DownHit.Normal, DeltaTime * 2.f);
			UpVector = MoveComp.DownHit.Normal;
			AlignWithGround(WantedMeshRotation);
			if(!MoveComp.BecameGrounded())
				WantedMeshRotation = FMath::QInterpTo(LastRotation, WantedMeshRotation, DeltaTime, 25.f);
		}
		else
		{
			UpVector = FVector::UpVector;
			WantedMeshRotation = FMath::QInterpTo(LastRotation, WantedMeshRotation, DeltaTime, 10.f);
		}
	
		OwningFrog.Mesh.SetWorldRotation(WantedMeshRotation);
		LastRotation = WantedMeshRotation;
	}

	void AlignWithGround(FQuat& WantedMeshRotation)
	{
		FVector Forward = Math::MakeRotFromYZ(OwningFrog.GetActorRightVector(), UpVector).ForwardVector;
		FVector Right = Math::MakeRotFromZX(UpVector, Forward).RightVector;
		WantedMeshRotation = Math::MakeQuatFromAxes(Forward, Right, UpVector);
	}
}