import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.Tomato;
import Vino.Movement.Helpers.MovementJumpHybridData;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.TomatoTags;

class UTomatoLaunchCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::Movement);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 9;

	ATomato Tomato;
	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;

	FMovementCharacterJumpHybridData JumpData;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Tomato = Cast<ATomato>(Owner);

		MoveComp = UHazeMovementComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(TomatoTags::Launch) && Tomato.bTomatoInitialized && !Tomato.bIsLaunching)
		{
			return EHazeNetworkActivation::ActivateUsingCrumb;
		}
        	
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Tomato.bTomatoInitialized || (Tomato.bIsLaunching && !MoveComp.IsAirborne()))
		{
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{		
// 		Tomato.bIsLaunching = true;
// 		const float Impulse = CalculateVerticalJumpForceWithInheritedVelocityAndApplyHorizontalVelocityAsImpulse(Tomato.LaunchImpulse);
// 		JumpData.StartJump(Impulse);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
// 		Tomato.bIsJumping = false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		if(MoveComp.CanCalculateMovement())
// 		{
// 			FHazeFrameMovement ThisFrameMove = MoveComp.MakeFrameMovement(MovementSystemTags::Jump);
// 			MakeFrameMovementData(ThisFrameMove, DeltaTime);

// 			if(!ThisFrameMove.Velocity.IsNearlyZero())
// 			{
// 				MoveComp.Move(ThisFrameMove);
// 				Tomato.CalculateRotationFromVelocity(ThisFrameMove.Velocity, DeltaTime);
// 			}
// 		}
// 	}

// 	void MakeFrameMovementData(FHazeFrameMovement& FrameMoveData, float DeltaTime)
// 	{
// 		if(HasControl())
// 		{	
// 			FVector VerticalVelocity = FVector::ZeroVector;
// 			VerticalVelocity = JumpData.CalculateJumpVelocity(DeltaTime, Tomato.bJumpButtonPressed, MoveComp);

// 			FVector Input = Tomato.Velocity;
// 			float MoveSpeed = Tomato.Velocity.Size();
			

// 			FrameMoveData.ApplyDelta(GetHorizontalAirDeltaMovement(DeltaTime, Input, MoveSpeed));
// 			FrameMoveData.ApplyAndConsumeImpulses();
			
// 			FrameMoveData.ApplyVelocity(VerticalVelocity);

// 			//FHazeActorReplication ReplicationData = Tomato.MakeReplicationData();
// 			CrumbComp.LeaveMovementCrumb();
// 		}
// 		else
// 		{
// 			FHazeActorReplicationFinalized ConsumedParams;
// 	 		CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
// 	 		FrameMoveData.ApplyConsumedCrumbData(ConsumedParams);
// 		}

// 		FrameMoveData.OverrideStepUpHeight(0.f);
// 		FrameMoveData.OverrideStepDownHeight(0.f);
// 	}

// 	UFUNCTION()
// 	float CalculateVerticalJumpForceWithInheritedVelocityAndApplyHorizontalVelocityAsImpulse(float VerticalJumpImpulse) const
// 	{
// 		FVector InheritedVelocity = MoveComp.GetInheritedVelocity(false);
// 		FVector HorizontalInherited = InheritedVelocity.ConstrainToPlane(MoveComp.WorldUp);
// 		float VerticalInherited = InheritedVelocity.DotProduct(MoveComp.WorldUp);

// 		MoveComp.AddImpulse(HorizontalInherited);
// 		return VerticalJumpImpulse + VerticalInherited;
// 	}

//     UFUNCTION()
//     FVector GetHorizontalAirDeltaMovement(float DeltaTime, FVector Input, float MoveSpeed)const
//     {    
// 		const FVector ForwardVelocity = Input.ConstrainToPlane(MoveComp.WorldUp);
//         const FVector InputVector = Input.ConstrainToPlane(MoveComp.WorldUp);
		
//         if(!InputVector.IsNearlyZero())
//         {
//             const FVector CurrentForwardVelocityDir = ForwardVelocity.GetSafeNormal();
            
//             const float CorrectInputAmount = (InputVector.DotProduct(CurrentForwardVelocityDir) + 1) * 0.5f;
        
//             const FVector WorstInputVelocity = InputVector * MoveSpeed;
//             const FVector BestInputVelocity = InputVector * FMath::Max(MoveSpeed, ForwardVelocity.Size());

//             const FVector TargetVelocity = FMath::Lerp(WorstInputVelocity, BestInputVelocity, CorrectInputAmount);
//             return FMath::VInterpConstantTo(ForwardVelocity, TargetVelocity, DeltaTime, 1.0f) * DeltaTime;
//         }
//         else
//         {
//              return ForwardVelocity * DeltaTime;
//         }          
//     }
}
