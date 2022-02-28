import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Peanuts.Movement.NoWallCollisionSolver;
import Peanuts.Movement.DefaultCharacterCollisionSolver;
import Vino.Movement.MovementSystemTags;

class UCharacterUnwalkableFloorCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);

	default TickGroup = ECapabilityTickGroups::LastMovement;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(ShouldBeGrounded())
			return EHazeNetworkActivation::DontActivate;

		if (MoveComp.PreviousImpacts.DownImpact.bBlockingHit)
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (ShouldBeGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		if (!MoveComp.PreviousImpacts.DownImpact.bBlockingHit)
			return EHazeNetworkDeactivation::DeactivateLocal;

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
		FVector Velocity = MoveComp.Velocity;
		Velocity += MoveComp.Gravity * DeltaTime;

		Velocity = Velocity.GetSafeNormal() * FMath::Min(Velocity.Size(), MoveComp.MaxFallSpeed / 2.f);

		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"WallSlide");
		FrameMove.ApplyVelocity(Velocity);
		FrameMove.ApplyTargetRotationDelta();
		MoveCharacter(FrameMove, NAME_None);
	}
	
	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{	
		FString Str = "";
		Str += "Velocity: <Yellow>" + MoveComp.Velocity.Size() + "</> (" + MoveComp.Velocity.ToString() + ")\n";
		
		if(HasControl())
		{

		}
		else
		{
			Str += "MoveType: ";
			// const FHazeActorReplication TargetParams = GetReplicationParams(SyncMovementComp);					
			// if(TargetParams.ReachedType == EHazeReachedType::NotReched)
			// {
			// 	Str += "<Green>Moving" + "</>\n";
			// }
			// else if(TargetParams.ReachedType == EHazeReachedType::Reached)
			// {
			// 	Str += "<Blue>Reached" + "</>\n";
			// }
			// else if(TargetParams.ReachedType == EHazeReachedType::ReachedButCanContinue)
			// {
			// 	Str += "<Yellow>Continue" + "</>\n";
			// }
			// else
			// {
			// 	Str += "<Red>???" + "</>\n";
			// }
		}

		return Str;
	} 
};
