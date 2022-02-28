import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Garden.ControllablePlants.SneakyBush.SneakyBush;
import Vino.Tutorial.TutorialStatics;

class USneakyBushMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Falling);
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;

	USneakyBushMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;
	ASneakyBush PlantOwner;

	UPROPERTY()
	FTutorialPrompt StartMove;
	default StartMove.DisplayType = ETutorialPromptDisplay::LeftStick_LeftRightUpDown;

	bool bShowTutorial = true;
	float InputTimeTutorial = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlantOwner = Cast<ASneakyBush>(Owner);
		MoveComp = USneakyBushMovementComponent::Get(PlantOwner);
		CrumbComp = UHazeCrumbComponent::Get(PlantOwner);
		StartMove.Text = PlantOwner.MoveTutorialText;
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
		//Audio On Enter Sneaky Bush sound
		PlantOwner.SetCapabilityActionState(n"AudioOnBecomeSneakyBush", EHazeActionState::ActiveForOneFrame);
		
		//Audio Sneaky Bush start movement sound
		PlantOwner.SetCapabilityActionState(n"AudioOnMoveSneakyBush", EHazeActionState::ActiveForOneFrame);

		ShowTutorialPrompt(Game::GetCody(), StartMove, Game::GetCody());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		//Audio Sneaky Bush Exit sound and stop movement
		PlantOwner.SetCapabilityActionState(n"AudioExitSneakyBush", EHazeActionState::ActiveForOneFrame);
		RemoveTutorialPromptByInstigator(Game::GetCody(),Game::GetCody());
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FinalMovement = MoveComp.MakeFrameMovement(n"BushMovement");

		if(HasControl())
		{
			
			FinalMovement.ApplyActorVerticalVelocity();
			FinalMovement.ApplyGravityAcceleration();

			FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);
			FinalMovement.ApplyVelocity(Input * MoveComp.GetMoveSpeed());

			if(!Input.IsNearlyZero())
			{
				MoveComp.SetTargetFacingDirection(Input.GetSafeNormal(), 6.f);

				if(bShowTutorial)
				{
					InputTimeTutorial += DeltaTime;
					if(InputTimeTutorial >= 4)
					{
						bShowTutorial = false;
						NetRemoveTutorialPromt();
					}
				}
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
	
		// // Align the bush with the ground
		// const float LineTraceUp = PlantOwner.CollisionComp.CapsuleHalfHeight * 2;
		// const float AlignToGroundDistance = MoveComp.GetStepAmount(-1);
		
		// const FVector CurrentPlantLocation = PlantOwner.GetActorLocation() + (MoveComp.WorldUp * LineTraceUp);
		// const float PlantRadius = PlantOwner.CollisionComp.CapsuleRadius;

		// // ForwardBackward
		// FVector PitchAmount = PlantOwner.GetActorForwardVector();
		// {
		// 	FHitResult ForwardHit;
		// 	MoveComp.LineTraceGround(CurrentPlantLocation + (PlantOwner.GetActorForwardVector() * PlantRadius), ForwardHit, LineTraceUp + AlignToGroundDistance);

		// 	FHitResult BackwardHit;
		// 	MoveComp.LineTraceGround(CurrentPlantLocation - (PlantOwner.GetActorForwardVector() * PlantRadius), BackwardHit, LineTraceUp + AlignToGroundDistance);

			
		// 	if(ForwardHit.bBlockingHit && BackwardHit.bBlockingHit)
		// 	{
		// 		PitchAmount = (ForwardHit.ImpactPoint - BackwardHit.ImpactPoint).GetSafeNormal();
		// 	}
		// 	else if(ForwardHit.bBlockingHit)
		// 	{
		// 		PitchAmount = (ForwardHit.ImpactPoint - PlantOwner.GetActorLocation()).GetSafeNormal();
			
		// 	}
		// 	else if(BackwardHit.bBlockingHit)
		// 	{
		// 		PitchAmount = (PlantOwner.GetActorLocation() - BackwardHit.ImpactPoint).GetSafeNormal();	
		// 	}
		// }


		// // LeftRight
		// FVector RollAmount = PlantOwner.GetActorRightVector();
		// {
		// 	FHitResult LeftHit;
		// 	MoveComp.LineTraceGround(CurrentPlantLocation - (PlantOwner.GetActorRightVector() * PlantRadius), LeftHit, LineTraceUp + AlignToGroundDistance);

		// 	FHitResult RightHit;
		// 	MoveComp.LineTraceGround(CurrentPlantLocation + (PlantOwner.GetActorRightVector() * PlantRadius), RightHit, LineTraceUp + AlignToGroundDistance);

		// 	if(LeftHit.bBlockingHit && RightHit.bBlockingHit)
		// 	{
		// 		RollAmount = (RightHit.ImpactPoint - LeftHit.ImpactPoint).GetSafeNormal();
		// 	}
		// 	else if(LeftHit.bBlockingHit)
		// 	{
		// 		RollAmount = (PlantOwner.GetActorLocation() - LeftHit.ImpactPoint).GetSafeNormal();
		// 	}
		// 	else if(RightHit.bBlockingHit)
		// 	{
		// 		RollAmount = (RightHit.ImpactPoint - PlantOwner.GetActorLocation()).GetSafeNormal();
		// 	}
		// }

		// FQuat WantedMeshRotation = Math::MakeRotFromXY(PitchAmount, RollAmount).Quaternion();
		// WantedMeshRotation = FMath::QInterpConstantTo(PlantOwner.Mesh.ComponentQuat, WantedMeshRotation, DeltaTime, 3.f);
		// PlantOwner.Mesh.SetWorldRotation(WantedMeshRotation.Rotator());
	}

	UFUNCTION(NetFunction)
	void NetRemoveTutorialPromt()
	{
		RemoveTutorialPromptByInstigator(Game::GetCody(),Game::GetCody());
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