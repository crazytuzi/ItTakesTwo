import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimal;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.PlayerHealth.PlayerHealthStatics;

class UWallWalkingAnimalMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 100;

	AWallWalkingAnimal TargetAnimal;
	UWallWalkingAnimalMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;
	FQuat LastFrameRotation;

	float CurrentSpeed = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		TargetAnimal = Cast<AWallWalkingAnimal>(Owner);
		MoveComp = UWallWalkingAnimalMovementComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(TargetAnimal.bIsControlledByCutscene)
			return EHazeNetworkActivation::DontActivate;	
        
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(TargetAnimal.bIsControlledByCutscene)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TargetAnimal.MoveComp.bCanUpdateMovement = true;
		LastFrameRotation = TargetAnimal.GetActorQuat();

		CurrentSpeed = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		TargetAnimal.MoveComp.bCanUpdateMovement = false;
		TargetAnimal.SetCapabilityAttributeValue(n"AudioSpiderVelocity", 0.f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if(!TargetAnimal.IsCarryingPlayer())
		{
			UpdateEmptySpider(DeltaTime);
			TargetAnimal.TuringDirection = 0;
		}
		else
		{
			if(HasControl())
			{
				UpdateControlSpider(DeltaTime);	
			}
			else
			{
				FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"WallWalkingAnimal");
				FHazeActorReplicationFinalized ReplicatedMovement;
				CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ReplicatedMovement);
				MoveData.ApplyConsumedCrumbData(ReplicatedMovement);
				
				LastFrameRotation = FMath::QInterpTo(LastFrameRotation, MoveData.Rotation, Owner.GetActorDeltaSeconds(), 10.f);
				MoveData.SetRotation(LastFrameRotation);
				MoveCharacter(MoveData, n"Movement");
			}
		}

		TargetAnimal.SetCapabilityAttributeValue(n"AudioSpiderVelocity", TargetAnimal.MoveComp.GetVelocity().Size());
		auto ContactMaterial = MoveComp.GetContactSurfaceMaterial();
		if(ContactMaterial != nullptr)
			TargetAnimal.SetCapabilityAttributeObject(n"AudioSpiderContactSurface", ContactMaterial.AudioAsset);		
	}

	FRotator GetWantedRotation()const
	{
		if(TargetAnimal.GetPlayer() == nullptr)
			return TargetAnimal.GetActorRotation();

		if(TargetAnimal.ActiveTransitionType != EWallWalkingAnimalTransitionType::None)
			return TargetAnimal.GetActorRotation();

		if(TargetAnimal.LockedForwardTimeStamp > Time::GetGameTimeSeconds())
			return TargetAnimal.GetActorRotation();

		if(TargetAnimal.bFaceCameraDirection)
			return TargetAnimal.GetPlayer().GetControlRotation();

		FVector FacingDirection = TargetAnimal.SpiderWantedMovementDirection.GetSafeNormal();
		if(FacingDirection.IsNearlyZero())
			return MoveComp.GetTargetFacingRotation().Rotator();
		else
			return FacingDirection.ToOrientationRotator();
	}

	void UpdateControlSpider(float DeltaTime)
	{
		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"WallWalkingAnimal");
		MoveData.OverrideStepDownHeight(TargetAnimal.GetCollisionSize().Y * 2);

		if(MoveComp.IsGrounded())
		{		
			MoveData.FlagToMoveWithDownImpact();

			//const float RotationSpeed = TargetAnimal.bFaceCameraDirection ? 24.f : 12.f;

			FRotator NewWantedRotation = GetWantedRotation();
			MoveComp.SetTargetFacingRotation(NewWantedRotation, 0);
			MoveData.ApplyTargetRotationDelta();
			
			FVector ForwardVelocityDirection;
			if(TargetAnimal.bTransitioning)
				ForwardVelocityDirection = NewWantedRotation.ForwardVector.ConstrainToDirection(TargetAnimal.GetActorForwardVector());
			else
				ForwardVelocityDirection = TargetAnimal.SpiderWantedMovementDirection;
				
			float FinalMultiplier = 1.f;
			if(TargetAnimal.bPreparingToLaunch)
				FinalMultiplier = TargetAnimal.MovementSettings.PreparingToLaunchMoveSpeedMultiplier;
			else if(TargetAnimal.bRidingPlayerIsAiming)
				FinalMultiplier = TargetAnimal.MovementSettings.PlayerAimingSpeedMultiplier;
			else if(TargetAnimal.bTransitioning)
				FinalMultiplier = 0.5f;
			
			FVector Input = TargetAnimal.SpiderWantedMovementDirection;

			float TargetSpeed = 0.f;
			if (!Input.IsNearlyZero())
				TargetSpeed = MoveComp.MoveSpeed * FinalMultiplier * Input.GetClampedToSize(0.4f, 1.f).Size();

			float AccelerationSpeed = MoveComp.MoveSpeed / 0.35f;
			CurrentSpeed += AccelerationSpeed * DeltaTime;
			
			if (CurrentSpeed > TargetSpeed)
				CurrentSpeed = TargetSpeed;

			MoveData.ApplyDelta(ForwardVelocityDirection.GetSafeNormal() * CurrentSpeed * DeltaTime);	
		}

		MoveCharacter(MoveData, n"Movement");
		CrumbComp.LeaveMovementCrumb();
	}

	void UpdateEmptySpider(float DeltaTime)
	{
		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"WallWalkingAnimal");
		if(!MoveComp.IsGrounded())
		{
			MoveData.ApplyActorVerticalVelocity();
			MoveData.ApplyGravityAcceleration(FVector::UpVector);	
		}
		MoveCharacter(MoveData, n"Movement");
	}

	 void MoveCharacter(const FHazeFrameMovement& MoveData, FName AnimationRequestTag, FName SubAnimationRequestTag = NAME_None)
    {
        if(AnimationRequestTag != NAME_None)
        {
            TargetAnimal.SendMovementAnimationRequest(MoveData, GetAttributeVector(AttributeVectorNames::MovementDirection), AnimationRequestTag, SubAnimationRequestTag);
        }
        MoveComp.Move(MoveData);
    }
}
