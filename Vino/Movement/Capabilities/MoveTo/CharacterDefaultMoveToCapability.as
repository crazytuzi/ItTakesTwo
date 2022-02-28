
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Peanuts.Movement.NoWallCollisionSolver;
import Peanuts.Movement.DefaultCharacterCollisionSolver;
import Peanuts.Animation.Features.LocomotionFeatureLanding;

class UCharacterDefaultMoveToCapability : UHazePathFindingCapabilityBase
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	
	default BlockTagsOnActivated.Add(CapabilityTags::Movement);
	default BlockTagsOnActivated.Add(CapabilityTags::GameplayAction);

	default CapabilityDebugCategory = CapabilityTags::Movement;
	
	UHazeMovementComponent MoveComp;
    UHazeCrumbComponent CrumbComp;
	AHazeCharacter CharacterOwner;
	UHazeCharacterSkeletalMeshComponent SkelMeshComp;

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 10;

	const float DefaultMoveSpeed = 600.f;

	FVector DebugStartLocation = FVector::ZeroVector;
	bool bHasEnded = true;
	EHazeDestinationControlType ControlType = EHazeDestinationControlType::Local;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		devEnsure(CheckIfTickGroupIsMovementTickGroup(TickGroup), "TickGroup is not set Correctly on " + Name +  ". all Movement capabilities has to be in a movement Tickgroup. If you are unsure what group to put your capability in you can ask Simon or Tyko.");

        CharacterOwner = Cast<AHazeCharacter>(Owner);
        ensure(CharacterOwner != nullptr);

		MoveComp = UHazeMovementComponent::Get(Owner);
        CrumbComp = UHazeCrumbComponent::GetOrCreate(Owner);
		SkelMeshComp = UHazeCharacterSkeletalMeshComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool SetupPathFindingParams(FHazeDestinationInitializeParams& Params)
	{
		Params.Shape.InitializeFromShape(CharacterOwner.CapsuleComponent);
		Params.Status = EHazeDestinationInitializeType::BeginMoveTo;
		Params.bOnlyValidateHorizontal = true;

		bHasEnded = false;
		DebugStartLocation = CharacterOwner.GetActorLocation();
		return true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(MoveComp != nullptr && !MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(!IsValidToActivate())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(MoveComp != nullptr && !MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!IsValidToActivate())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ControlType = EHazeDestinationControlType::Local;
		PathFindingComponent.GetActivationControlType(ControlType);

		if(!HasControl() && ControlType == EHazeDestinationControlType::Controlled)
		{
			bHasEnded = false;		
		}

		if(ControlType == EHazeDestinationControlType::Controlled)
		{
			Owner.UnblockMovementSyncronization(this);
			Owner.TriggerMovementTransition(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(ControlType == EHazeDestinationControlType::Controlled)
		{
			Owner.BlockMovementSyncronization(this);
		}
	}

	FVector LineTraceGround()
    {
		FVector ActorLocation = CharacterOwner.GetActorLocation();
		if(MoveComp != nullptr)
		{
			
			const FVector From = CharacterOwner.GetActorCenterLocation();
			const FVector To = ActorLocation - (CharacterOwner.GetMovementWorldUp() * 500.f);

			FHazeHitResult Hit;
			if(MoveComp.SweepTrace(From, To, Hit))
			{
				ActorLocation = Hit.ActorLocation;
			}
		}
		return ActorLocation;
    }

	UFUNCTION(BlueprintOverride)
	void OnMoveToEnded(const FHazeDestinationEndingSettings& EndSettings)
	{
		bHasEnded = true;
	}
	
	UFUNCTION()
    void SendMovementAnimationRequest(const FHazeFrameMovement& MoveData, FName AnimationRequestTag, FName SubAnimationRequestTag)
    {        
        FHazeRequestLocomotionData AnimationRequest;
 
        AnimationRequest.LocomotionAdjustment.DeltaTranslation = MoveData.MovementDelta;
        AnimationRequest.LocomotionAdjustment.WorldRotation = MoveData.Rotation;
 		AnimationRequest.WantedVelocity = MoveData.Velocity;
        AnimationRequest.WantedWorldTargetDirection = MoveData.Velocity.GetSafeNormal();

		if(MoveComp != nullptr)
		{
			AnimationRequest.WantedWorldFacingRotation = MoveComp.GetTargetFacingRotation();
				
			if(!MoveComp.GetAnimationRequest(AnimationRequest.AnimationTag))
			{
				AnimationRequest.AnimationTag = AnimationRequestTag;
			}

			if (!MoveComp.GetSubAnimationRequest(AnimationRequest.SubAnimationTag))
			{
				AnimationRequest.SubAnimationTag = SubAnimationRequestTag;
			}
		}

        CharacterOwner.RequestLocomotion(AnimationRequest);
    }

	void MakeFrameMovementData(FHazeFrameMovement& FrameMoveData, float DeltaTime)
	{	
		float MoveSpeed = DefaultMoveSpeed;
		
		MoveSpeed = MoveComp.MoveSpeed;
		if(ControlType == EHazeDestinationControlType::Local || HasControl())
		{
			const FTransform DeltaTranslationWorldRotation = PathFindingComponent.MoveAlongPath(MoveSpeed * DeltaTime);
			MoveComp.SetTargetFacingRotation(DeltaTranslationWorldRotation.Rotation, 10.f);
		
			FrameMoveData.ApplyDelta(DeltaTranslationWorldRotation.Translation);	
			FrameMoveData.OverrideCollisionSolver(UNoWallCollisionSolver::StaticClass());
			FrameMoveData.FlagToMoveWithDownImpact();
			FrameMoveData.ApplyTargetRotationDelta();
		}
		else
		{	
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMoveData.ApplyConsumedCrumbData(ConsumedParams);	
		}
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bHasEnded)
			return;

		if(MoveComp != nullptr)
		{
			FHazeFrameMovement FinalMovement = MoveComp.MakeFrameMovement(n"PathFindingStandard");
			MakeFrameMovementData(FinalMovement, DeltaTime);

			FName MoveRequest = MoveRequest = n"Movement";
			if(!MoveComp.IsGrounded())
			{
				const FVector FallingDirection = FinalMovement.MovementDelta.GetSafeNormal();
				if(FallingDirection.DotProduct(MoveComp.WorldUp) < 0.7f)
					MoveRequest = FeatureName::AirMovement;
			}

			SendMovementAnimationRequest(FinalMovement, MoveRequest, NAME_None);
			
			MoveComp.Move(FinalMovement);
		}
		else
		{
			PrintWarning("Pathfinding without movement component needs to be implemented!");
		}

		if(ControlType == EHazeDestinationControlType::Controlled)
		{
			if(HasControl())
			{
				CrumbComp.LeaveMovementCrumb();
			}
		}
			
		// Print Debug
		if(!HasControl())
		{
			CrumbComp.SetCrumbDebugActive(this, IsDebugActive());
		}

		if(IsDebugActive())
		{
			TArray<FVector> PathPoints;
			PathFindingComponent.GetDebugTrackingPathPoints(PathPoints);
			const FVector DebugOffset = MoveComp.WorldUp * 100.f;
			FVector CurrentLocation = DebugStartLocation;
			for(int i = 0; i < PathPoints.Num(); ++i)
			{
				const FVector TargetLocation = PathPoints[i];
				System::DrawDebugArrow(CurrentLocation + DebugOffset, TargetLocation + DebugOffset);
				CurrentLocation = TargetLocation;
			}
		}
	}
};
