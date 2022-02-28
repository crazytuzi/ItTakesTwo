import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Hopscotch.MarbleMazeBall;
import Vino.Movement.Components.MovementComponent;

class UMarbleMazeBallCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Movement");

	default CapabilityDebugCategory = n"Movement";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 100;

	UHazeMovementComponent MoveComp;

	AMarbleMazeBall MarbleMazeBall;

	/* The ball move on to the next phase whenever it's close enough to the Goal. 
	If it for some reason should get that close, due to an collision issue. 
	We force move it to the next phase with this timer.*/
	float LerpToGoalSafeTimer = 0.f;

	FVector MarbleMazeMovement;
	FVector MarbleMazeMovemetLastTick;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MarbleMazeBall = Cast<AMarbleMazeBall>(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(MarbleMazeBall);
		MoveComp.UseCollisionSolver(n"CollisionSolver", NAME_None);

		MarbleMazeBall.ReplicateAsMovingActor();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
       if (MarbleMazeBall == nullptr) 
			return EHazeNetworkActivation::DontActivate;

		if (!IsActioning(n"MazeBallActive"))
			return EHazeNetworkActivation::DontActivate;
  
        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (MarbleMazeBall == nullptr) 
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (!IsActioning(n"MazeBallActive"))
			return EHazeNetworkDeactivation::DeactivateFromControl;

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
		if (MarbleMazeBall.HasControl())
		{
			FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"MarbleMove");
			
			if (!MarbleMazeBall.bShouldLerpToGoal)
			{
				if (MoveComp.IsGrounded())
				{
					FRotator MazeRot = MarbleMazeBall.MazeRotation;
					FVector TargetMarbleMazeMovement = MazeRot.UpVector.ConstrainToPlane(MoveComp.WorldUp) * 5000.f;

					MarbleMazeMovement = FMath::VInterpConstantTo(MoveComp.Velocity.ConstrainToPlane(MoveComp.DownHit.ImpactNormal), TargetMarbleMazeMovement, DeltaTime, 300.f);

					MoveData.FlagToMoveWithDownImpact();
					MoveData.ApplyVelocity(MarbleMazeMovement);
					MoveData.ApplyGravityAcceleration();
					MoveComp.Move(MoveData);
				}
				else
				{
					MoveData.FlagToMoveWithDownImpact();
					MoveData.ApplyVelocity(MoveComp.Velocity);
					MoveData.ApplyGravityAcceleration();
					MoveComp.Move(MoveData);
				}
			} else 
			{
				FVector TargetMarbleMazeMovement = MarbleMazeBall.CurrentGoalLoc - MarbleMazeBall.ActorLocation;
				TargetMarbleMazeMovement.Normalize();
				TargetMarbleMazeMovement = (TargetMarbleMazeMovement * 5000.f) * DeltaTime;

				MarbleMazeMovement = FMath::VInterpConstantTo(MarbleMazeBall.ActorLocation, TargetMarbleMazeMovement, DeltaTime, 300.f);

				MoveData.FlagToMoveWithDownImpact();
				MoveData.ApplyVelocity(TargetMarbleMazeMovement);
				MoveData.ApplyGravityAcceleration();
				MoveComp.Move(MoveData);

				LerpToGoalSafeTimer += DeltaTime;
				FVector Dist = MarbleMazeBall.ActorLocation - MarbleMazeBall.CurrentGoalLoc;
				if (Dist.Size() <= 2.f || LerpToGoalSafeTimer >= 4.f)
				{
					LerpToGoalSafeTimer = 0.f;
					MarbleMazeBall.bShouldLerpToGoal = false;
					MarbleMazeBall.MarbleBallReachedGoal.Broadcast();
				}
			}

			MarbleMazeMovemetLastTick = MarbleMazeMovement;
			
			MarbleMazeBall.CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			MarbleMazeBall.CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);

			FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"MarbleReplicatedMove");

			FHazeReplicatedFrameMovementSettings Settings;
			Settings.bUseReplicatedRotation = false;

			MoveData.ApplyConsumedCrumbData(ConsumedParams, Settings);

			MoveComp.Move(MoveData);
		}
	}
}
