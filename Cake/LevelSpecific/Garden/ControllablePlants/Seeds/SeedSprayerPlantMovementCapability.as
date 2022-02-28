import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Garden.ControllablePlants.Seeds.SeedSprayerPlant;


class USeedSprayerPlantMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Falling);
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;

	ASeedSprayerPlant PlantOwner;
	USeedSprayerPlantMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;
	

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlantOwner = Cast<ASeedSprayerPlant>(Owner);
		MoveComp = USeedSprayerPlantMovementComponent::Get(PlantOwner);
		CrumbComp = UHazeCrumbComponent::Get(PlantOwner);

		PlantOwner.MovingEffect = Niagara::SpawnSystemAttached(PlantOwner.MoveUndergroundLoopEffectWhite, PlantOwner.RootComponent, NAME_None, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, false);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(!PlantOwner.CanMove())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}


	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!PlantOwner.CanMove())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		
	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FinalMovement = MoveComp.MakeFrameMovement(n"SeedSprayerMovement");

		if(HasControl())
		{
			FinalMovement.OverrideStepUpHeight(0.0f);
			FinalMovement.ApplyActorVerticalVelocity();
			FinalMovement.ApplyGravityAcceleration();

			FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);
			FinalMovement.ApplyVelocity(Input * MoveComp.GetMoveSpeed());

			if(!Input.IsNearlyZero())
			{
				MoveComp.SetTargetFacingDirection(Input.GetSafeNormal(), 6.f);
			}

			FinalMovement.ApplyTargetRotationDelta();
		}
		else
		{
			FHazeActorReplicationFinalized ReplicatedMovement;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ReplicatedMovement);
			FinalMovement.ApplyConsumedCrumbData(ReplicatedMovement);
		}

		// TODO, if we change it to be a skelmesh component, add this
		//SendMovementAnimationRequest(FinalMovement, n"Movement");

		MoveComp.Move(FinalMovement);
		CrumbComp.LeaveMovementCrumb();
	}

	void SendMovementAnimationRequest(const FHazeFrameMovement& MoveData, FName AnimationRequestTag, FName SubAnimationRequestTag = n"")
    {        
        FHazeRequestLocomotionData AnimationRequest;
 
        AnimationRequest.LocomotionAdjustment.DeltaTranslation = MoveData.MovementDelta;
        AnimationRequest.LocomotionAdjustment.WorldRotation = MoveData.Rotation;
 		AnimationRequest.WantedVelocity = MoveData.Velocity;
        AnimationRequest.WantedWorldTargetDirection = MoveData.Velocity.GetSafeNormal();
        AnimationRequest.WantedWorldFacingRotation = MoveComp.GetTargetFacingRotation();
		AnimationRequest.MoveSpeed = MoveComp.MoveSpeed;		
		
		if(!MoveComp.GetAnimationRequest(AnimationRequest.AnimationTag))
		{
			AnimationRequest.AnimationTag = AnimationRequestTag;
		}

        if (!MoveComp.GetSubAnimationRequest(AnimationRequest.SubAnimationTag))
        {
            AnimationRequest.SubAnimationTag = SubAnimationRequestTag;
        }

		// TODO, if we change it to be a skelmesh component, add this
        //PlantOwner.Mesh.RequestLocomotion(AnimationRequest);
    }
}